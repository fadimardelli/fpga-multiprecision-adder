`timescale 1ns / 1ps
//==============================================================================
// Module      : CLA_8b
// Project     : 512-bit multi-precision adder/subtractor on FPGA (PYNQ-Z2, Zynq-7020)
// Description : 8-bit carry-lookahead adder with flat (non-iterative) carry equations:
//               every carry is computed directly from P/G and the carry-in.
//               Leaf block of the final hybrid adder.
//==============================================================================

module CLA_8b#(
    parameter   ADDER_WIDTH = 8
    )
    (
    input   wire [ADDER_WIDTH-1:0]  iA, iB,
    input   wire                    iCarry,
    output  wire [ADDER_WIDTH-1:0]  oSum,
    output  wire                    oCarry,
    output wire oXORResult
);

wire [8:0] C;
wire [7:0] P;
wire [7:0] G;
wire [7:0] rResult;
genvar i;

generate
    for (i=0;i<8;i=i+1)
        begin
            partial_full_adder partial_full_adder_inst(.iA(iA[i]),.iB(iB[i]),.iCarry(C[i]),.oSum(rResult[i]),.oG(G[i]),.oP(P[i]));
        end
endgenerate

assign C[0] = iCarry;
assign C[1] = G[0] | (P[0] & iCarry);
assign C[2] = G[1] | (P[1] & G[0]) | (P[1] & P[0] & iCarry);
assign C[3] = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) | (P[2] & P[1] & P[0] & iCarry);
assign C[4] = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0]) | (P[3] & P[2] & P[1] & P[0] & iCarry);
assign C[5]  = G[4] | (P[4] & G[3]) | (P[4] & P[3] & G[2]) | (P[4] & P[3] & P[2] & G[1]) | (P[4] & P[3] & P[2] & P[1] & G[0]) | (P[4] & P[3] & P[2] & P[1] & P[0] & iCarry);
assign C[6]  = G[5] | (P[5] & G[4]) | (P[5] & P[4] & G[3]) | (P[5] & P[4] & P[3] & G[2]) | (P[5] & P[4] & P[3] & P[2] & G[1]) | (P[5] & P[4] & P[3] & P[2] & P[1] & G[0]) | (P[5] & P[4] & P[3] & P[2] & P[1] & P[0] & iCarry);
assign C[7]  = G[6] | (P[6] & G[5]) | (P[6] & P[5] & G[4]) | (P[6] & P[5] & P[4] & G[3]) | (P[6] & P[5] & P[4] & P[3] & G[2]) | (P[6] & P[5] & P[4] & P[3] & P[2] & G[1]) | (P[6] & P[5] & P[4] & P[3] & P[2] & P[1] & G[0]) | (P[6] & P[5] & P[4] & P[3] & P[2] & P[1] & P[0] & iCarry);
assign C[8]  = G[7] | (P[7] & G[6]) | (P[7] & P[6] & G[5]) | (P[7] & P[6] & P[5] & G[4]) | (P[7] & P[6] & P[5] & P[4] & G[3]) | (P[7] & P[6] & P[5] & P[4] & P[3] & G[2]) | (P[7] & P[6] & P[5] & P[4] & P[3] & P[2] & G[1]) | (P[7] & P[6] & P[5] & P[4] & P[3] & P[2] & P[1] & G[0]) | (P[7] & P[6] & P[5] & P[4] & P[3] & P[2] & P[1] & P[0] & iCarry);

assign oCarry=C[8];
assign oXORResult=^rResult;
assign oSum=rResult;
endmodule
