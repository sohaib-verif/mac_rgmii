

// Language: Verilog 2001

//=============================================================================
// RGMII SYSTEM-ON-CHIP INTEGRATION MODULE
//=============================================================================
// This module integrates the RGMII physical layer with the MAC layer,
// providing a complete Ethernet subsystem.
//
// PURPOSE:
//   - Integrates rgmii_core (physical layer) with eth_mac_1g_rgmii (MAC)
//   - Provides system-level interface with AXI-Stream
//   - Handles clock domain management
//   - Manages PHY control signals (reset, interrupt)
//
// ARCHITECTURE:
//   AXI-Stream (8-bit) ↔ MAC ↔ GMII ↔ RGMII Core ↔ RGMII PHY Interface
//
// FUNCTIONAL BLOCKS:
//   1. **RGMII Core**: Physical layer (GMII ↔ RGMII DDR)
//   2. **MAC**: Ethernet MAC (frame processing, FCS, IFG)
//   3. **Clock Management**: Distributes 125 MHz and 90° clocks
//   4. **PHY Control**: Reset, interrupt, power management
//
// INTERFACES:
//   - AXI-Stream: 8-bit packet data (system side)
//   - RGMII: 4-bit DDR physical interface (PHY side)
//   - MDIO: PHY management interface
//   - Control: PHY reset, interrupts, status
//
// CLOCKING:
//   - clk_int: 125 MHz system clock
//   - clk90_int: 125 MHz 90° shifted (for RGMII TX DDR)
//   - clk_200_int: 200 MHz (for IDELAY calibration)
//   - phy_rx_clk: 125 MHz from PHY (source-synchronous RX)
//=============================================================================

module rgmii_soc (
    // Internal 125 MHz clock
    input              clk_int,
    input              rst_int,
    input              clk90_int,
    input              clk_200_int,

    /*
     * Ethernet: 1000BASE-T RGMII
     */
    input wire         phy_rx_clk,
    input wire [3:0]   phy_rxd,
    input wire         phy_rx_ctl,
    output wire        phy_tx_clk,
    output wire [3:0]  phy_txd,
    output wire        phy_tx_ctl,
    output wire        phy_reset_n,
    input wire         phy_int_n,
    input wire         phy_pme_n,
    output wire        mac_gmii_tx_en,

       /*
        * AXI input
        */
    input wire         tx_axis_tvalid,
    input wire         tx_axis_tlast,
    input wire [7:0]   tx_axis_tdata,
    output wire        tx_axis_tready,
    input wire         tx_axis_tuser,

       /*
        * AXI output
        */
    output wire [7:0]  rx_axis_tdata,
    output wire        rx_axis_tvalid,
    output wire        rx_axis_tlast,
    output             rx_axis_tuser,

    /*
     * Status
     */

    output wire [31:0] rx_fcs_reg,
    output wire [31:0] tx_fcs_reg

);

// IODELAY elements for RGMII interface to PHY
wire [3:0] phy_rxd_delay;
wire       phy_rx_ctl_delay;

`ifdef GENESYSII

IDELAYCTRL
idelayctrl_inst
(
    .REFCLK(clk_200_int),
    .RST(rst_int),
    .RDY()
);

IDELAYE2 #(
    .IDELAY_TYPE("FIXED")
)
phy_rxd_idelay_0
(
    .IDATAIN(phy_rxd[0]),
    .DATAOUT(phy_rxd_delay[0]),
    .DATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .CINVCTRL(1'b0),
    .CNTVALUEIN(5'd0),
    .CNTVALUEOUT(),
    .LD(1'b0),
    .LDPIPEEN(1'b0),
    .REGRST(1'b0)
);

IDELAYE2 #(
    .IDELAY_TYPE("FIXED")
)
phy_rxd_idelay_1
(
    .IDATAIN(phy_rxd[1]),
    .DATAOUT(phy_rxd_delay[1]),
    .DATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .CINVCTRL(1'b0),
    .CNTVALUEIN(5'd0),
    .CNTVALUEOUT(),
    .LD(1'b0),
    .LDPIPEEN(1'b0),
    .REGRST(1'b0)
);

IDELAYE2 #(
    .IDELAY_TYPE("FIXED")
)
phy_rxd_idelay_2
(
    .IDATAIN(phy_rxd[2]),
    .DATAOUT(phy_rxd_delay[2]),
    .DATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .CINVCTRL(1'b0),
    .CNTVALUEIN(5'd0),
    .CNTVALUEOUT(),
    .LD(1'b0),
    .LDPIPEEN(1'b0),
    .REGRST(1'b0)
);

IDELAYE2 #(
    .IDELAY_TYPE("FIXED")
)
phy_rxd_idelay_3
(
    .IDATAIN(phy_rxd[3]),
    .DATAOUT(phy_rxd_delay[3]),
    .DATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .CINVCTRL(1'b0),
    .CNTVALUEIN(5'd0),
    .CNTVALUEOUT(),
    .LD(1'b0),
    .LDPIPEEN(1'b0),
    .REGRST(1'b0)
);

IDELAYE2 #(
    .IDELAY_VALUE(0),
    .IDELAY_TYPE("FIXED")
)
phy_rx_ctl_idelay
(
    .IDATAIN(phy_rx_ctl),
    .DATAOUT(phy_rx_ctl_delay),
    .DATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .CINVCTRL(1'b0),
    .CNTVALUEIN(5'd0),
    .CNTVALUEOUT(),
    .LD(1'b0),
    .LDPIPEEN(1'b0),
    .REGRST(1'b0)
);

`else // !`ifdef GENESYSII
   assign phy_rx_ctl_delay = phy_rx_ctl;
   assign phy_rxd_delay = phy_rxd;
`endif

rgmii_core
core_inst (
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    .clk(clk_int),
    .clk90(clk90_int),
    .rst(rst_int),
    /*
     * Ethernet: 1000BASE-T RGMII
     */
    .phy_rx_clk(phy_rx_clk),
    .phy_rxd(phy_rxd_delay),
    .phy_rx_ctl(phy_rx_ctl_delay),
    .phy_tx_clk(phy_tx_clk),
    .phy_txd(phy_txd),
    .phy_tx_ctl(phy_tx_ctl),
    .phy_reset_n(phy_reset_n),
    .phy_int_n(phy_int_n),
    .phy_pme_n(phy_pme_n),
    .mac_gmii_tx_en(mac_gmii_tx_en),
    .tx_axis_tdata(tx_axis_tdata),
    .tx_axis_tvalid(tx_axis_tvalid),
    .tx_axis_tready(tx_axis_tready),
    .tx_axis_tlast(tx_axis_tlast),
    .tx_axis_tuser(tx_axis_tuser),
    .rx_axis_tdata(rx_axis_tdata),
    .rx_axis_tvalid(rx_axis_tvalid),
    .rx_axis_tlast(rx_axis_tlast),
    .rx_axis_tuser(rx_axis_tuser),
    .rx_fcs_reg(rx_fcs_reg),
    .tx_fcs_reg(tx_fcs_reg)
);

endmodule
