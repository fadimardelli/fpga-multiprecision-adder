#!/usr/bin/env bash
# Runs the self-checking testbenches with Icarus Verilog (>= 11).
#
# Usage:  ./scripts/run_sim.sh             # all testbenches
#         ./scripts/run_sim.sh tb_adders   # a single testbench
#
# Icarus Verilog does not accept synthesis attributes such as (* keep="true" *)
# in front of continuous assignments (Vivado does). The script therefore copies
# the RTL into build/sim and strips those attributes there; they have no effect
# on simulation and the sources in rtl/ are left untouched.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$ROOT/build/sim"
if [ "$#" -gt 0 ]; then TESTS=("$@"); else TESTS=(tb_adders tb_mp_adder tb_uart_top); fi

command -v iverilog >/dev/null || { echo "iverilog not found - install Icarus Verilog"; exit 1; }

rm -rf "$BUILD" && mkdir -p "$BUILD/src"
for f in "$ROOT"/rtl/*/*.v; do
  sed -E 's/\(\*[^*]*\*\)//g' "$f" > "$BUILD/src/$(basename "$f")"
done

status=0
for tb in "${TESTS[@]}"; do
  echo "=== $tb"
  iverilog -g2012 -o "$BUILD/$tb.vvp" -s "$tb" "$ROOT/sim/$tb.v" "$BUILD"/src/*.v
  out="$(cd "$BUILD" && vvp -n "$tb.vvp")"
  echo "$out" | grep -v '\$finish'
  if echo "$out" | grep -q 'FAIL'; then status=1; fi
done
exit $status
