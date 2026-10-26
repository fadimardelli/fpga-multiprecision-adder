`timescale 1ns / 1ps
//==============================================================================
// Module      : CSA_64b_2x32
// Project     : 512-bit multi-precision adder/subtractor on FPGA (PYNQ-Z2, Zynq-7020)
// Description : 64-bit carry-select adder built from two 32-bit carry-select blocks
//               (CSA_32b_4x8).
//==============================================================================

module CSA_64b_2x32#(
    parameter M = 32
)
(
    input   wire [63:0]  iA, iB,
    input   wire                    iCarry,
    output  wire [63:0]  oSum,
    output  wire                    oCarry
);

wire [63:32] wSum_0, wSum_1;
wire [3:1] wCarry_0, wCarry_1;
wire [4:1] wCon;
genvar i;

// least-significant block: uses the real carry-in
CSA_32b_4x8 CSA_32b_4x8_inst_init(
    .iA(iA[31:0]),
    .iB(iB[31:0]),
    .iCarry(iCarry),
    .oSum(oSum[31:0]),
    .oCarry(wCon[1])
    );

generate
    for(i=1;i<2;i=i+1)
    begin

        // block computed assuming carry-in = 0
        CSA_32b_4x8 CSA_32b_4x8_inst0(
        .iA(iA[(i*32+31):i*32]),
        .iB(iB[(i*32+31):i*32]),
        .iCarry(1'b0),
        .oSum(wSum_0[(i*32+31):i*32]),
        .oCarry(wCarry_0[i])
        );

        // block computed assuming carry-in = 1
        CSA_32b_4x8 CSA_32b_4x8_inst1(
        .iA(iA[(i*32+31):i*32]),
        .iB(iB[(i*32+31):i*32]),
        .iCarry(1'b1),
        .oSum(wSum_1[(i*32+31):i*32]),
        .oCarry(wCarry_1[i])
        );

        // select the correct sum once the real carry-in is known
        mux_32b mux_32b_inst(
        .iA(wSum_0[(i*32+31):i*32]),
        .iB(wSum_1[(i*32+31):i*32]),
        .iSel(wCon[i]),
        .out(oSum[(i*32+31):i*32])
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

assign oCarry=wCon[2];

endmodule
