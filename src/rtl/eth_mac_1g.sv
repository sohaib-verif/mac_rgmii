


//=============================================================================
// 1 GIGABIT ETHERNET MAC (Media Access Control) CORE
//=============================================================================
// This module implements the IEEE 802.3 Ethernet MAC functionality for
// Gigabit Ethernet (1000BASE-T).
//
// PURPOSE:
//   - Provides MAC layer functionality between system (AXI-Stream) and PHY (GMII)
//   - Handles Ethernet frame formatting and validation
//   - Implements TX and RX data paths
//
// TX PATH FUNCTIONS (axis_gmii_tx):
//   1. Add Preamble: 7 bytes of 0x55 before frame
//   2. Add SFD (Start Frame Delimiter): 1 byte of 0xD5
//   3. Pass Frame Data: Destination MAC, Source MAC, EtherType, Payload
//   4. Calculate FCS: CRC-32 checksum over entire frame
//   5. Append FCS: 4 bytes of CRC-32 at end of frame
//   6. Add Padding: Pad short frames to minimum 64 bytes (if enabled)
//   7. Inter-Frame Gap: Wait 96 bit times (12 bytes @ 1 Gbps) between frames
//
// RX PATH FUNCTIONS (axis_gmii_rx):
//   1. Detect Preamble: Look for 7 bytes of 0x55
//   2. Detect SFD: Look for 0xD5
//   3. Receive Frame Data: Capture until end of frame
//   4. Check FCS: Verify CRC-32 checksum
//   5. Output Frame: Send to AXI-Stream if FCS is good
//   6. Discard Bad Frames: Drop frames with FCS errors
//
// ETHERNET FRAME FORMAT:
//   [Preamble(7)] [SFD(1)] [Dest MAC(6)] [Src MAC(6)] [Type(2)] 
//   [Payload(46-1500)] [FCS(4)]
//
//   Preamble + SFD = Added/removed by MAC (not in AXI-Stream)
//   FCS            = Added/removed by MAC (not in AXI-Stream)
//   Other fields   = Passed through AXI-Stream interface
//
// INTERFACES:
//   - AXI-Stream (8-bit): System-side packet interface
//   - GMII (8-bit): PHY-side Gigabit Media Independent Interface
//
// CLOCKING:
//   - tx_clk: 125 MHz for Gigabit (8 bits × 125 MHz = 1 Gbps)
//   - rx_clk: 125 MHz from PHY (recovered from received signal)
//   - Separate clock domains for TX and RX
//=============================================================================

