`timescale 1ns / 1ps
//==============================================================================
// Module      : uart_top
// Project     : 512-bit multi-precision adder/subtractor on FPGA (PYNQ-Z2, Zynq-7020)
// Description : Top level of the accelerator: receives operand A and operand B over UART
//               (64 bytes each, most-significant byte first), runs the multi-precision
//               adder/subtractor and sends back the 65-byte result.
//               iAdd_sub selects the operation (0 = A + B, 1 = A - B).
//==============================================================================

module uart_top #(
    parameter   OPERAND_WIDTH = 512,
    parameter   ADDER_WIDTH   =128,
    parameter   NBYTES        = OPERAND_WIDTH/8,
    // UART settings
    parameter   CLK_FREQ      = 125_000_000,
    parameter   BAUD_RATE     = 115_200
  )
  (
    input   wire   iClk, iRst,
    input   wire   iRx,
    input wire     iAdd_sub,
    output  wire   oTx
  );

  // Buffer to exchange data between Pynq-Z2 and laptop
  reg [NBYTES*8-1:0] rA,rB;
  reg [(NBYTES+1)*8-1:0] rRes;

  // State definition
  localparam s_IDLE         = 4'b0000;
  localparam s_WAIT_RX_A    = 4'b0001;
  localparam s_WAIT_RX_B    = 4'b0010;
  localparam s_START_CAL    = 4'b0011;
  localparam s_WAIT_CAL     = 4'b0100;
  localparam s_END_CAL      = 4'b0101;
  localparam s_TX           = 4'b0110;
  localparam s_WAIT_TX      = 4'b0111;
  localparam s_DONE         = 4'b1000;

  // Declare all variables needed for the finite state machine
  // -> the FSM state
  reg [3:0]   rFSM;

  // Connection to UART TX (inputs = registers, outputs = wires)
  reg         rTxStart;
  reg [7:0]   rTxByte, rRxByte;

  wire [7:0]   wRxByte;

  wire        wTxBusy;
  wire        wTxDone;
  wire        wRxDone;

  // multi-precision adder interface
  reg rStart;

  wire [OPERAND_WIDTH-1:0] wOpA, wOpB;

  wire [OPERAND_WIDTH:0] wRes;
  wire wDone;

  uart_tx #(  .CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE) )
  UART_TX_INST
    (.iClk(iClk),
     .iRst(iRst),
     .iTxStart(rTxStart),
     .iTxByte(rTxByte),
     .oTxSerial(oTx),
     .oTxBusy(wTxBusy),
     .oTxDone(wTxDone)
     );

  uart_rx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE))
  UART_RX_INST
  (
    .iClk(iClk),
    .iRst(iRst),
    .iRxSerial(iRx),
    .oRxByte(wRxByte),
    .oRxDone(wRxDone)
  );

  mp_adder #(.OPERAND_WIDTH(OPERAND_WIDTH), .ADDER_WIDTH(ADDER_WIDTH))
  MP_ADDER_INST
  (
    .iClk(iClk),
    .iRst(iRst),
    .iStart(rStart),
    .iOpA(wOpA),
    .iOpB(wOpB),
    .iAdd_sub(iAdd_sub),
    .oRes(wRes),
    .oDone(wDone)
  );

  reg [$clog2(NBYTES):0] rCnt;

  always @(posedge iClk)
  begin

  // reset all registers upon reset
  if (iRst == 1 )
    begin
      rFSM <= s_IDLE;
      rTxStart <= 0;
      rCnt <= 0;
      rTxByte <= 0;
      rRxByte<=0;
      rA <= 0;
      rB <= 0;
      rRes <= 0;
      rStart <= 0;  // start pulse for the multi-precision adder
    end
  else
    begin
      case (rFSM)

        s_IDLE :
          begin
            rTxStart <= 0;
            rCnt <= 0;
            rTxByte <= 0;
            rRxByte<=0;
            rA <= 0;
            rB <= 0;
            rRes <= 0;
            rStart <= 0;  // start pulse for the multi-precision adder
            rFSM <= s_WAIT_RX_A;
          end

        s_WAIT_RX_A :
          begin
            if(rCnt < NBYTES)
              begin
                if(wRxDone)
                  begin
                    rA<={rA[NBYTES*8-9:0] , rRxByte};
                    rCnt<=rCnt+1;
                  end
                else
                  begin
                    rRxByte<=wRxByte;
                    rA<=rA;
                    rCnt<=rCnt;
                  end
                rFSM<=s_WAIT_RX_A;
              end
            else
              begin
                rA<=rA;
                rFSM <= s_WAIT_RX_B;
                rCnt<=0;
              end

          end

        s_WAIT_RX_B :
          begin
            if(rCnt < NBYTES)
              begin
                if(wRxDone)
                  begin
                    rB<={rB[NBYTES*8-9:0] , rRxByte};
                    rCnt<=rCnt+1;
                  end
                else
                  begin
                    rRxByte<=wRxByte;
                    rB<=rB;
                    rCnt<=rCnt;
                  end
                rFSM<=s_WAIT_RX_B;
              end
            else
              begin
                rB<=rB;
                rFSM <= s_START_CAL;
                rCnt<=0;
              end
          end

        s_START_CAL :
          begin
            rStart <= 1;
            rFSM <= s_WAIT_CAL;
          end

        s_WAIT_CAL :
          begin
            rStart<=0;
            if(!wDone)
              begin
                rFSM <= s_WAIT_CAL;
                rRes <= {7'b0000000, wRes};
              end
            else
              begin
                rFSM<=s_END_CAL;
                rRes <= {7'b0000000, wRes};
              end
          end

        s_END_CAL :
          begin
            rRes<=rRes;
            rFSM<=s_TX;
          end

        s_TX :
          begin
            if ( (rCnt < (NBYTES+1)) && (wTxBusy ==0) )
              begin
                rFSM <= s_WAIT_TX;
                rTxStart <= 1;
                rTxByte <= rRes[(NBYTES+1)*8-1:(NBYTES+1)*8-8];            // we send the uppermost byte
                rRes <= {rRes[(NBYTES+1)*8-9:0] , 8'b0000_0000};    // we shift from right to left
                rCnt <= rCnt + 1;
              end
            else
              begin
                rFSM <= s_DONE;
                rTxStart <= 0;
                rTxByte <= 0;
                rCnt <= 0;
              end
            end

            s_WAIT_TX :
              begin
                if (wTxDone) begin
                  rFSM <= s_TX;
                end
                else begin
                  rFSM <= s_WAIT_TX;
                  rTxStart <= 0;
                end
              end

            s_DONE :
              begin
                rFSM <= s_IDLE;
              end

            default :
              rFSM <= s_IDLE;

          endcase
      end
    end

    assign wOpA = rA;
    assign wOpB = rB;

endmodule
