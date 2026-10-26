`timescale 1ns / 1ps
//==============================================================================
// Module      : mux_8b
// Project     : 512-bit multi-precision adder/subtractor on FPGA (PYNQ-Z2, Zynq-7020)
// Description : 8-bit 2:1 multiplexer (sum select).
//==============================================================================

module mux_8b(
    input wire [7:0]iA,iB,
    input wire iSel,
    output wire [7:0]out
);

assign out=(iSel==0)?iA:iB;
endmodule
