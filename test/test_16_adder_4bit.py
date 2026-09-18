# SPDX-License-Identifier: Apache-2.0
"""Experiment 16: 4-bit ripple-carry adder."""
import cocotb
from chiplab_helpers import ADDER_4BIT, initialize, sample

@cocotb.test()
async def test_adder_4bit(dut):
    initialize(dut)
    for inputs in range(256):
        # The 4-bit ripple-carry adder takes two 4-bit inputs (ui_in[7:0]) and produces a 6-bit output (ui_out[5:0]).
        # Outputs are ui_out[3:0] = sum, ui_out[4] = carry-out, ui_out[5] = overflow.
        a = inputs & 15
        b = inputs >> 4
        sum  = a + b
        value = sum & 15
        overflow = ((~(a ^ b) & (a ^ value)) >> 3) & 1
        expected = value | ((sum > 15) << 4) | (overflow << 5)

        assert await sample(dut, ADDER_4BIT, inputs) == expected
