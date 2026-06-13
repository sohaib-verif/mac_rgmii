
//=============================================================================
// ETHERNET TOP-LEVEL MODULE
//=============================================================================
// This is the top-level wrapper for the Gigabit Ethernet IP core.
//
// PURPOSE:
//   - Provides a clean, parameterized interface to the Ethernet subsystem
//   - Handles AXI-Stream width conversion (64-bit ↔ 8-bit)
//   - Integrates framing, MAC, and RGMII physical layer
//
// ARCHITECTURE:
//   System (64-bit) → Downsizer (64→8) → Framing/MAC → RGMII → PHY
//   System (64-bit) ← Upsizer (8→64) ← Framing/MAC ← RGMII ← PHY
//
// KEY FEATURES:
//   - Gigabit Ethernet (1000BASE-T) with RGMII physical interface
//   - AXI-Stream data interface (parameterizable width, default 64-bit)
//   - REG_BUS configuration interface for MAC address and settings
//   - Automatic preamble, SFD, and FCS (CRC) handling
//   - MAC address filtering with promiscuous mode support
//
// INTERFACES:
//   - AXI-Stream TX/RX: High-bandwidth packet data (system side)
//   - RGMII: 4-bit DDR physical interface to Ethernet PHY
//   - REG_BUS: Configuration registers (MAC address, control, status)
//   - MDIO: PHY management interface (optional)
//   - Clocks: 125 MHz (system), 125 MHz 90° (DDR), 200 MHz (IDELAY)
//=============================================================================

`include "axi_stream/assign.svh"
`include "axi_stream/typedef.svh"
`include "register_interface/typedef.svh"
`include "register_interface/assign.svh"

