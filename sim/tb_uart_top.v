`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// tb_uart_top.v
// End-to-end testbench for uart_top: a behavioural UART host sends operand A
// and operand B (64 bytes each, most significant byte first), then receives
// the 65-byte result and checks it against a reference model.
// The UART is scaled down (CLKS_PER_BIT = 16) to keep simulation short.
//------------------------------------------------------------------------------
module tb_uart_top;

  localparam OPERAND_WIDTH = 512;
  localparam NBYTES        = OPERAND_WIDTH / 8;
  localparam CLK_FREQ      = 1600;   // scaled: CLKS_PER_BIT = 1600 / 100 = 16
  localparam BAUD_RATE     = 100;
  localparam CLKS_PER_BIT  = CLK_FREQ / BAUD_RATE;
  localparam T             = 8;
  localparam BIT_TIME      = CLKS_PER_BIT * T;
  localparam N_TESTS       = 4;      // per mode

  reg  rClk = 1'b0, rRst = 1'b1, rRx = 1'b1, rAddSub = 1'b0;
  wire wTx;

  uart_top #(.OPERAND_WIDTH(OPERAND_WIDTH), .ADDER_WIDTH(128),
             .CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) dut (
    .iClk(rClk), .iRst(rRst), .iRx(rRx), .iAdd_sub(rAddSub), .oTx(wTx));

  always #(T/2) rClk = ~rClk;

  // host -> FPGA: one 8N1 frame, LSB first
  task send_byte(input [7:0] b);
    integer k;
    begin
      rRx = 1'b0; #(BIT_TIME);
      for (k = 0; k < 8; k = k + 1) begin rRx = b[k]; #(BIT_TIME); end
      rRx = 1'b1; #(BIT_TIME);
    end
  endtask

  // FPGA -> host: wait for a start bit, sample in the middle of each bit
  task recv_byte(output [7:0] b);
    integer k;
    begin
      @(negedge wTx);
      #(BIT_TIME + BIT_TIME/2);
      for (k = 0; k < 8; k = k + 1) begin b[k] = wTx; #(BIT_TIME); end
    end
  endtask

  integer i, j, k_rx, n, mode, errors = 0;
  reg [OPERAND_WIDTH-1:0]     a, b;
  reg [(NBYTES+1)*8-1:0]      received, expected;
  reg [7:0]                   byte_rx;

  initial begin
    repeat (10) @(posedge rClk);
    rRst = 1'b0;
    repeat (10) @(posedge rClk);

    for (mode = 0; mode < 2; mode = mode + 1) begin
      rAddSub = mode;
      for (n = 0; n < N_TESTS; n = n + 1) begin
        for (i = 0; i < OPERAND_WIDTH/32; i = i + 1) begin
          a[i*32 +: 32] = $urandom;
          b[i*32 +: 32] = $urandom;
        end
        if (n == 0) begin a = {OPERAND_WIDTH{1'b1}}; b = 1; end  // full carry chain

        fork
          begin
            for (j = NBYTES-1; j >= 0; j = j - 1) send_byte(a[j*8 +: 8]);
            for (j = NBYTES-1; j >= 0; j = j - 1) send_byte(b[j*8 +: 8]);
          end
          begin
            for (k_rx = NBYTES; k_rx >= 0; k_rx = k_rx - 1) begin
              recv_byte(byte_rx);
              received[k_rx*8 +: 8] = byte_rx;
            end
          end
        join

        expected = mode ? {8'h00, a - b} : {7'b0, {1'b0, a} + {1'b0, b}};
        if (received !== expected) begin
          errors = errors + 1;
          $display("FAIL (%s) got %h\n            exp %h", mode ? "sub" : "add", received, expected);
        end
        #(4*BIT_TIME);
      end
    end

    $display("uart_top: %0d transactions over UART, %0d errors -> %s",
             2 * N_TESTS, errors, errors == 0 ? "PASS" : "FAIL");
    $finish;
  end

  initial begin
    #(200_000_000);
    $display("uart_top: TIMEOUT -> FAIL");
    $finish;
  end

endmodule
