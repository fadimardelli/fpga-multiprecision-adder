`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// tb_mp_adder.v
// Self-checking testbench for the 512-bit multi-precision adder/subtractor.
// Applies random and corner-case operands in both modes and compares the
// result with a behavioural reference model.
//------------------------------------------------------------------------------
module tb_mp_adder;

  localparam OPERAND_WIDTH = 512;
  localparam ADDER_WIDTH   = 128;
  localparam N_TESTS       = 200;   // per mode
  localparam T             = 8;     // 125 MHz

  reg                      rClk = 1'b0;
  reg                      rRst, rStart, rAddSub;
  reg  [OPERAND_WIDTH-1:0] rA, rB;
  wire [OPERAND_WIDTH:0]   wRes;
  wire                     wDone;

  mp_adder #(.OPERAND_WIDTH(OPERAND_WIDTH), .ADDER_WIDTH(ADDER_WIDTH)) dut (
    .iClk(rClk), .iRst(rRst), .iStart(rStart),
    .iOpA(rA), .iOpB(rB), .iAdd_sub(rAddSub),
    .oRes(wRes), .oDone(wDone));

  always #(T/2) rClk = ~rClk;

  integer i, mode, errors = 0, cycles;
  reg [OPERAND_WIDTH:0] expected;

  function [OPERAND_WIDTH-1:0] rand512;
    input dummy;
    integer j;
    begin
      for (j = 0; j < OPERAND_WIDTH/32; j = j + 1)
        rand512[j*32 +: 32] = $urandom;
    end
  endfunction

  task run_op(input [OPERAND_WIDTH-1:0] a, input [OPERAND_WIDTH-1:0] b, input sub);
    begin
      @(negedge rClk);
      rA = a; rB = b; rAddSub = sub; rStart = 1'b1;
      @(negedge rClk);
      rStart = 1'b0;
      cycles = 1;
      while (!wDone) begin @(negedge rClk); cycles = cycles + 1; end
      expected = sub ? {1'b0, a - b} : {1'b0, a} + {1'b0, b};
      if (wRes !== expected) begin
        errors = errors + 1;
        if (errors <= 3)
          $display("FAIL (%s)\n  A   = %h\n  B   = %h\n  got = %h\n  exp = %h",
                   sub ? "sub" : "add", a, b, wRes, expected);
      end
    end
  endtask

  initial begin
    rRst = 1'b1; rStart = 1'b0; rAddSub = 1'b0; rA = 0; rB = 0;
    repeat (5) @(negedge rClk);
    rRst = 1'b0;

    for (mode = 0; mode < 2; mode = mode + 1) begin
      // corner cases: zero, all ones, carry propagating through every word
      run_op({OPERAND_WIDTH{1'b0}}, {OPERAND_WIDTH{1'b0}}, mode);
      run_op({OPERAND_WIDTH{1'b1}}, {OPERAND_WIDTH{1'b1}}, mode);
      run_op({OPERAND_WIDTH{1'b1}}, {{OPERAND_WIDTH-1{1'b0}}, 1'b1}, mode);
      run_op({{OPERAND_WIDTH-1{1'b0}}, 1'b1}, {OPERAND_WIDTH{1'b1}}, mode);
      for (i = 0; i < N_TESTS; i = i + 1)
        run_op(rand512(0), rand512(0), mode);
    end

    $display("mp_adder: %0d operations, latency %0d cycles, %0d errors -> %s",
             2 * (N_TESTS + 4), cycles, errors, errors == 0 ? "PASS" : "FAIL");
    $finish;
  end

endmodule
