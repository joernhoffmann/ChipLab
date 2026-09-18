# SPDX-License-Identifier: Apache-2.0
"""Experiment 21: 4-bit left and right rotation."""
import cocotb

from chiplab_helpers import ROTATION, initialize, sample


@cocotb.test()
async def test_rotation(dut):
    initialize(dut)
    for operation in range(4):
        for inputs in range(256):
            value = inputs & 15
            amount = (inputs >> 4) & 3
            if amount == 0:
                expected = value
            elif operation & 1:
                expected = ((value >> amount) | (value << (4 - amount))) & 15
            else:
                expected = ((value << amount) | (value >> (4 - amount))) & 15
            assert await sample(dut, ROTATION, inputs, operation) == expected
