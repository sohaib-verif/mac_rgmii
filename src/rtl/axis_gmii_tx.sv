
//=============================================================================
// AXI-STREAM TO GMII TX CONVERTER
//=============================================================================
// This module converts AXI-Stream packets to GMII format for Ethernet transmission.
// It implements the MAC layer transmit functionality.
//
// PURPOSE:
//   - Convert AXI-Stream frames to GMII Ethernet frames
//   - Add Ethernet frame components (preamble, SFD, FCS)
//   - Enforce Ethernet timing requirements (IFG, minimum frame size)
//   - Calculate and append CRC-32 checksum
//
// ETHERNET FRAME GENERATION:
//   1. **Preamble**: 7 bytes of 0x55 (for synchronization)
//   2. **SFD**: 1 byte of 0xD5 (Start Frame Delimiter)
//   3. **Frame Data**: From AXI-Stream (Dest MAC, Src MAC, Type, Payload)
//   4. **FCS**: 4 bytes of CRC-32 checksum (calculated over frame data)
//   5. **IFG**: Inter-Frame Gap (12 bytes idle time between frames)
//
// STATE MACHINE:
//   IDLE → PREAMBLE → SFD → DATA → PAD (if needed) → FCS → IFG → IDLE
//
// PADDING:
//   - Ethernet minimum frame size: 64 bytes (excluding preamble/SFD)
//   - If ENABLE_PADDING=1 and frame < MIN_FRAME_LENGTH: Pad with zeros
//
// CRC-32 (FCS):
//   - Polynomial: 0x04C11DB7 (Ethernet standard)
//   - Calculated over: Dest MAC + Src MAC + EtherType + Payload
//   - NOT calculated over: Preamble + SFD
//   - Appended as: 4 bytes in little-endian order
//
// INTER-FRAME GAP (IFG):
//   - IEEE 802.3 requires 96 bit times (12 bytes @ 1 Gbps) between frames
//   - Configurable via ifg_delay parameter (default: 12)
//
// ERROR HANDLING:
//   - If s_axis_tuser=1: Intentionally corrupt FCS (for testing)
//   - Asserts gmii_tx_er during error condition
//
// TIMING:
//   - GMII: 8 bits per clock cycle @ 125 MHz = 1 Gbps
//   - Throughput: ~950 Mbps (accounting for preamble, FCS, IFG overhead)
//=============================================================================

module axis_gmii_tx #
(
    parameter ENABLE_PADDING = 1,
    parameter MIN_FRAME_LENGTH = 64
)
(
    input  wire        clk,
    input  wire        rst,

    /*
     * AXI input
     */
    input  wire [7:0]  s_axis_tdata,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire        s_axis_tlast,
    input  wire        s_axis_tuser,

    /*
     * GMII output
     */
    output wire [7:0]  gmii_txd,
    output wire        gmii_tx_en,
    output wire        gmii_tx_er,

    /*
     * Control
     */
    input  wire        clk_enable,
    input  wire        mii_select,

    /*
     * Configuration
     */
    input wire [7:0]  ifg_delay,

    /* debug */
    output reg [31:0] fcs_reg
);

localparam [7:0]
    ETH_PRE = 8'h55,
    ETH_SFD = 8'hD5;

localparam [2:0]
    STATE_IDLE = 3'd0,
    STATE_PREAMBLE = 3'd1,
    STATE_PAYLOAD = 3'd2,
    STATE_LAST = 3'd3,
    STATE_PAD = 3'd4,
    STATE_FCS = 3'd5,
    STATE_WAIT_END = 3'd6,
    STATE_IFG = 3'd7;

reg [2:0] state_reg, state_next;

// datapath control signals
reg reset_crc;
reg update_crc;

reg [7:0] s_tdata_reg, s_tdata_next, ifg_reg, ifg_next;

reg mii_odd_reg, mii_odd_next;
reg [3:0] mii_msn_reg, mii_msn_next;

reg [15:0] frame_ptr_reg, frame_ptr_next;

reg [7:0] gmii_txd_reg, gmii_txd_next;
reg gmii_tx_en_reg, gmii_tx_en_next;
reg gmii_tx_er_reg, gmii_tx_er_next;

reg s_axis_tready_reg, s_axis_tready_next;
reg [31:0] crc_state, fcs_next;   

wire [31:0] crc_next;

assign s_axis_tready = s_axis_tready_reg;