module eth_mac_1g #
(
    //===========================================================================
    // PARAMETERS
    //===========================================================================
    /// Enable automatic padding of short frames to minimum length
    /// If 1: Frames < MIN_FRAME_LENGTH will be padded with zeros
    /// If 0: Frames are transmitted as-is (may violate Ethernet spec)
    parameter ENABLE_PADDING = 1,
    
    /// Minimum Ethernet frame length (IEEE 802.3 specifies 64 bytes)
    /// Includes: Dest MAC(6) + Src MAC(6) + Type(2) + Payload(46+) + FCS(4)
    /// Does NOT include: Preamble(7) + SFD(1)
    parameter MIN_FRAME_LENGTH = 64
)
(
    //===========================================================================
    // CLOCKS AND RESETS
    //===========================================================================
    /// RX clock (125 MHz from PHY, recovered from received signal)
    input wire         rx_clk,
    /// RX reset (synchronous to rx_clk, active-high)
    input wire         rx_rst,
    /// TX clock (125 MHz system clock)
    input wire         tx_clk,
    /// TX reset (synchronous to tx_clk, active-high)
    input wire         tx_rst,

    //===========================================================================
    // AXI-STREAM TX INTERFACE (Input from System)
    //===========================================================================
    // System sends Ethernet frames to MAC for transmission
    // Frame format: [Dest MAC(6)] [Src MAC(6)] [EtherType(2)] [Payload(46-1500)]
    // MAC will add: Preamble, SFD, FCS (CRC-32), padding (if needed)
    
    /// TX data byte
    input wire [7:0]   tx_axis_tdata,
    /// TX data valid
    input wire         tx_axis_tvalid,
    /// TX ready for data (backpressure from MAC)
    output wire        tx_axis_tready,
    /// TX last byte of frame
    input wire         tx_axis_tlast,
    /// TX error indication (1 = error, causes error marking in GMII)
    input wire         tx_axis_tuser,

    //===========================================================================
    // AXI-STREAM RX INTERFACE (Output to System)
    //===========================================================================
    // MAC sends received Ethernet frames to system
    // Frame format: [Dest MAC(6)] [Src MAC(6)] [EtherType(2)] [Payload(46-1500)]
    // MAC has removed: Preamble, SFD, FCS (CRC-32)
    // Only frames with good FCS are output
    
    /// RX data byte
    output wire [7:0]  rx_axis_tdata,
    /// RX data valid
    output wire        rx_axis_tvalid,
    /// RX last byte of frame
    output wire        rx_axis_tlast,
    /// RX error indication (1 = FCS error or other error)
    output wire        rx_axis_tuser,

    //===========================================================================
    // GMII INTERFACE (Gigabit Media Independent Interface to PHY)
    //===========================================================================
    // Physical layer interface (8-bit parallel @ 125 MHz = 1 Gbps)
    
    // RX Signals (from PHY to MAC)
    /// RX data byte from PHY
    input wire [7:0]   gmii_rxd,
    /// RX data valid (1 = data is valid)
    input wire         gmii_rx_dv,
    /// RX error from PHY (1 = error detected)
    input wire         gmii_rx_er,
    
    // TX Signals (from MAC to PHY)
    /// TX data byte to PHY
    output wire [7:0]  gmii_txd,
    /// TX enable (1 = transmitting data)
    output wire        gmii_tx_en,
    /// TX error to PHY (1 = intentional error marking)
    output wire        gmii_tx_er,

    //===========================================================================
    // CONTROL SIGNALS
    //===========================================================================
    /// RX clock enable (1 = process RX, 0 = ignore RX)
    input wire         rx_clk_enable,
    /// TX clock enable (1 = process TX, 0 = hold TX)
    input wire         tx_clk_enable,
    /// RX MII mode select (1 = 10/100 Mbps MII, 0 = 1 Gbps GMII)
    input wire         rx_mii_select,
    /// TX MII mode select (1 = 10/100 Mbps MII, 0 = 1 Gbps GMII)
    input wire         tx_mii_select,
 
    //===========================================================================
    // STATUS SIGNALS
    //===========================================================================
    /// RX bad frame error (1 = frame had error, pulsed per frame)
    output wire        rx_error_bad_frame,
    /// RX FCS error (1 = CRC-32 check failed, pulsed per frame)
    output wire        rx_error_bad_fcs,
    /// Last received FCS value (for debugging)
    output wire [31:0] rx_fcs_reg,
    /// Last transmitted FCS value (for debugging)
    output wire [31:0] tx_fcs_reg,

    //===========================================================================
    // CONFIGURATION
    //===========================================================================
    /// Inter-Frame Gap delay in bytes (IEEE 802.3 specifies 12 bytes = 96 bit times)
    /// Delay between consecutive transmitted frames
    /// Default should be 12 for standard Ethernet
    input wire [7:0]   ifg_delay
);

  //===========================================================================
  // RX PATH: GMII RECEIVER (GMII → AXI-Stream)
  //===========================================================================
  // Converts incoming GMII signals from PHY to AXI-Stream packets for system
  // 
  // Functions:
  //   - Detects and removes preamble (7 × 0x55) and SFD (0xD5)
  //   - Receives frame data
  //   - Calculates and checks CRC-32 (FCS)
  //   - Outputs frame to AXI-Stream if FCS is good
  //   - Discards frames with FCS errors
  //   - Sets tuser=1 on frames with errors
  
  axis_gmii_rx
  axis_gmii_rx_inst (
    .clk(rx_clk),                        // RX clock (125 MHz from PHY)
    .rst(rx_rst),                        // RX reset (active-high)
    
    // GMII RX Interface (from PHY)
    .gmii_rxd(gmii_rxd),                 // RX data [7:0]
    .gmii_rx_dv(gmii_rx_dv),             // RX data valid
    .gmii_rx_er(gmii_rx_er),             // RX error from PHY
    
    // AXI-Stream Master Interface (to system)
    .m_axis_tdata(rx_axis_tdata),        // Output data [7:0]
    .m_axis_tvalid(rx_axis_tvalid),      // Output valid
    .m_axis_tlast(rx_axis_tlast),        // Output last byte
    .m_axis_tuser(rx_axis_tuser),        // Output error flag
    
    // Control
    .clk_enable(rx_clk_enable),          // Clock enable
    .mii_select(rx_mii_select),          // MII mode (1=10/100Mbps, 0=1Gbps)
    
    // Status
    .error_bad_frame(rx_error_bad_frame), // Bad frame pulse
    .error_bad_fcs(rx_error_bad_fcs),     // FCS error pulse
    .fcs_reg(rx_fcs_reg)                  // Last FCS value (debug)
  );

  //===========================================================================
  // TX PATH: GMII TRANSMITTER (AXI-Stream → GMII)
  //===========================================================================
  // Converts outgoing AXI-Stream packets from system to GMII signals for PHY
  //
  // Functions:
  //   - Adds preamble (7 × 0x55) and SFD (0xD5)
  //   - Transmits frame data
  //   - Calculates and appends CRC-32 (FCS)
  //   - Pads short frames to minimum length (if enabled)
  //   - Enforces inter-frame gap (96 bit times / 12 bytes)
  //   - Asserts tx_er if tuser=1 (error marking)
  
  axis_gmii_tx #(
    .ENABLE_PADDING(ENABLE_PADDING),     // Enable padding of short frames
    .MIN_FRAME_LENGTH(MIN_FRAME_LENGTH)  // Minimum frame length (64 bytes)
  )
  axis_gmii_tx_inst (
    .clk(tx_clk),                        // TX clock (125 MHz)
    .rst(tx_rst),                        // TX reset (active-high)
    
    // AXI-Stream Slave Interface (from system)
    .s_axis_tdata(tx_axis_tdata),        // Input data [7:0]
    .s_axis_tvalid(tx_axis_tvalid),      // Input valid
    .s_axis_tready(tx_axis_tready),      // Input ready (backpressure)
    .s_axis_tlast(tx_axis_tlast),        // Input last byte
    .s_axis_tuser(tx_axis_tuser),        // Input error flag
    
    // GMII TX Interface (to PHY)
    .gmii_txd(gmii_txd),                 // TX data [7:0]
    .gmii_tx_en(gmii_tx_en),             // TX enable
    .gmii_tx_er(gmii_tx_er),             // TX error (from tuser)
    
    // Control
    .clk_enable(tx_clk_enable),          // Clock enable
    .mii_select(tx_mii_select),          // MII mode (1=10/100Mbps, 0=1Gbps)
    .ifg_delay(ifg_delay),               // Inter-frame gap (12 bytes)
    
    // Status
    .fcs_reg(tx_fcs_reg)                 // Last FCS value (debug)
  );

endmodule

