`timescale 1ns / 1ps
//==============================================================================
// Module      : mux_16b
// Project     : 512-bit multi-precision adder/subtractor on FPGA (PYNQ-Z2, Zynq-7020)
// Description : 16-bit 2:1 multiplexer (sum select).
//==============================================================================

module mux_16b(
    input wire [15:0]iA,iB,
    input wire iSel,
    output wire [15:0]out
);

assign out=(iSel==0)?iA:iB;
endmodule
