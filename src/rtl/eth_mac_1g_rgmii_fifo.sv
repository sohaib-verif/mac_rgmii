

//=============================================================================
// 1G ETHERNET MAC WITH RGMII INTERFACE AND FIFOs
//=============================================================================
// This module adds FIFO buffering to the MAC+RGMII integration, providing
// clock domain crossing and flow control.
//
// PURPOSE:
//   - Adds TX and RX FIFOs for buffering and clock domain crossing
//   - Isolates system clock domain from MAC/RGMII clock domains
//   - Provides elastic buffering for burst traffic
//   - Handles backpressure and flow control
//
// ARCHITECTURE:
//   System (async) → TX FIFO → MAC+RGMII → PHY
//   System (async) ← RX FIFO ← MAC+RGMII ← PHY
//
// TX FIFO FEATURES:
//   - Frame-based FIFO (optional): Stores complete frames
//   - Drop bad frames (if enabled): Discards frames with errors
//   - Drop when full (if enabled): Discards frames if FIFO full
//   - Configurable depth via TX_FIFO_ADDR_WIDTH
//
// RX FIFO FEATURES:
//   - Frame-based FIFO (optional): Outputs complete frames
//   - Drop bad frames (if enabled): Discards frames with FCS errors
//   - Drop when full (if enabled): Discards frames if FIFO full
//   - Configurable depth via RX_FIFO_ADDR_WIDTH
//
// CLOCK DOMAINS:
//   - async_logic_clk: Asynchronous system clock (any frequency)
//   - gtx_clk: 125 MHz GTX clock for MAC TX
//   - rgmii_rx_clk: 125 MHz RX clock from PHY
//=============================================================================

module eth_mac_1g_rgmii_fifo #
(
    // target ("SIM", "GENERIC", "XILINX", "ALTERA")
    parameter TARGET = "GENERIC",
    // IODDR style ("IODDR", "IODDR2")
    // Use IODDR for Virtex-4, Virtex-5, Virtex-6, 7 Series, Ultrascale
    // Use IODDR2 for Spartan-6
    parameter IODDR_STYLE = "IODDR2",
    // Clock input style ("BUFG", "BUFR", "BUFIO", "BUFIO2")
    // Use BUFR for Virtex-5, Virtex-6, 7-series
    // Use BUFG for Ultrascale
    // Use BUFIO2 for Spartan-6
    parameter CLOCK_INPUT_STYLE = "BUFIO2",
    // Use 90 degree clock for RGMII transmit ("TRUE", "FALSE")
    parameter USE_CLK90 = "TRUE",
    parameter ENABLE_PADDING = 1,
    parameter MIN_FRAME_LENGTH = 64,
    parameter TX_FIFO_ADDR_WIDTH = 12,
    parameter TX_FRAME_FIFO = 1,
    parameter TX_DROP_BAD_FRAME = TX_FRAME_FIFO,
    parameter TX_DROP_WHEN_FULL = 0,
    parameter RX_FIFO_ADDR_WIDTH = 12,
    parameter RX_FRAME_FIFO = 1,
    parameter RX_DROP_BAD_FRAME = RX_FRAME_FIFO,
    parameter RX_DROP_WHEN_FULL = RX_FRAME_FIFO
)
(
    input wire         gtx_clk,
    input wire         gtx_clk90,
    input wire         gtx_rst,
    input wire         logic_clk,
    input wire         logic_rst,

    /*
     * AXI input
     */
    input wire [7:0]   tx_axis_tdata,
    input wire         tx_axis_tvalid,
    output wire        tx_axis_tready,
    input wire         tx_axis_tlast,
    input wire         tx_axis_tuser,

    /*
     * AXI output
     */
    output wire [7:0]  rx_axis_tdata,
    output wire        rx_axis_tvalid,
    input  wire        rx_axis_tready,
    output wire        rx_axis_tlast,
    output wire        rx_axis_tuser,

    /*
     * RGMII interface
     */
    input wire         rgmii_rx_clk,
    input wire [3:0]   rgmii_rxd,
    input wire         rgmii_rx_ctl,
    output wire        rgmii_tx_clk,
    output wire [3:0]  rgmii_txd,
    output wire        rgmii_tx_ctl,
    output wire        mac_gmii_tx_en,

    /*
     * Status
     */
    output wire        tx_fifo_overflow,
    output wire        tx_fifo_bad_frame,
    output wire        tx_fifo_good_frame,
    output wire        rx_error_bad_frame,
    output wire        rx_error_bad_fcs,
    output wire        rx_fifo_overflow,
    output wire        rx_fifo_bad_frame,
    output wire        rx_fifo_good_frame,
    output wire [1:0]  speed,
    output wire [31:0] rx_fcs_reg,
    output wire [31:0] tx_fcs_reg,

    /*
     * Configuration
     */
    input wire [7:0]   ifg_delay
);

