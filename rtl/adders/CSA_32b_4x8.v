`timescale 1ns / 1ps
//==============================================================================
// Module      : CSA_32b_4x8
// Project     : 512-bit multi-precision adder/subtractor on FPGA (PYNQ-Z2, Zynq-7020)
// Description : 32-bit carry-select adder built from four 8-bit flat CLA blocks.
//               Middle layer of the final hybrid adder.
//==============================================================================

module CSA_32b_4x8#(
    parameter CLA_WIDTH = 8
)
(
    input   wire [31:0]  iA, iB,
    input   wire                    iCarry,
    output  wire [31:0]  oSum,
    output  wire                    oCarry,
    output wire oXORResult
);

wire [31:8] wSum_0, wSum_1;
wire [3:1] wCarry_0, wCarry_1;
wire [4:1] wCon;
wire [31:0]rResult;
genvar i;

// least-significant block: uses the real carry-in
CLA_8b CLA_8b_inst_init(
    .iA(iA[7:0]),
    .iB(iB[7:0]),
    .iCarry(iCarry),
    .oSum(rResult[7:0]),
    .oCarry(wCon[1])
    );

generate
    for(i=1;i<4;i=i+1)
    begin

        // block computed assuming carry-in = 0
        CLA_8b CLA_8b_inst0(
        .iA(iA[(i*8+7):i*8]),
        .iB(iB[(i*8+7):i*8]),
        .iCarry(1'b0),
        .oSum(wSum_0[(i*8+7):i*8]),
        .oCarry(wCarry_0[i])
        );

        // block computed assuming carry-in = 1
        CLA_8b CLA_8b_inst1(
        .iA(iA[(i*8+7):i*8]),
        .iB(iB[(i*8+7):i*8]),
        .iCarry(1'b1),
        .oSum(wSum_1[(i*8+7):i*8]),
        .oCarry(wCarry_1[i])
        );

        // select the correct sum once the real carry-in is known
        mux_8b mux_8b_inst(
        .iA(wSum_0[(i*8+7):i*8]),
        .iB(wSum_1[(i*8+7):i*8]),
        .iSel(wCon[i]),
        .out(rResult[(i*8+7):i*8])
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
assign oXORResult=^rResult;
assign oSum=rResult;

endmodule
