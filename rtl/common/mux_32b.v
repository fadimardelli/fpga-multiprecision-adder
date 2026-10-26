`timescale 1ns / 1ps
//==============================================================================
// Module      : mux_32b
// Project     : 512-bit multi-precision adder/subtractor on FPGA (PYNQ-Z2, Zynq-7020)
// Description : 32-bit 2:1 multiplexer (sum select).
//==============================================================================

module mux_32b(
    input wire [31:0]iA,iB,
    input wire iSel,
    output wire [31:0]out
);

assign out=(iSel==0)?iA:iB;
endmodule
