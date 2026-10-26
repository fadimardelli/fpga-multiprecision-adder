`timescale 1ns / 1ps
//==============================================================================
// Module      : carry_lookahead_adder_4b
// Project     : 512-bit multi-precision adder/subtractor on FPGA (PYNQ-Z2, Zynq-7020)
// Description : 4-bit carry-lookahead adder with fully expanded carry equations.
//               Also exports group generate/propagate for a second lookahead level.
//==============================================================================

module carry_lookahead_adder_4b #(
    parameter   ADDER_WIDTH = 4
    )
    (
    input   wire [ADDER_WIDTH-1:0]  iA, iB,
    input   wire                    iCarry,
    output  wire [ADDER_WIDTH-1:0]  oSum,
    output  wire                    oCarry,
    output wire oG4,
    output wire oP4
);

wire [ADDER_WIDTH:0] C;
wire [ADDER_WIDTH-1:0] P;
wire [ADDER_WIDTH-1:0] G;
genvar i;

generate
    for (i=0;i<ADDER_WIDTH;i=i+1)
        begin
            partial_full_adder partial_full_adder_inst(.iA(iA[i]),.iB(iB[i]),.iCarry(C[i]),.oSum(oSum[i]),.oP(P[i]),.oG(G[i]));
        end
endgenerate

assign C[0] = iCarry;
(* keep="true" *)
assign C[1] = G[0] | (P[0] & iCarry);
(* keep="true" *)
assign C[2] = G[1] | (P[1] & G[0]) | (P[1] & P[0] & iCarry);
(* keep="true" *)
assign C[3] = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) | (P[2] & P[1] & P[0] & iCarry);
(* keep="true" *)
assign C[4] = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0]) | (P[3] & P[2] & P[1] & P[0] & iCarry);

assign oCarry = C[4];
(* keep="true" *)
assign oG4 = G[3] | (P[3]&G[2]) | (P[3]&P[2]&G[1]) | (P[3]&P[2]&P[1]&G[0]);
(* keep="true" *)
assign oP4 = P[3]&P[2]&P[1]&P[0]&iCarry;

endmodule
