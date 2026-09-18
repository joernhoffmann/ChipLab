# SPDX-License-Identifier: Apache-2.0
"""Experiment 15: full adder built from two half adders."""
import cocotb
from chiplab_helpers import FULL_ADDER, initialize, sample

@cocotb.test()
async def test_full_adder(dut):
    initialize(dut)
    for inputs in range(256):
        # The full adder takes three 1-bit inputs (ui_in[2:0]) and produces a 2-bit output (ui_out[1:0]).
        total = (inputs & 1) + ((inputs >> 1) & 1) + ((inputs >> 2) & 1)
        expected = (total & 1) | ((total > 1) << 1)

        assert await sample(dut, FULL_ADDER, inputs) == expected