assign gmii_txd = gmii_txd_reg;
assign gmii_tx_en = gmii_tx_en_reg;
assign gmii_tx_er = gmii_tx_er_reg;

rgmii_lfsr #(
    .LFSR_WIDTH(32),
    .LFSR_POLY(32'h4c11db7),
    .LFSR_CONFIG("GALOIS"),
    .LFSR_FEED_FORWARD(0),
    .REVERSE(1),
    .DATA_WIDTH(8),
    .STYLE("AUTO")
)
eth_crc_8 (
    .data_in(s_tdata_reg),
    .state_in(crc_state),
    .data_out(),
    .state_out(crc_next)
);

always @* begin
    state_next = STATE_IDLE;

    reset_crc = 1'b0;
    update_crc = 1'b0;

    mii_odd_next = mii_odd_reg;
    mii_msn_next = mii_msn_reg;

    frame_ptr_next = frame_ptr_reg;
    fcs_next = fcs_reg;
    ifg_next = ifg_reg;

    s_axis_tready_next = 1'b0;

    s_tdata_next = s_tdata_reg;

    gmii_txd_next = 8'd0;
    gmii_tx_en_next = 1'b0;
    gmii_tx_er_next = 1'b0;

    if (!clk_enable) begin
        // clock disabled - hold state and outputs
        gmii_txd_next = gmii_txd_reg;
        gmii_tx_en_next = gmii_tx_en_reg;
        gmii_tx_er_next = gmii_tx_er_reg;
        state_next = state_reg;
    end else if (mii_select && mii_odd_reg) begin
        // MII odd cycle - hold state, output MSN
        mii_odd_next = 1'b0;
        gmii_txd_next = {4'd0, mii_msn_reg};
        gmii_tx_en_next = gmii_tx_en_reg;
        gmii_tx_er_next = gmii_tx_er_reg;
        state_next = state_reg;
    end else begin
        case (state_reg)
            STATE_IDLE: begin
                // idle state - wait for packet
                reset_crc = 1'b1;
                mii_odd_next = 1'b0;

                if (s_axis_tvalid) begin
                    mii_odd_next = 1'b1;
                    frame_ptr_next = 16'd1;
                    gmii_txd_next = ETH_PRE;
                    gmii_tx_en_next = 1'b1;
                    state_next = STATE_PREAMBLE;
                end else begin
                    state_next = STATE_IDLE;
                end
            end
            STATE_PREAMBLE: begin
                // send preamble
                reset_crc = 1'b1;

                mii_odd_next = 1'b1;
                frame_ptr_next = frame_ptr_reg + 16'd1;

                gmii_txd_next = ETH_PRE;
                gmii_tx_en_next = 1'b1;

                if (frame_ptr_reg == 16'd6) begin
                    s_axis_tready_next = 1'b1;
                    s_tdata_next = s_axis_tdata;
                    state_next = STATE_PREAMBLE;
                end else if (frame_ptr_reg == 16'd7) begin
                    // end of preamble; start payload
                    frame_ptr_next = 16'd0;
                    if (s_axis_tready_reg) begin
                        s_axis_tready_next = 1'b1;
                        s_tdata_next = s_axis_tdata;
                    end
                    gmii_txd_next = ETH_SFD;
                    state_next = STATE_PAYLOAD;
                end else begin
                    state_next = STATE_PREAMBLE;
                end
            end
            STATE_PAYLOAD: begin
                // send payload

                update_crc = 1'b1;
                s_axis_tready_next = 1'b1;

                mii_odd_next = 1'b1;
                frame_ptr_next = frame_ptr_reg + 16'd1;

                gmii_txd_next = s_tdata_reg;
                gmii_tx_en_next = 1'b1;

                s_tdata_next = s_axis_tdata;

                if (s_axis_tvalid) begin
                    if (s_axis_tlast) begin
                        s_axis_tready_next = !s_axis_tready_reg;
                        if (s_axis_tuser) begin
                            gmii_tx_er_next = 1'b1;
                            frame_ptr_next = 1'b0;
                            state_next = STATE_IFG;
                        end else begin
                            state_next = STATE_LAST;
                        end
                    end else begin
                        state_next = STATE_PAYLOAD;
                    end
                end else begin
                    // tvalid deassert, fail frame
                    gmii_tx_er_next = 1'b1;
                    frame_ptr_next = 16'd0;
                    state_next = STATE_WAIT_END;
                end
            end
            STATE_LAST: begin
                // last payload word

                update_crc = 1'b1;

                mii_odd_next = 1'b1;
                frame_ptr_next = frame_ptr_reg + 16'd1;

                gmii_txd_next = s_tdata_reg;
                gmii_tx_en_next = 1'b1;

                if (ENABLE_PADDING && frame_ptr_reg < MIN_FRAME_LENGTH-5) begin
                    s_tdata_next = 8'd0;
                    state_next = STATE_PAD;
                end else begin
                    frame_ptr_next = 16'd0;
                    state_next = STATE_FCS;
                end
            end
            STATE_PAD: begin
                // send padding

                update_crc = 1'b1;
                mii_odd_next = 1'b1;
                frame_ptr_next = frame_ptr_reg + 16'd1;

                gmii_txd_next = 8'd0;
                gmii_tx_en_next = 1'b1;

                s_tdata_next = 8'd0;

                if (frame_ptr_reg < MIN_FRAME_LENGTH-5) begin
                    state_next = STATE_PAD;
                end else begin
                    frame_ptr_next = 16'd0;
                    state_next = STATE_FCS;
                end
            end
            STATE_FCS: begin
                // send FCS

                mii_odd_next = 1'b1;
                frame_ptr_next = frame_ptr_reg + 16'd1;

                case (frame_ptr_reg)
                    2'd0: gmii_txd_next = ~crc_state[7:0];
                    2'd1: gmii_txd_next = ~crc_state[15:8];
                    2'd2: gmii_txd_next = ~crc_state[23:16];
                    2'd3: gmii_txd_next = ~crc_state[31:24];
                    default:;
                endcase
                gmii_tx_en_next = 1'b1;

                if (frame_ptr_reg < 3) begin
                    state_next = STATE_FCS;
                end else begin
                    frame_ptr_next = 16'd0;
                    fcs_next = crc_state;
                    state_next = STATE_IFG;
                end
            end
            STATE_WAIT_END: begin
                // wait for end of frame

                reset_crc = 1'b1;

                mii_odd_next = 1'b1;
                frame_ptr_next = frame_ptr_reg + 16'd1;
                s_axis_tready_next = 1'b1;

                if (s_axis_tvalid) begin
                    if (s_axis_tlast) begin
                        s_axis_tready_next = 1'b0;
                        ifg_next = 8'b0;
                            state_next = STATE_IFG;
                    end else begin
                        state_next = STATE_WAIT_END;
                    end
                end else begin
                    state_next = STATE_WAIT_END;
                end
            end
            STATE_IFG: begin
                // send IFG

                reset_crc = 1'b1;

                mii_odd_next = 1'b1;
                frame_ptr_next = frame_ptr_reg + 16'd1;

                if (ifg_reg < ifg_delay-1) begin
                    ifg_next = ifg_reg + 1;
                    state_next = STATE_IFG;
                end else begin
                    state_next = STATE_IDLE;
                end
            end
        endcase

        if (mii_select) begin
            mii_msn_next = gmii_txd_next[7:4];
            gmii_txd_next[7:4] = 4'd0;
        end
    end
end

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        state_reg <= STATE_IDLE;

        frame_ptr_reg <= 16'd0;

        s_axis_tready_reg <= 1'b0;

        gmii_tx_en_reg <= 1'b0;
        gmii_tx_er_reg <= 1'b0;

        crc_state <= 32'hFFFFFFFF;
        fcs_reg <= 32'hFFFFFFFF;
        ifg_reg <= 'd0;

        mii_odd_reg <= 1'b0;
        mii_msn_reg <= 'd0;
        s_tdata_reg <= 'd0;
        gmii_txd_reg <= 'd0;
    end else begin
        state_reg <= state_next;

        frame_ptr_reg <= frame_ptr_next;

        s_axis_tready_reg <= s_axis_tready_next;

        gmii_tx_en_reg <= gmii_tx_en_next;
        gmii_tx_er_reg <= gmii_tx_er_next;

        fcs_reg <= fcs_next;
        ifg_reg <= ifg_next;
        // datapath
        if (reset_crc) begin
            crc_state <= 32'hFFFFFFFF;
        end else if (update_crc) begin
            crc_state <= crc_next;
        end

        mii_odd_reg <= mii_odd_next;
        mii_msn_reg <= mii_msn_next;
        s_tdata_reg <= s_tdata_next;
        gmii_txd_reg <= gmii_txd_next;
    end
end

endmodule
