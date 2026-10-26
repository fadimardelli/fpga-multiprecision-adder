`timescale 1ns / 1ps
//==============================================================================
// Module      : carry_lookahead_adder_16b
// Project     : 512-bit multi-precision adder/subtractor on FPGA (PYNQ-Z2, Zynq-7020)
// Description : 16-bit two-level carry-lookahead adder: four 4-bit CLA blocks plus a
//               lookahead unit computing the block carries from group G/P.
//==============================================================================

module carry_lookahead_adder_16b#(
    parameter   ADDER_WIDTH = 16
    )
    (
    input   wire [ADDER_WIDTH-1:0]  iA, iB,
    input   wire                    iCarry,
    output  wire [ADDER_WIDTH-1:0]  oSum,
    output  wire                    oCarry,
    output wire oG16,
    output wire oP16
);

wire [4:0] C;
wire [3:0] P;
wire [3:0] G;
genvar i;

generate
    for (i=0;i<4;i=i+1)
        begin
            carry_lookahead_adder_4b carry_lookahead_adder_4b_inst(.iA(iA[(i*4+3):i*4]),.iB(iB[(i*4+3):i*4]),.iCarry(C[i]),.oSum(oSum[(i*4+3):i*4]),.oG4(G[i]),.oP4(P[i]));
        end
endgenerate

assign C[0] = iCarry;
assign C[1] = G[0] | (P[0] & iCarry);
assign C[2] = G[1] | (P[1] & G[0]) | (P[1] & P[0] & iCarry);
assign C[3] = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) | (P[2] & P[1] & P[0] & iCarry);
assign C[4] = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0]) | (P[3] & P[2] & P[1] & P[0] & iCarry);

assign oCarry = C[4];
assign oG16 = G[3] | (P[3]&G[2]) | (P[3]&P[2]&G[1]) | (P[3]&P[2]&P[1]&G[0]);
assign oP16 = P[3]&P[2]&P[1]&P[0]&C[0];

endmodule