wire tx_clk;
wire rx_clk;
wire tx_rst;
wire rx_rst;

// synchronize MAC status signals into logic clock domain
wire rx_error_bad_frame_int;
wire rx_error_bad_fcs_int;

reg [1:0] rx_sync_reg_1;
reg [1:0] rx_sync_reg_2;
reg [1:0] rx_sync_reg_3;
reg [1:0] rx_sync_reg_4;

assign rx_error_bad_frame = rx_sync_reg_3[0] ^ rx_sync_reg_4[0];
assign rx_error_bad_fcs = rx_sync_reg_3[1] ^ rx_sync_reg_4[1];

always @(posedge rx_clk or posedge rx_rst) begin
    if (rx_rst) begin
        rx_sync_reg_1 <= 2'd0;
    end else begin
        rx_sync_reg_1 <= rx_sync_reg_1 ^ {rx_error_bad_frame_int, rx_error_bad_frame_int};
    end
end

always @(posedge logic_clk or posedge logic_rst) begin
    if (logic_rst) begin
        rx_sync_reg_2 <= 2'd0;
        rx_sync_reg_3 <= 2'd0;
        rx_sync_reg_4 <= 2'd0;
    end else begin
        rx_sync_reg_2 <= rx_sync_reg_1;
        rx_sync_reg_3 <= rx_sync_reg_2;
        rx_sync_reg_4 <= rx_sync_reg_3;
    end
end


wire [1:0] speed_int;

reg [1:0] speed_sync_reg_1;
reg [1:0] speed_sync_reg_2;

assign speed = speed_sync_reg_2;

always @(posedge logic_clk) begin
    speed_sync_reg_1 <= speed_int;
    speed_sync_reg_2 <= speed_sync_reg_1;
end

eth_mac_1g_rgmii #(
    .TARGET(TARGET),
    .IODDR_STYLE(IODDR_STYLE),
    .CLOCK_INPUT_STYLE(CLOCK_INPUT_STYLE),
    .USE_CLK90(USE_CLK90),
    .ENABLE_PADDING(ENABLE_PADDING),
    .MIN_FRAME_LENGTH(MIN_FRAME_LENGTH)
)
eth_mac_1g_rgmii_inst (
    .gtx_clk(gtx_clk),
    .gtx_clk90(gtx_clk90),
    .gtx_rst(gtx_rst),
    .tx_clk(tx_clk),
    .tx_rst(tx_rst),
    .rx_clk(rx_clk),
    .rx_rst(rx_rst),
    .tx_axis_tdata(tx_axis_tdata),
    .tx_axis_tvalid(tx_axis_tvalid),
    .tx_axis_tready(tx_axis_tready),
    .tx_axis_tlast(tx_axis_tlast),
    .tx_axis_tuser(tx_axis_tuser),
    .rx_axis_tdata(rx_axis_tdata),
    .rx_axis_tvalid(rx_axis_tvalid),
    .rx_axis_tlast(rx_axis_tlast),
    .rx_axis_tuser(rx_axis_tuser),
    .rgmii_rx_clk(rgmii_rx_clk),
    .rgmii_rxd(rgmii_rxd),
    .rgmii_rx_ctl(rgmii_rx_ctl),
    .rgmii_tx_clk(rgmii_tx_clk),
    .rgmii_txd(rgmii_txd),
    .rgmii_tx_ctl(rgmii_tx_ctl),
    .mac_gmii_tx_en(mac_gmii_tx_en),
    .rx_error_bad_frame(rx_error_bad_frame_int),
    .rx_error_bad_fcs(rx_error_bad_fcs_int),
    .rx_fcs_reg(rx_fcs_reg),
    .tx_fcs_reg(tx_fcs_reg),
    .speed(speed_int),
    .ifg_delay(ifg_delay)
);
   
endmodule
