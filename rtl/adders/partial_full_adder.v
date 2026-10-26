`timescale 1ns / 1ps
//==============================================================================
// Module      : partial_full_adder
// Project     : 512-bit multi-precision adder/subtractor on FPGA (PYNQ-Z2, Zynq-7020)
// Description : 1-bit partial full adder: produces the sum bit plus the propagate (P)
//               and generate (G) signals consumed by carry-lookahead logic.
//==============================================================================

module partial_full_adder (
    input   wire    iA, iB, iCarry,
    output  wire    oSum, oP, oG
);

assign oSum = (iA^iB)^iCarry;
assign oP = iA | iB;
assign oG = iA & iB;

endmodule
