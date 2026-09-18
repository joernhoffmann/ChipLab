# SPDX-License-Identifier: Apache-2.0
"""Experiment 14: half adder."""
import cocotb

from chiplab_helpers import HALF_ADDER, initialize, sample


@cocotb.test()
async def test_half_adder(dut):
    initialize(dut)
    for inputs in range(256):
        # Calculate sum and carry.
        # ui_out[0] is the sum (XOR) and ui_out[1] is the carry (AND).
        a = inputs & 1
        b = (inputs >> 1) & 1
        expected = (a ^ b) | ((a & b) << 1)

        assert await sample(dut, HALF_ADDER, inputs) == expected
