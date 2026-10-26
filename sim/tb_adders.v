`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// tb_adders.v
// Self-checking testbench for every combinational adder architecture in
// rtl/adders/. Each design gets corner cases (all zeros, all ones, carry
// propagating through every bit) plus random operands and a random carry-in,
// and {oCarry, oSum} is compared with A + B + Cin.
//------------------------------------------------------------------------------
module tb_adders;

  localparam N_VECTORS = 2000;

  integer total_errors = 0;

  // fills a vector of up to 256 bits with random data
  `define RAND256 {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom}

  // ---------------------------------------------------------------- ripple_carry_adder_Nb
  if (1) begin : g_ripple_carry_adder_Nb
    reg  [31:0] a, b;
    reg         ci;
    wire [31:0] s;
    wire        co;
    reg  [32:0] expected;
    integer     k, errors;

    ripple_carry_adder_Nb #(.ADDER_WIDTH(32)) dut (.iA(a), .iB(b), .iCarry(ci), .oSum(s), .oCarry(co));

    initial begin
      errors = 0;
      for (k = 0; k < N_VECTORS; k = k + 1) begin
        a = `RAND256; b = `RAND256; ci = $urandom;
        if (k < 4)  begin a = k[0] ? {32{1'b1}} : 0; b = k[1] ? {32{1'b1}} : 0; ci = k[0]; end
        if (k == 4) begin a = {32{1'b1}}; b = 1; ci = 0; end   // carry through every bit
        #1;
        expected = a + b + ci;
        if ({co, s} !== expected) begin
          errors = errors + 1;
          if (errors == 1)
            $display("  ripple_carry_adder_Nb: a=%h b=%h cin=%b got=%h expected=%h", a, b, ci, {co, s}, expected);
        end
      end
      $display("%-28s %3d-bit  %s", "ripple_carry_adder_Nb", 32, errors == 0 ? "PASS" : "FAIL");
      total_errors = total_errors + errors;
    end
  end

  // ---------------------------------------------------------------- carry_lookahead_adder_4b
  if (1) begin : g_carry_lookahead_adder_4b
    reg  [3:0] a, b;
    reg         ci;
    wire [3:0] s;
    wire        co;
    reg  [4:0] expected;
    integer     k, errors;

    carry_lookahead_adder_4b dut (.iA(a), .iB(b), .iCarry(ci), .oSum(s), .oCarry(co), .oG4(), .oP4());

    initial begin
      errors = 0;
      for (k = 0; k < N_VECTORS; k = k + 1) begin
        a = `RAND256; b = `RAND256; ci = $urandom;
        if (k < 4)  begin a = k[0] ? {4{1'b1}} : 0; b = k[1] ? {4{1'b1}} : 0; ci = k[0]; end
        if (k == 4) begin a = {4{1'b1}}; b = 1; ci = 0; end   // carry through every bit
        #1;
        expected = a + b + ci;
        if ({co, s} !== expected) begin
          errors = errors + 1;
          if (errors == 1)
            $display("  carry_lookahead_adder_4b: a=%h b=%h cin=%b got=%h expected=%h", a, b, ci, {co, s}, expected);
        end
      end
      $display("%-28s %3d-bit  %s", "carry_lookahead_adder_4b", 4, errors == 0 ? "PASS" : "FAIL");
      total_errors = total_errors + errors;
    end
  end

  // ---------------------------------------------------------------- CLA_8b
  if (1) begin : g_CLA_8b
    reg  [7:0] a, b;
    reg         ci;
    wire [7:0] s;
    wire        co;
    reg  [8:0] expected;
    integer     k, errors;

    CLA_8b dut (.iA(a), .iB(b), .iCarry(ci), .oSum(s), .oCarry(co), .oXORResult());

    initial begin
      errors = 0;
      for (k = 0; k < N_VECTORS; k = k + 1) begin
        a = `RAND256; b = `RAND256; ci = $urandom;
        if (k < 4)  begin a = k[0] ? {8{1'b1}} : 0; b = k[1] ? {8{1'b1}} : 0; ci = k[0]; end
        if (k == 4) begin a = {8{1'b1}}; b = 1; ci = 0; end   // carry through every bit
        #1;
        expected = a + b + ci;
        if ({co, s} !== expected) begin
          errors = errors + 1;
          if (errors == 1)
            $display("  CLA_8b: a=%h b=%h cin=%b got=%h expected=%h", a, b, ci, {co, s}, expected);
        end
      end
      $display("%-28s %3d-bit  %s", "CLA_8b", 8, errors == 0 ? "PASS" : "FAIL");
      total_errors = total_errors + errors;
    end
  end

  // ---------------------------------------------------------------- carry_lookahead_adder_16b
  if (1) begin : g_carry_lookahead_adder_16b
    reg  [15:0] a, b;
    reg         ci;
    wire [15:0] s;
    wire        co;
    reg  [16:0] expected;
    integer     k, errors;

    carry_lookahead_adder_16b dut (.iA(a), .iB(b), .iCarry(ci), .oSum(s), .oCarry(co), .oG16(), .oP16());

    initial begin
      errors = 0;
      for (k = 0; k < N_VECTORS; k = k + 1) begin
        a = `RAND256; b = `RAND256; ci = $urandom;
        if (k < 4)  begin a = k[0] ? {16{1'b1}} : 0; b = k[1] ? {16{1'b1}} : 0; ci = k[0]; end
        if (k == 4) begin a = {16{1'b1}}; b = 1; ci = 0; end   // carry through every bit
        #1;
        expected = a + b + ci;
        if ({co, s} !== expected) begin
          errors = errors + 1;
          if (errors == 1)
            $display("  carry_lookahead_adder_16b: a=%h b=%h cin=%b got=%h expected=%h", a, b, ci, {co, s}, expected);
        end
      end
      $display("%-28s %3d-bit  %s", "carry_lookahead_adder_16b", 16, errors == 0 ? "PASS" : "FAIL");
      total_errors = total_errors + errors;
    end
  end

  // ---------------------------------------------------------------- carry_lookahead_adder_32b
  if (1) begin : g_carry_lookahead_adder_32b
    reg  [31:0] a, b;
    reg         ci;
    wire [31:0] s;
    wire        co;
    reg  [32:0] expected;
    integer     k, errors;

    carry_lookahead_adder_32b dut (.iA(a), .iB(b), .iCarry(ci), .oSum(s), .oCarry(co));

    initial begin
      errors = 0;
      for (k = 0; k < N_VECTORS; k = k + 1) begin
        a = `RAND256; b = `RAND256; ci = $urandom;
        if (k < 4)  begin a = k[0] ? {32{1'b1}} : 0; b = k[1] ? {32{1'b1}} : 0; ci = k[0]; end
        if (k == 4) begin a = {32{1'b1}}; b = 1; ci = 0; end   // carry through every bit
        #1;
        expected = a + b + ci;
        if ({co, s} !== expected) begin
          errors = errors + 1;
          if (errors == 1)
            $display("  carry_lookahead_adder_32b: a=%h b=%h cin=%b got=%h expected=%h", a, b, ci, {co, s}, expected);
        end
      end
      $display("%-28s %3d-bit  %s", "carry_lookahead_adder_32b", 32, errors == 0 ? "PASS" : "FAIL");
      total_errors = total_errors + errors;
    end
  end

  // ---------------------------------------------------------------- CSA_32b
  if (1) begin : g_CSA_32b
    reg  [31:0] a, b;
    reg         ci;
    wire [31:0] s;
    wire        co;
    reg  [32:0] expected;
    integer     k, errors;

    CSA_32b dut (.iA(a), .iB(b), .iCarry(ci), .oSum(s), .oCarry(co));

    initial begin
      errors = 0;
      for (k = 0; k < N_VECTORS; k = k + 1) begin
        a = `RAND256; b = `RAND256; ci = $urandom;
        if (k < 4)  begin a = k[0] ? {32{1'b1}} : 0; b = k[1] ? {32{1'b1}} : 0; ci = k[0]; end
        if (k == 4) begin a = {32{1'b1}}; b = 1; ci = 0; end   // carry through every bit
        #1;
        expected = a + b + ci;
        if ({co, s} !== expected) begin
          errors = errors + 1;
          if (errors == 1)
            $display("  CSA_32b: a=%h b=%h cin=%b got=%h expected=%h", a, b, ci, {co, s}, expected);
        end
      end
      $display("%-28s %3d-bit  %s", "CSA_32b", 32, errors == 0 ? "PASS" : "FAIL");
      total_errors = total_errors + errors;
    end
  end

  // ---------------------------------------------------------------- CSA_32b_4x8
  if (1) begin : g_CSA_32b_4x8
    reg  [31:0] a, b;
    reg         ci;
    wire [31:0] s;
    wire        co;
    reg  [32:0] expected;
    integer     k, errors;

    CSA_32b_4x8 dut (.iA(a), .iB(b), .iCarry(ci), .oSum(s), .oCarry(co), .oXORResult());

    initial begin
      errors = 0;
      for (k = 0; k < N_VECTORS; k = k + 1) begin
        a = `RAND256; b = `RAND256; ci = $urandom;
        if (k < 4)  begin a = k[0] ? {32{1'b1}} : 0; b = k[1] ? {32{1'b1}} : 0; ci = k[0]; end
        if (k == 4) begin a = {32{1'b1}}; b = 1; ci = 0; end   // carry through every bit
        #1;
        expected = a + b + ci;
        if ({co, s} !== expected) begin
          errors = errors + 1;
          if (errors == 1)
            $display("  CSA_32b_4x8: a=%h b=%h cin=%b got=%h expected=%h", a, b, ci, {co, s}, expected);
        end
      end
      $display("%-28s %3d-bit  %s", "CSA_32b_4x8", 32, errors == 0 ? "PASS" : "FAIL");
      total_errors = total_errors + errors;
    end
  end

  // ---------------------------------------------------------------- CSA_64b
  if (1) begin : g_CSA_64b
    reg  [63:0] a, b;
    reg         ci;
    wire [63:0] s;
    wire        co;
    reg  [64:0] expected;
    integer     k, errors;

    CSA_64b dut (.iA(a), .iB(b), .iCarry(ci), .oSum(s), .oCarry(co));

    initial begin
      errors = 0;
      for (k = 0; k < N_VECTORS; k = k + 1) begin
        a = `RAND256; b = `RAND256; ci = $urandom;
        if (k < 4)  begin a = k[0] ? {64{1'b1}} : 0; b = k[1] ? {64{1'b1}} : 0; ci = k[0]; end
        if (k == 4) begin a = {64{1'b1}}; b = 1; ci = 0; end   // carry through every bit
        #1;
        expected = a + b + ci;
        if ({co, s} !== expected) begin
          errors = errors + 1;
          if (errors == 1)
            $display("  CSA_64b: a=%h b=%h cin=%b got=%h expected=%h", a, b, ci, {co, s}, expected);
        end
      end
      $display("%-28s %3d-bit  %s", "CSA_64b", 64, errors == 0 ? "PASS" : "FAIL");
      total_errors = total_errors + errors;
    end
  end

  // ---------------------------------------------------------------- CSA_64b_2x32
  if (1) begin : g_CSA_64b_2x32
    reg  [63:0] a, b;
    reg         ci;
    wire [63:0] s;
    wire        co;
    reg  [64:0] expected;
    integer     k, errors;

    CSA_64b_2x32 dut (.iA(a), .iB(b), .iCarry(ci), .oSum(s), .oCarry(co));

    initial begin
      errors = 0;
      for (k = 0; k < N_VECTORS; k = k + 1) begin
        a = `RAND256; b = `RAND256; ci = $urandom;
        if (k < 4)  begin a = k[0] ? {64{1'b1}} : 0; b = k[1] ? {64{1'b1}} : 0; ci = k[0]; end
        if (k == 4) begin a = {64{1'b1}}; b = 1; ci = 0; end   // carry through every bit
        #1;
        expected = a + b + ci;
        if ({co, s} !== expected) begin
          errors = errors + 1;
          if (errors == 1)
            $display("  CSA_64b_2x32: a=%h b=%h cin=%b got=%h expected=%h", a, b, ci, {co, s}, expected);
        end
      end
      $display("%-28s %3d-bit  %s", "CSA_64b_2x32", 64, errors == 0 ? "PASS" : "FAIL");
      total_errors = total_errors + errors;
    end
  end

  // ---------------------------------------------------------------- CSA_128b_4x32
  if (1) begin : g_CSA_128b_4x32
    reg  [127:0] a, b;
    reg         ci;
    wire [127:0] s;
    wire        co;
    reg  [128:0] expected;
    integer     k, errors;

    CSA_128b_4x32 dut (.iA(a), .iB(b), .iCarry(ci), .oSum(s), .oCarry(co), .oXORResult());

    initial begin
      errors = 0;
      for (k = 0; k < N_VECTORS; k = k + 1) begin
        a = `RAND256; b = `RAND256; ci = $urandom;
        if (k < 4)  begin a = k[0] ? {128{1'b1}} : 0; b = k[1] ? {128{1'b1}} : 0; ci = k[0]; end
        if (k == 4) begin a = {128{1'b1}}; b = 1; ci = 0; end   // carry through every bit
        #1;
        expected = a + b + ci;
        if ({co, s} !== expected) begin
          errors = errors + 1;
          if (errors == 1)
            $display("  CSA_128b_4x32: a=%h b=%h cin=%b got=%h expected=%h", a, b, ci, {co, s}, expected);
        end
      end
      $display("%-28s %3d-bit  %s", "CSA_128b_4x32", 128, errors == 0 ? "PASS" : "FAIL");
      total_errors = total_errors + errors;
    end
  end

  // ---------------------------------------------------------------- CSA_128b_4x32IterativeCla
  if (1) begin : g_CSA_128b_4x32IterativeCla
    reg  [127:0] a, b;
    reg         ci;
    wire [127:0] s;
    wire        co;
    reg  [128:0] expected;
    integer     k, errors;

    CSA_128b_4x32IterativeCla dut (.iA(a), .iB(b), .iCarry(ci), .oSum(s), .oCarry(co), .oXORResult());

    initial begin
      errors = 0;
      for (k = 0; k < N_VECTORS; k = k + 1) begin
        a = `RAND256; b = `RAND256; ci = $urandom;
        if (k < 4)  begin a = k[0] ? {128{1'b1}} : 0; b = k[1] ? {128{1'b1}} : 0; ci = k[0]; end
        if (k == 4) begin a = {128{1'b1}}; b = 1; ci = 0; end   // carry through every bit
        #1;
        expected = a + b + ci;
        if ({co, s} !== expected) begin
          errors = errors + 1;
          if (errors == 1)
            $display("  CSA_128b_4x32IterativeCla: a=%h b=%h cin=%b got=%h expected=%h", a, b, ci, {co, s}, expected);
        end
      end
      $display("%-28s %3d-bit  %s", "CSA_128b_4x32IterativeCla", 128, errors == 0 ? "PASS" : "FAIL");
      total_errors = total_errors + errors;
    end
  end

  // ---------------------------------------------------------------- add_sub_128b
  if (1) begin : g_add_sub_128b
    reg  [127:0] a, b;
    reg         ci;
    wire [127:0] s;
    wire        co;
    reg  [128:0] expected;
    integer     k, errors;

    add_sub_128b dut (.iA(a), .iB(b), .iCarry(ci), .iAdd_sub(1'b0), .oSum(s), .oCarry(co));

    initial begin
      errors = 0;
      for (k = 0; k < N_VECTORS; k = k + 1) begin
        a = `RAND256; b = `RAND256; ci = $urandom;
        if (k < 4)  begin a = k[0] ? {128{1'b1}} : 0; b = k[1] ? {128{1'b1}} : 0; ci = k[0]; end
        if (k == 4) begin a = {128{1'b1}}; b = 1; ci = 0; end   // carry through every bit
        #1;
        expected = a + b + ci;
        if ({co, s} !== expected) begin
          errors = errors + 1;
          if (errors == 1)
            $display("  add_sub_128b: a=%h b=%h cin=%b got=%h expected=%h", a, b, ci, {co, s}, expected);
        end
      end
      $display("%-28s %3d-bit  %s", "add_sub_128b", 128, errors == 0 ? "PASS" : "FAIL");
      total_errors = total_errors + errors;
    end
  end

  initial begin
    #(N_VECTORS + 10);
    $display("adders: %0s", total_errors == 0 ? "ALL PASS" : "FAIL");
    $finish;
  end

endmodule
