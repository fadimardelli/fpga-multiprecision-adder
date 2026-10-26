`timescale 1ns / 1ps
//==============================================================================
// Module      : ripple_carry_adder_Nb
// Project     : 512-bit multi-precision adder/subtractor on FPGA (PYNQ-Z2, Zynq-7020)
// Description : Parameterisable N-bit adder that ripples the carry between 4-bit
//               carry-lookahead blocks (baseline from the earlier labs).
//==============================================================================

module ripple_carry_adder_Nb #(
    parameter   ADDER_WIDTH = 32,
    parameter   CLA_WIDTH = 4,
    parameter   CLA_BLOCKS = ADDER_WIDTH/CLA_WIDTH
    )
    (
    input   wire [ADDER_WIDTH-1:0]  iA, iB,
    input   wire                    iCarry,
    output  wire [ADDER_WIDTH-1:0]  oSum,
    output  wire                    oCarry
);

wire [CLA_BLOCKS-1:0] temp_iCarry;
wire [CLA_BLOCKS-1:0] temp_oCarry;
genvar i;

assign temp_iCarry[0]=iCarry;

generate
    for (i=0;i<CLA_BLOCKS;i=i+1)
        begin
            carry_lookahead_adder_4b carry_lookahead_adder_4b(.iA(iA[(i*(CLA_WIDTH)+(CLA_WIDTH-1)):(i*CLA_WIDTH)]),.iB(iB[(i*(CLA_WIDTH)+(CLA_WIDTH-1)):(i*CLA_WIDTH)]),.iCarry(temp_iCarry[i]),.oSum(oSum[(i*(CLA_WIDTH)+(CLA_WIDTH-1)):(i*CLA_WIDTH)]),.oCarry(temp_oCarry[i]));
        end
    for(i=0;i<CLA_BLOCKS-1;i=i+1)
        begin
            assign temp_iCarry[i+1]=temp_oCarry[i];
        end
endgenerate

assign oCarry=temp_oCarry[CLA_BLOCKS-1];

endmodule

