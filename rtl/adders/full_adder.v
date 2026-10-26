`timescale 1ns / 1ps
//==============================================================================
// Module      : full_adder
// Project     : 512-bit multi-precision adder/subtractor on FPGA (PYNQ-Z2, Zynq-7020)
// Description : 1-bit full adder.
//==============================================================================

module full_adder (
    input   wire    iA, iB, iCarry,
    output  wire    oSum, oCarry
);

assign oSum = (iA^iB)^iCarry;
assign oCarry = iA&iB | (iA^iB)&iCarry;

endmodule

