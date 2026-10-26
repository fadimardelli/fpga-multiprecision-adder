`timescale 1ns / 1ps
//==============================================================================
// Module      : CSA_64b
// Project     : 512-bit multi-precision adder/subtractor on FPGA (PYNQ-Z2, Zynq-7020)
// Description : 64-bit carry-select adder with 16-bit two-level CLA blocks.
//==============================================================================

module CSA_64b#(
    parameter CLA_WIDTH = 16
)
(
    input   wire [63:0]  iA, iB,
    input   wire                    iCarry,
    output  wire [63:0]  oSum,
    output  wire                    oCarry
);

wire [63:16] wSum_0, wSum_1;
wire [3:1] wCarry_0, wCarry_1;
wire [4:1] wCon;
genvar i;

// least-significant block: uses the real carry-in
carry_lookahead_adder_16b carry_lookahead_adder_16b_inst(
    .iA(iA[15:0]),
    .iB(iB[15:0]),
    .iCarry(iCarry),
    .oSum(oSum[15:0]),
    .oCarry(wCon[1])
    );

generate
    for(i=1;i<4;i=i+1)
    begin

        // block computed assuming carry-in = 0
        carry_lookahead_adder_16b carry_lookahead_adder_16b_inst_0(
        .iA(iA[(i*16+15):i*16]),
        .iB(iB[(i*16+15):i*16]),
        .iCarry(1'b0),
        .oSum(wSum_0[(i*16+15):i*16]),
        .oCarry(wCarry_0[i])
        );

        // block computed assuming carry-in = 1
        carry_lookahead_adder_16b carry_lookahead_adder_16b_inst_1(
        .iA(iA[(i*16+15):i*16]),
        .iB(iB[(i*16+15):i*16]),
        .iCarry(1'b1),
        .oSum(wSum_1[(i*16+15):i*16]),
        .oCarry(wCarry_1[i])
        );

        // select the correct sum once the real carry-in is known
        mux_16b mux_16b_inst(
        .iA(wSum_0[(i*16+15):i*16]),
        .iB(wSum_1[(i*16+15):i*16]),
        .iSel(wCon[i]),
        .out(oSum[(i*16+15):i*16])
        );

        // select the carry passed to the next block
        mux_1b mux_1b_inst(
        .iA(wCarry_0[i]),
        .iB(wCarry_1[i]),
        .iSel(wCon[i]),
        .out(wCon[i+1])
        );

    end
endgenerate

assign oCarry=wCon[4];

endmodule
