#!/usr/bin/env python3
"""
Host-side test script for the 512-bit multi-precision adder/subtractor.

Generates random operands, sends them to the PYNQ-Z2 over UART and checks the
result returned by the FPGA.

Protocol (see rtl/uart/uart_top.v):
  host -> FPGA : operand A, 64 bytes, most-significant byte first
                 operand B, 64 bytes, most-significant byte first
  FPGA -> host : result, 65 bytes, most-significant byte first
                 (addition: A + B including the carry-out bit,
                  subtraction: (A - B) mod 2^512)

The operation is selected on the board with switch SW0 (0 = add, 1 = subtract);
pass the matching --mode so the script computes the right reference value.

Requirements: Python 3.8+, pyserial  (pip install pyserial)

Example:
  python uart_host.py --port COM5 --mode add --count 10
  python uart_host.py --port /dev/ttyUSB0 --mode sub
"""
import argparse
import random
import sys
import time

OPERAND_BITS = 512
OPERAND_BYTES = OPERAND_BITS // 8
RESULT_BYTES = OPERAND_BYTES + 1
BAUD_RATE = 115200


def expected_result(a: int, b: int, mode: str) -> int:
    if mode == "add":
        return a + b
    return (a - b) % (1 << OPERAND_BITS)


def run_once(ser, a: int, b: int, mode: str, byte_delay: float) -> bool:
    ser.reset_input_buffer()
    for value in (a, b):
        for byte in value.to_bytes(OPERAND_BYTES, "big"):
            ser.write(bytes([byte]))
            if byte_delay:
                time.sleep(byte_delay)

    raw = ser.read(RESULT_BYTES)
    if len(raw) != RESULT_BYTES:
        print(f"  timeout: received {len(raw)} of {RESULT_BYTES} bytes")
        return False

    received = int.from_bytes(raw, "big")
    expected = expected_result(a, b, mode)
    ok = received == expected
    print(f"  A        = {a:#0{OPERAND_BYTES * 2 + 2}x}")
    print(f"  B        = {b:#0{OPERAND_BYTES * 2 + 2}x}")
    print(f"  expected = {expected:#0{RESULT_BYTES * 2 + 2}x}")
    print(f"  received = {received:#0{RESULT_BYTES * 2 + 2}x}")
    print("  -> PASS" if ok else "  -> FAIL")
    return ok


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--port", required=True, help="serial port, e.g. COM5 or /dev/ttyUSB0")
    parser.add_argument("--mode", choices=("add", "sub"), default="add",
                        help="operation selected with SW0 on the board (default: add)")
    parser.add_argument("--count", type=int, default=5, help="number of random tests (default: 5)")
    parser.add_argument("--seed", type=int, help="random seed for reproducible operands")
    parser.add_argument("--byte-delay", type=float, default=0.001,
                        help="pause between transmitted bytes in seconds (default: 0.001)")
    args = parser.parse_args()

    try:
        import serial  # pyserial
    except ImportError:
        print("pyserial is required: pip install pyserial")
        return 2

    rng = random.Random(args.seed)
    passed = 0
    with serial.Serial(args.port, BAUD_RATE, timeout=2) as ser:
        for i in range(args.count):
            a = rng.getrandbits(OPERAND_BITS)
            b = rng.getrandbits(OPERAND_BITS)
            print(f"Test {i + 1}/{args.count} ({args.mode})")
            passed += run_once(ser, a, b, args.mode, args.byte_delay)

    print(f"\n{passed}/{args.count} tests passed")
    return 0 if passed == args.count else 1


if __name__ == "__main__":
    sys.exit(main())
