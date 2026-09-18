# SPDX-License-Identifier: Apache-2.0
"""Experiment 20: logical and arithmetic shifts."""
import cocotb

from chiplab_helpers import SHIFTS, initialize, sample


@cocotb.test()
async def test_shifts(dut):
    initialize(dut)
    for operation in range(4):
        for inputs in range(256):
            value = inputs & 15
            amount = (inputs >> 4) & 3

            # Shift left
            if operation == 0:
                expected = (value << amount) & 15

            # Shift right
            elif operation == 1:
                expected = value >> amount

            # Signed shift right
            elif operation == 2:
                signed = value - 16 if value & 8 else value
                expected = (signed >> amount) & 15

            else:
                expected = 0

            assert await sample(dut, SHIFTS, inputs, operation) == expected
