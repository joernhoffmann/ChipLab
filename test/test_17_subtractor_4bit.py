# SPDX-License-Identifier: Apache-2.0
"""Experiment 17: 4-bit subtraction using two's complement."""
import cocotb
from chiplab_helpers import SUBTRACTOR_4BIT, initialize, sample


@cocotb.test()
async def test_subtractor_4bit(dut):
    initialize(dut)
    for inputs in range(256):
        a, b = inputs & 15, inputs >> 4
        value = (a - b) & 15
        overflow = (((a ^ b) & (a ^ value)) >> 3) & 1
        expected = value | ((a >= b) << 4) | (overflow << 5)
        
        assert await sample(dut, SUBTRACTOR_4BIT, inputs) == expected
