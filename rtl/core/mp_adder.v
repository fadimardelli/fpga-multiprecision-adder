`timescale 1ns / 1ps
//==============================================================================
// Module      : mp_adder
// Project     : 512-bit multi-precision adder/subtractor on FPGA (PYNQ-Z2, Zynq-7020)
// Description : Multi-precision adder/subtractor. Adds or subtracts two OPERAND_WIDTH-bit
//               operands by iterating an ADDER_WIDTH-bit combinational adder over the
//               words of the operands, least-significant word first, with the
//               carry kept in a register between iterations.
//               512-bit operands, 128-bit adder: 1 + 512/128 + 1 = 6 clock cycles.
//==============================================================================

module mp_adder #(
      // to avoid extra complexity, it is best that OPERAND_WIDTH is a multiple of ADDER_WIDTH
      //   that way the number of iterations for the addition is an integer number
      // if the operands you want to add have an OPERAND_WIDTH non-multiple of ADDER_WIDTH
      //   you'll have to extend them by padding them with zeroes
      parameter OPERAND_WIDTH = 512,
      parameter ADDER_WIDTH   = 128,
      parameter CLA_WIDTH =4,
      parameter N_ITERATIONS  = OPERAND_WIDTH / ADDER_WIDTH
    )
    (
    input  wire                       iClk,
    input  wire                       iRst,
    input  wire                       iStart,
    input  wire [OPERAND_WIDTH-1:0]   iOpA,
    input  wire [OPERAND_WIDTH-1:0]   iOpB,
    input wire iAdd_sub,
    output wire [OPERAND_WIDTH:0]     oRes,
    output wire                       oDone);

    // operation select (0 = add, 1 = subtract), latched on iStart
    wire wAdd_sub;
    reg rAdd_sub;

    always@(posedge iClk)
    begin
      if(iRst==1)rAdd_sub=0;
      else if(iStart==1)rAdd_sub=iAdd_sub;
      else rAdd_sub=rAdd_sub;
    end
    assign wAdd_sub=rAdd_sub;

    // OPERAND_WIDTH-bit register for A
    wire [OPERAND_WIDTH-1:0] regA_D;
    reg  [OPERAND_WIDTH-1:0] regA_Q;

    always @(posedge iClk)
    begin
        if(iRst==1)     regA_Q <= { OPERAND_WIDTH{1'b0} };
        else            regA_Q <= regA_D;
    end

    // OPERAND_WIDTH-bit register for B
    wire [OPERAND_WIDTH-1:0] regB_D;
    reg  [OPERAND_WIDTH-1:0] regB_Q;

    always @(posedge iClk)
    begin
      if(iRst==1)       regB_Q <= {OPERAND_WIDTH{1'b0}};
      else              regB_Q <= regB_D;
    end

    // 2-input Multiplexer for register A
    // Selects one of:
    //   - the input iOpA
    //   - the output of register A shifted-right
    reg          muxA_sel;
    wire [OPERAND_WIDTH-1:0] muxA_Out;

    assign muxA_Out = (muxA_sel == 0) ? iOpA : { {ADDER_WIDTH{1'b0}}  , regA_Q[OPERAND_WIDTH-1:ADDER_WIDTH]};

    // connect the output of the multiplexer to the input of register A
    assign regA_D = muxA_Out;

    // 2-input Multiplexer for register B
    // Selects one of:
    //   - the input iOpB
    //   - the output of register B shifted-right
    reg          muxB_sel;
    wire  [OPERAND_WIDTH-1:0] muxB_Out;

    assign muxB_Out = (muxB_sel == 0) ? iOpB : { {ADDER_WIDTH{1'b0}}  , regB_Q[OPERAND_WIDTH-1:ADDER_WIDTH]};

    // connect the output of the multiplexer to the input of register B
    assign regB_D = muxB_Out;

    // Combinational adder: two ADDER_WIDTH-bit operands and a 1-bit carry-in,
    // one ADDER_WIDTH-bit result and a 1-bit carry-out
    wire [ADDER_WIDTH-1:0]  operandA;
    wire [ADDER_WIDTH-1:0]  operandB;
    wire                    carry_in;
    wire [ADDER_WIDTH-1:0]  result;
    wire                    carry_out;

    // Final choice: 128-bit hybrid adder/subtractor (8-bit CLA -> 32-bit carry-select
    // -> 128-bit carry-select). The other architectures evaluated during the design
    // exploration (ripple, CLA, carry-select variants) are kept in rtl/adders/.
    add_sub_128b add_sub_128b_inst(
      .iA( operandA ),
      .iB( operandB ),
      .iCarry( carry_in ),
      .iAdd_sub(wAdd_sub),
      .oSum(result),
      .oCarry(carry_out)
    );

    // OPERAND_WIDTH-bit register for storing the result
    // This shift register places the adder output at the MSB ADDER_WIDTH-bits,
    // and shifts the remaining OPERAND_WIDTH-ADDER_WIDTH bits to the right
    reg  [OPERAND_WIDTH-1:0] regResult;

    always @(posedge iClk)
    begin
        if(iRst==1)   regResult <= { OPERAND_WIDTH{1'b0} };
      else            regResult <= { result, regResult[OPERAND_WIDTH-1:ADDER_WIDTH] };
    end

    // 1-bit register for storing the carry-out
    reg  regCout;

    always @(posedge iClk)
    begin
      if(iRst==1)   regCout <= 1'b0;
      else          regCout <= carry_out;
    end

    // 1-bit multiplexer for selecting carry-in
    // Selects one of:
    //   - 0
    //   - carry-out
    reg  muxCarry_sel;
    wire muxCarryIn;

    assign muxCarryIn = (muxCarry_sel == 0) ? ((wAdd_sub==1)?1'b1:1'b0) : regCout;

    // Connect the inputs of adder to the outputs of A and B registers
    // and to the carry mux
    assign operandA = regA_Q;
    assign operandB = regB_Q;
    assign carry_in = muxCarryIn;

    // Describe the output signal oRes: it is the concatenation of output registers
    assign oRes = (wAdd_sub==1)?{ 1'b0, regResult}:{ regCout, regResult};

    // FINITE STATE MACHINE

    // State definition
    localparam s_IDLE         = 3'b000;
    localparam s_STORE_OPS    = 3'b001;
    localparam s_ADD_FIRST    = 3'b010;
    localparam s_ADD_WORDS    = 3'b011;
    localparam s_DONE         = 3'b100;

    reg [2:0] rFSM_current, wFSM_next;

    always @(posedge iClk)
    begin
        if(iRst==1)
            rFSM_current <= s_IDLE;
        else
            rFSM_current <= wFSM_next;
    end

   // Iteration counter
    reg [$clog2(N_ITERATIONS):0] rCnt_Current, wCnt_next;

    always @(posedge iClk)
    begin
        if(iRst==1)
            rCnt_Current <= 0;
        else
            rCnt_Current <= wCnt_next;
    end

    // Describe next_state logic

    always @(*)
    begin
        case(rFSM_current)

            s_IDLE:
              begin
                muxA_sel = 0;
                muxB_sel = 0;
                muxCarry_sel = 0;
                wCnt_next = 0;

                if (iStart==1)
                    wFSM_next = s_STORE_OPS;
                else
                    wFSM_next = s_IDLE;
              end

            s_STORE_OPS:
              begin
                muxA_sel = 0;
                muxB_sel = 0;
                muxCarry_sel = 0;
                wCnt_next = rCnt_Current + 1;

                wFSM_next = s_ADD_FIRST;
              end

            s_ADD_FIRST:
              begin
                muxA_sel = 1;
                muxB_sel = 1;
                muxCarry_sel = 0;
                wCnt_next = rCnt_Current + 1;

                wFSM_next = s_ADD_WORDS;
              end

            s_ADD_WORDS:
              begin
                muxA_sel = 1;
                muxB_sel = 1;
                muxCarry_sel = 1;
                wCnt_next = rCnt_Current + 1;

                if ( rCnt_Current < (N_ITERATIONS - 1) )
                  wFSM_next = s_ADD_WORDS;
                else
                  wFSM_next = s_DONE;
              end

            s_DONE:
              begin
                muxA_sel = 1;
                muxB_sel = 1;
                muxCarry_sel = 1;
                wCnt_next = 0;

                wFSM_next = s_IDLE;
              end

            default:
              begin
                muxA_sel = 0;
                muxB_sel = 0;
                muxCarry_sel = 0;
                wCnt_next = 0;

                wFSM_next = s_IDLE;
              end

        endcase
    end

    // Describe done signal
    // High during the clock cycle in which the result is valid

    reg regDone;
    always @(posedge iClk)
    begin
      if(iRst)    regDone <= 1'd0;
      else        regDone <= ( rFSM_current == s_DONE ) ? 1'b1 : 1'b0;
    end

    assign oDone = regDone;

endmodule
