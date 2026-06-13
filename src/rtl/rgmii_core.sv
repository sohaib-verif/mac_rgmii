

//=============================================================================
// RGMII CORE - Physical Layer Interface
//=============================================================================
// This module implements the RGMII (Reduced Gigabit Media Independent Interface)
// physical layer, converting between 8-bit GMII and 4-bit DDR RGMII.
//
// PURPOSE:
//   - Converts GMII (8-bit SDR) ↔ RGMII (4-bit DDR) for Gigabit Ethernet
//   - Handles TX and RX data paths with DDR signaling
//   - Manages RGMII clock generation and sampling
//
// RGMII OPERATION:
//   - TX: 8-bit GMII @ 125 MHz → 4-bit DDR RGMII @ 125 MHz (both clock edges)
//   - RX: 4-bit DDR RGMII @ 125 MHz → 8-bit GMII @ 125 MHz
//   - Bandwidth: 4 bits × 2 (DDR) × 125 MHz = 1000 Mbps = 1 Gbps
//
// TX PATH:
//   - Takes 8-bit GMII data (gmii_txd[7:0])
//   - Splits into two 4-bit words: [7:4] and [3:0]
//   - Uses ODDR to output on both clock edges
//   - Result: 4-bit DDR RGMII (rgmii_txd[3:0])
//
// RX PATH:
//   - Receives 4-bit DDR RGMII (rgmii_rxd[3:0])
//   - Uses IDDR to capture on both clock edges
//   - Combines into 8-bit GMII data (gmii_rxd[7:0])
//
// CONTROL SIGNALS:
//   - RGMII uses in-band signaling (control encoded with data)
//   - rgmii_tx_ctl: DDR signal encoding tx_en and tx_er
//   - rgmii_rx_ctl: DDR signal encoding rx_dv and rx_er
//
// CLOCKING:
//   - clk: 125 MHz system clock
//   - clk90: 125 MHz 90° shifted for DDR TX output
//   - rgmii_rx_clk: 125 MHz clock from PHY (source-synchronous)
//=============================================================================

module rgmii_core #
(
`ifdef GENESYSII
 parameter TARGET = "XILINX"
`else
 parameter TARGET = "GENERIC"
`endif
)
(
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    input wire         clk,
    input wire         clk90,
    input wire         rst,

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
    output wire        rx_axis_tuser,

    /*
     * Status
     */

    output wire [31:0] rx_fcs_reg,
    output wire [31:0] tx_fcs_reg

);

assign phy_reset_n = !rst;

eth_mac_1g_rgmii_fifo #(
    .TARGET(TARGET),
    .IODDR_STYLE("IODDR"),
    .CLOCK_INPUT_STYLE("BUFR"),
    .USE_CLK90("FALSE"), //TRUE
    .ENABLE_PADDING(1),
    .MIN_FRAME_LENGTH(64),
    .TX_FIFO_ADDR_WIDTH(12),
    .TX_FRAME_FIFO(1),
    .RX_FIFO_ADDR_WIDTH(12),
    .RX_FRAME_FIFO(1)
)
eth_mac_inst (
    .gtx_clk(clk),
    .gtx_clk90(clk90),
    .gtx_rst(rst),
    .logic_clk(clk),
    .logic_rst(rst),

    .tx_axis_tdata(tx_axis_tdata),
    .tx_axis_tvalid(tx_axis_tvalid),
    .tx_axis_tready(tx_axis_tready),
    .tx_axis_tlast(tx_axis_tlast),
    .tx_axis_tuser(tx_axis_tuser),

    .rx_axis_tdata(rx_axis_tdata),
    .rx_axis_tvalid(rx_axis_tvalid),
    .rx_axis_tready(1'b1),
    .rx_axis_tlast(rx_axis_tlast),
    .rx_axis_tuser(rx_axis_tuser),

    .rgmii_rx_clk(phy_rx_clk),
    .rgmii_rxd(phy_rxd),
    .rgmii_rx_ctl(phy_rx_ctl),
    .rgmii_tx_clk(phy_tx_clk),
    .rgmii_txd(phy_txd),
    .rgmii_tx_ctl(phy_tx_ctl),
    .mac_gmii_tx_en(mac_gmii_tx_en),

    .tx_fifo_overflow(),
    .tx_fifo_bad_frame(),
    .tx_fifo_good_frame(),
    .rx_error_bad_frame(),
    .rx_error_bad_fcs(),
    .rx_fcs_reg(rx_fcs_reg),
    .tx_fcs_reg(tx_fcs_reg),
    .rx_fifo_overflow(),
    .rx_fifo_bad_frame(),
    .rx_fifo_good_frame(),
    .speed(),

    .ifg_delay(8'd12)
);

endmodule
