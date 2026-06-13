
//=============================================================================
// INPUT DDR (Double Data Rate) PRIMITIVE - Generic Wrapper
//=============================================================================
// This module provides a generic IDDR (Input DDR) wrapper that works across
// multiple FPGA families (Xilinx, Altera/Intel, Generic).
//
// PURPOSE IN ETHERNET IP:
//   - Used in RGMII RX path to capture 4-bit DDR data from Ethernet PHY
//   - Converts DDR input (data on both clock edges) to SDR (Single Data Rate)
//   - Essential for achieving 1 Gbps bandwidth with 125 MHz clock
//
// DDR OPERATION:
//   - Input: 4-bit data changing on both rising and falling clock edges
//   - Output: Two 4-bit words (q1=rising edge, q2=falling edge)
//   - Result: 8 bits captured per clock cycle (4-bit DDR → 8-bit SDR)
//
// RGMII EXAMPLE:
//   Clock:  125 MHz (8ns period)
//   Input:  phy_rxd[3:0] changes every 4ns (both edges)
//   q1:     Data captured on rising edge  (bits [7:4])
//   q2:     Data captured on falling edge (bits [3:0])
//   Output: 8 bits per cycle × 125 MHz = 1 Gbps
//
// TIMING DIAGRAM:
//                _____       _____       _____       _____       ____
//     clk  _____/     \_____/     \_____/     \_____/     \_____/
//          _ _____ _____ _____ _____ _____ _____ _____ _____ _____ _
//     d    _X_D0__X_D1__X_D2__X_D3__X_D4__X_D5__X_D6__X_D7__X_D8__X_
//          _______ ___________ ___________ ___________ ___________ _
//     q1   _______X___________X____D0_____X____D2_____X____D4_____X_  (rising)
//          _______ ___________ ___________ ___________ ___________ _
//     q2   _______X___________X____D1_____X____D3_____X____D5_____X_  (falling)
//
// TARGET FPGAS:
//   - XILINX:  Uses IDDR or IDDR2 primitives (7-series, Ultrascale, Spartan-6)
//   - ALTERA:  Uses altddio_in megafunction
//   - GENERIC: Uses registers on positive/negative clock edges (simulation/ASIC)
//=============================================================================

module iddr #
(
    // target ("SIM", "GENERIC", "XILINX", "ALTERA")
    parameter TARGET = "GENERIC",
    // IODDR style ("IODDR", "IODDR2")
    // Use IODDR for Virtex-4, Virtex-5, Virtex-6, 7 Series, Ultrascale
    // Use IODDR2 for Spartan-6
    parameter IODDR_STYLE = "IODDR2",
    // Width of register in bits
    parameter WIDTH = 1
)
(
    input  wire             clk,

    input  wire [WIDTH-1:0] d,

    output wire [WIDTH-1:0] q1,
    output wire [WIDTH-1:0] q2
);

/*

Provides a consistent input DDR flip flop across multiple FPGA families
              _____       _____       _____       _____       ____
    clk  ____/     \_____/     \_____/     \_____/     \_____/
         _ _____ _____ _____ _____ _____ _____ _____ _____ _____ _
    d    _X_D0__X_D1__X_D2__X_D3__X_D4__X_D5__X_D6__X_D7__X_D8__X_
         _______ ___________ ___________ ___________ ___________ _
    q1   _______X___________X____D0_____X____D2_____X____D4_____X_
         _______ ___________ ___________ ___________ ___________ _
    q2   _______X___________X____D1_____X____D3_____X____D5_____X_

*/

genvar n;

generate

if (TARGET == "XILINX") begin
    for (n = 0; n < WIDTH; n = n + 1) begin : iddr
        if (IODDR_STYLE == "IODDR") begin
            IDDR #(
                .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"),
                .SRTYPE("ASYNC")
            )
            iddr_inst (
                .Q1(q1[n]),
                .Q2(q2[n]),
                .C(clk),
                .CE(1'b1),
                .D(d[n]),
                .R(1'b0),
                .S(1'b0)
            );
        end else if (IODDR_STYLE == "IODDR2") begin
            IDDR2 #(
                .DDR_ALIGNMENT("C0")
            )
            iddr_inst (
                .Q0(q1[n]),
                .Q1(q2[n]),
                .C0(clk),
                .C1(~clk),
                .CE(1'b1),
                .D(d[n]),
                .R(1'b0),
                .S(1'b0)
            );
        end
    end
end else if (TARGET == "ALTERA") begin
    wire [WIDTH-1:0] q1_int;
    reg [WIDTH-1:0] q1_delay;

    altddio_in #(
        .WIDTH(WIDTH),
        .POWER_UP_HIGH("OFF")
    )
    altddio_in_inst (
        .aset(1'b0),
        .datain(d),
        .inclocken(1'b1),
        .inclock(clk),
        .aclr(1'b0),
        .dataout_h(q1_int),
        .dataout_l(q2)
    );

    always @(posedge clk) begin
        q1_delay <= q1_int;
    end

    assign q1 = q1_delay;
end else begin
    reg [WIDTH-1:0] d_reg_1 = {WIDTH{1'b0}};
    reg [WIDTH-1:0] d_reg_2 = {WIDTH{1'b0}};

    reg [WIDTH-1:0] q_reg_1 = {WIDTH{1'b0}};
    reg [WIDTH-1:0] q_reg_2 = {WIDTH{1'b0}};

    always @(posedge clk) begin
        d_reg_1 <= d;
    end

    always @(negedge clk) begin
        d_reg_2 <= d;
    end

    always @(posedge clk) begin
        q_reg_1 <= d_reg_1;
        q_reg_2 <= d_reg_2;
    end

    assign q1 = q_reg_1;
    assign q2 = q_reg_2;
end

endgenerate

endmodule
