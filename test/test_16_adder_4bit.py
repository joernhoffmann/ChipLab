# SPDX-License-Identifier: Apache-2.0
"""Experiment 16: 4-bit ripple-carry adder."""
import cocotb

from chiplab_helpers import ADDER_4BIT, initialize, sample


@cocotb.test()
async def test_adder_4bit(dut):
    initialize(dut)
    for inputs in range(256):
        # Add the two 4-bit operands and calculate the flags.
        a = inputs & 15
        b = inputs >> 4
        total = a + b
        value = total & 15
        overflow = ((~(a ^ b) & (a ^ value)) >> 3) & 1

        expected = value | ((total > 15) << 4) | (overflow << 5)
        assert await sample(dut, ADDER_4BIT, inputs) == expected
