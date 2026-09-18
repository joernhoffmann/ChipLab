# SPDX-License-Identifier: Apache-2.0
"""Experiment 22: 4-bit ALU."""
import cocotb

from chiplab_helpers import ALU, initialize, sample


@cocotb.test()
async def test_alu(dut):
    initialize(dut)
    for operation in range(4):
        for inputs in range(256):
            a, b = inputs & 15, inputs >> 4
            carry = overflow = 0

            # Calculate the selected operation.
            # Add
            if operation == 0:
                total = a + b
                value, carry = total & 15, total > 15
                overflow = ((~(a ^ b) & (a ^ value)) >> 3) & 1

            # Substract
            elif operation == 1:
                value, carry = (a - b) & 15, a >= b
                overflow = (((a ^ b) & (a ^ value)) >> 3) & 1

            # AND
            elif operation == 2:
                value = a & b

            # OR
            else:
                value = a | b

            # Pack value, carry, overflow, zero, and sign.
            expected = (value | (carry << 4) | (overflow << 5) | ((value == 0) << 6) | (((value >> 3) & 1) << 7))
            assert await sample(dut, ALU, inputs, operation) == expected
