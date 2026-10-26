`timescale 1ns / 1ps
//==============================================================================
// Module      : carry_lookahead_adder_32b
// Project     : 512-bit multi-precision adder/subtractor on FPGA (PYNQ-Z2, Zynq-7020)
// Description : 32-bit carry-lookahead adder built from two 16-bit two-level CLA blocks
//               ("iterative" CLA, evaluated as a building block).
//==============================================================================

module carry_lookahead_adder_32b#(
    parameter   ADDER_WIDTH = 32
    )
    (
    input   wire [ADDER_WIDTH-1:0]  iA, iB,
    input   wire                    iCarry,
    output  wire [ADDER_WIDTH-1:0]  oSum,
    output  wire                    oCarry
);

wire [4:0] C;
wire [3:0] P;
wire [3:0] G;
genvar i;

generate
    for (i=0;i<2;i=i+1)
        begin
            carry_lookahead_adder_16b carry_lookahead_adder_16b_inst(.iA(iA[(i*16+15):i*16]),.iB(iB[(i*16+15):i*16]),.iCarry(C[i]),.oSum(oSum[(i*16+15):i*16]),.oG16(G[i]),.oP16(P[i]));
        end
endgenerate

assign C[0] = iCarry;
(* keep="true" *)
assign C[1] = G[0] | (P[0] & iCarry);
(* keep="true" *)
assign C[2] = G[1] | (P[1] & G[0]) | (P[1] & P[0] & iCarry);

assign oCarry = C[2];

endmodule
