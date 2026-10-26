`timescale 1ns / 1ps
//==============================================================================
// Module      : mux_1b
// Project     : 512-bit multi-precision adder/subtractor on FPGA (PYNQ-Z2, Zynq-7020)
// Description : 1-bit 2:1 multiplexer (carry select).
//==============================================================================

module mux_1b(
    input wire iA, iB,
    input wire iSel,
    output wire out
);

assign out=(iSel==0)?iA:iB;

endmodule
