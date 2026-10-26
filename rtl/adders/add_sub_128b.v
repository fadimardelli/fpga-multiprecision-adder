`timescale 1ns / 1ps
//==============================================================================
// Module      : add_sub_128b
// Project     : 512-bit multi-precision adder/subtractor on FPGA (PYNQ-Z2, Zynq-7020)
// Description : 128-bit adder/subtractor. Operand B is inverted when iAdd_sub = 1;
//               together with carry-in = 1 (set by mp_adder) this gives A - B in
//               two's complement. Uses the hybrid adder CSA_128b_4x32.
//==============================================================================

module add_sub_128b(
    input   wire [127:0]  iA, iB,
    input   wire                    iCarry,
    input wire iAdd_sub,
    output  wire [127:0]  oSum,
    output  wire                    oCarry
    );
wire [127:0]wB;
wire wC;

as_mux_128b as_mux_128b_inst(
    .iA(iB),
    .iSel(iAdd_sub),
    .out(wB)
);

CSA_128b_4x32 CSA_128b_4x32_inst(
    .iA(iA),
    .iB(wB),
    .iCarry(iCarry),
    .oSum(oSum),
    .oCarry(oCarry)
);

endmodule

module as_mux_128b(
    input wire [127:0]iA,
    input wire iSel,
    output wire [127:0] out
);
reg [127:0]rA;
always@(*)
begin
    rA=~iA;
end
assign out=(iSel==0)?iA:rA;
endmodule