module eth_top #(
  //===========================================================================
  // AXI-STREAM PARAMETERS (System-Side Interface)
  //===========================================================================
  /// AXI-Stream request struct type (contains tdata, tvalid, tlast, etc.)
  parameter type axi_stream_req_t = eth_top_pkg::s_req_t,
  /// AXI-Stream response struct type (contains tready for backpressure)
  parameter type axi_stream_rsp_t = eth_top_pkg::s_rsp_t,
  /// AXI-Stream data width in bits (default: 64-bit = 8 bytes per cycle)
  parameter int unsigned DataWidth = 64,
  /// AXI-Stream ID width (for stream routing, 0 = not used)
  parameter int unsigned IdWidth = 1,
  /// AXI-Stream destination width (for routing, 0 = not used)
  parameter int unsigned DestWidth = 1,
  /// AXI-Stream user sideband width (default: 1-bit for error indication)
  parameter int unsigned UserWidth = 1,
  
  //===========================================================================
  // REGISTER BUS PARAMETERS (Configuration Interface)
  //===========================================================================
  /// Register bus request struct type
  parameter type reg_req_t = eth_top_pkg::reg_bus_req_t,
  /// Register bus response struct type
  parameter type reg_rsp_t = eth_top_pkg::reg_bus_rsp_t,
  /// Register address width in bits (4 bits = 16 registers)
  parameter int AW_REGBUS = 4
) (
  //===========================================================================
  // CLOCK AND RESET
  //===========================================================================
  /// Main system clock (125 MHz for Gigabit Ethernet)
  input  wire                                           clk_i        ,
  /// Active-low asynchronous reset
  input  wire                                           rst_ni       ,
  /// 90-degree phase-shifted clock (125 MHz, for RGMII DDR output)
  input  wire                                           clk90_int    ,
  /// High-speed clock (200 MHz, for IDELAY calibration in RGMII)
  input  wire                                           clk_200_int  ,
  
  //===========================================================================
  // RGMII PHYSICAL INTERFACE (1000BASE-T to Ethernet PHY)
  //===========================================================================
  // RX Signals (from PHY to MAC)
  /// RX clock from PHY (125 MHz DDR clock)
  input  wire                                           phy_rx_clk   ,
  /// RX data bus (4-bit DDR = 8 bits per cycle = 1 Gbps)
  input  wire     [3:0]                                 phy_rxd      ,
  /// RX control signal (DDR: indicates valid data and errors)
  input  wire                                           phy_rx_ctl   ,
  
  // TX Signals (from MAC to PHY)
  /// TX clock to PHY (125 MHz DDR clock, generated internally)
  output wire                                           phy_tx_clk   ,
  /// TX data bus (4-bit DDR = 8 bits per cycle = 1 Gbps)
  output wire     [3:0]                                 phy_txd      ,
  /// TX control signal (DDR: indicates valid data and errors)
  output wire                                           phy_tx_ctl   ,
  
  // PHY Management
  /// PHY reset (active-low, used to reset the external PHY chip)
  output wire                                           phy_reset_n  ,
  /// PHY interrupt input (active-low, signals PHY events)
  input  wire                                           phy_int_n    ,
  /// PHY power management event (active-low)
  input  wire                                           phy_pme_n    ,
  
  //===========================================================================
  // MDIO INTERFACE (PHY Management Interface - Optional)
  //===========================================================================
  /// MDIO input (serial data from PHY)
  input  wire                                           phy_mdio_i   ,
  /// MDIO output (serial data to PHY)
  output reg                                            phy_mdio_o   ,
  /// MDIO output enable (tri-state control)
  output reg                                            phy_mdio_oe  ,
  /// MDIO clock (typically 2.5 MHz)
  output wire                                           phy_mdc      ,
  
  //===========================================================================
  // AXI-STREAM DATA INTERFACE (System-Side Packet Data)
  //===========================================================================
  // TX Path (Input): System sends Ethernet frames to IP for transmission
  /// TX AXI-Stream request (contains tdata, tvalid, tlast, etc.)
  input       axi_stream_req_t                          tx_axis_req_i,
  /// TX AXI-Stream response (contains tready for flow control)
  output      axi_stream_rsp_t                          tx_axis_rsp_o,
  
  // RX Path (Output): IP sends received Ethernet frames to system
  /// RX AXI-Stream request (contains tdata, tvalid, tlast, etc.)
  output      axi_stream_req_t                          rx_axis_req_o,
  /// RX AXI-Stream response (contains tready for flow control)
  input       axi_stream_rsp_t                          rx_axis_rsp_i,
  
  //===========================================================================
  // REGISTER BUS INTERFACE (Configuration and Status)
  //===========================================================================
  /// Register bus request (addr, wdata, write enable, etc.)
  input       reg_req_t                                 reg_req_i    ,
  /// Register bus response (rdata, ready, error)
  output      reg_rsp_t                                 reg_rsp_o
);

  //===========================================================================
  // INTERNAL AXI-STREAM INTERFACE (8-bit for MAC/Framing Layer)
  //===========================================================================
  // The system interface is 64-bit, but the MAC layer operates on 8-bit data.
  // Width converters (downsizer/upsizer) bridge between these domains.
  //
  // TX: System (64-bit) → Downsizer → Framing (8-bit) → MAC → RGMII
  // RX: System (64-bit) ← Upsizer ← Framing (8-bit) ← MAC ← RGMII
  
  /// Internal AXI-Stream data width (8-bit = 1 byte per cycle for MAC)
  localparam int unsigned FramingDataWidth = 8;
  /// Internal stream ID width (not used)
  localparam int unsigned FramingIdWidth   = 1;
  /// Internal stream destination width (not used)
  localparam int unsigned FramingDestWidth = 1;
  /// Internal stream user width (1-bit for error indication)
  localparam int unsigned FramingUserWidth = 1;

  // Define internal AXI-Stream signal types for 8-bit interface
  typedef logic [FramingDataWidth-1:0]   framing_tdata_t;   // 8-bit data
  typedef logic [FramingDataWidth/8-1:0] framing_tstrb_t;   // 1-bit strobe
  typedef logic [FramingDataWidth/8-1:0] framing_tkeep_t;   // 1-bit keep
  typedef logic [FramingIdWidth-1:0]     framing_tid_t;     // ID (unused)
  typedef logic [FramingDestWidth-1:0]   framing_tdest_t;   // Dest (unused)
  typedef logic [FramingUserWidth-1:0]   framing_tuser_t;   // 1-bit user

  // Generate complete AXI-Stream typedef (creates req/rsp structs)
  `AXI_STREAM_TYPEDEF_ALL(s_framing, framing_tdata_t, framing_tstrb_t, framing_tkeep_t, framing_tid_t, framing_tdest_t, framing_tuser_t)

  // Internal 8-bit AXI-Stream signals connecting width converters to framing layer
  s_framing_req_t s_framing_tx_req, s_framing_rx_req;  // Request (data, valid, last)
  s_framing_rsp_t s_framing_tx_rsp, s_framing_rx_rsp;  // Response (ready)

  //===========================================================================
  // FRAMING AND MAC LAYER
  //===========================================================================
  // The framing_top module handles:
  //   - MAC address filtering (unicast, broadcast, multicast, promiscuous)
  //   - Ethernet frame processing (preamble, SFD, FCS)
  //   - Integration with RGMII physical layer
  //   - Configuration via REG_BUS
  
  framing_top #(
    .axi_stream_req_t(s_framing_req_t),  // 8-bit AXI-Stream request type
    .axi_stream_rsp_t(s_framing_rsp_t),  // 8-bit AXI-Stream response type
    .reg_req_t       (reg_req_t),        // REG_BUS request type
    .reg_rsp_t       (reg_rsp_t),        // REG_BUS response type
    .AW_REGBUS       (AW_REGBUS)         // Register address width
  ) i_framing_top (
    // Clock and Reset
    .rst_ni(rst_ni),              // Active-low reset
    .clk_i(clk_i),                // 125 MHz system clock
    .clk90_int(clk90_int),        // 125 MHz 90° shifted (for RGMII DDR)
    .clk_200_int(clk_200_int),    // 200 MHz (for IDELAY)

    // RGMII Physical Interface
    .phy_rx_clk(phy_rx_clk),      // RX clock from PHY
    .phy_rxd(phy_rxd),            // RX data [3:0]
    .phy_rx_ctl(phy_rx_ctl),      // RX control
    .phy_tx_clk(phy_tx_clk),      // TX clock to PHY
    .phy_txd(phy_txd),            // TX data [3:0]
    .phy_tx_ctl(phy_tx_ctl),      // TX control
    .phy_reset_n(phy_reset_n),    // PHY reset
    .phy_int_n(phy_int_n),        // PHY interrupt
    .phy_pme_n(phy_pme_n),        // PHY power management

    // MDIO Management Interface
    .phy_mdio_i(phy_mdio_i),      // MDIO input
    .phy_mdio_o(phy_mdio_o),      // MDIO output
    .phy_mdio_oe(phy_mdio_oe),    // MDIO output enable
    .phy_mdc(phy_mdc),            // MDIO clock

    // 8-bit AXI-Stream Interface (after width conversion)
    .tx_axis_req_i(s_framing_tx_req),  // TX request (from downsizer)
    .tx_axis_rsp_o(s_framing_tx_rsp),  // TX response (to downsizer)
    .rx_axis_req_o(s_framing_rx_req),  // RX request (to upsizer)
    .rx_axis_rsp_i(s_framing_rx_rsp),  // RX response (from upsizer)

    // Configuration Register Interface
    .reg_req_i(reg_req_i),        // Register request (from system)
    .reg_rsp_o(reg_rsp_o)         // Register response (to system)
  );

  //===========================================================================
  // TX PATH: AXI-STREAM WIDTH DOWNSIZER (64-bit → 8-bit)
  //===========================================================================
  // Converts wide system interface (64-bit) to narrow MAC interface (8-bit)
  // 
  // Operation:
  //   - Takes one 64-bit word and outputs eight 8-bit words
  //   - Maintains AXI-Stream protocol (valid, ready, last)
  //   - Handles byte enable (tkeep) and strobes (tstrb)
  //   - Provides flow control via tready
  
  axi_stream_dw_downsizer #(
    .DataWidthIn         (DataWidth),           // Input: 64 bits
    .DataWidthOut        (FramingDataWidth),    // Output: 8 bits
    .IdWidth             (IdWidth),             // Stream ID width
    .DestWidth           (DestWidth),           // Destination width
    .UserWidth           (UserWidth),           // User sideband width
    .axi_stream_in_req_t(axi_stream_req_t),    // Input request type (64-bit)
    .axi_stream_in_rsp_t(axi_stream_rsp_t),    // Input response type
    .axi_stream_out_req_t(s_framing_req_t),    // Output request type (8-bit)
    .axi_stream_out_rsp_t(s_framing_rsp_t)     // Output response type
  ) i_axi_stream_dw_downsizer (
    .clk_i    (clk_i),              // System clock
    .rst_ni   (rst_ni),             // Active-low reset
    .in_req_i (tx_axis_req_i),      // 64-bit input from system
    .in_rsp_o (tx_axis_rsp_o),      // Response to system (tready)
    .out_req_o(s_framing_tx_req),   // 8-bit output to framing layer
    .out_rsp_i(s_framing_tx_rsp)    // Response from framing layer
  );

  //===========================================================================
  // RX PATH: AXI-STREAM WIDTH UPSIZER (8-bit → 64-bit)
  //===========================================================================
  // Converts narrow MAC interface (8-bit) to wide system interface (64-bit)
  // 
  // Operation:
  //   - Accumulates eight 8-bit words into one 64-bit word
  //   - Maintains AXI-Stream protocol (valid, ready, last)
  //   - Handles byte enable (tkeep) and strobes (tstrb)
  //   - Provides flow control via tready
  //   - Outputs when 64-bit word is complete or tlast is asserted
  
  axi_stream_dw_upsizer #(
    .DataWidthIn         (FramingDataWidth),    // Input: 8 bits
    .DataWidthOut        (DataWidth),           // Output: 64 bits
    .IdWidth             (IdWidth),             // Stream ID width
    .DestWidth           (DestWidth),           // Destination width
    .UserWidth           (UserWidth),           // User sideband width
    .axi_stream_in_req_t(s_framing_req_t),     // Input request type (8-bit)
    .axi_stream_in_rsp_t(s_framing_rsp_t),     // Input response type
    .axi_stream_out_req_t(axi_stream_req_t),   // Output request type (64-bit)
    .axi_stream_out_rsp_t(axi_stream_rsp_t)    // Output response type
  ) i_axi_stream_dw_upsizer (
    .clk_i    (clk_i),              // System clock
    .rst_ni   (rst_ni),             // Active-low reset
    .in_req_i (s_framing_rx_req),   // 8-bit input from framing layer
    .in_rsp_o (s_framing_rx_rsp),   // Response to framing layer (tready)
    .out_req_o(rx_axis_req_o),      // 64-bit output to system
    .out_rsp_i(rx_axis_rsp_i)       // Response from system
  );

endmodule : eth_top
