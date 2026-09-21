# SPDX-License-Identifier: Apache-2.0
"""Experiment 32: Accumulator using the shared ALU."""
import cocotb

from chiplab_helpers import ACCUMULATOR, clock_input, reset_manual, start_and_reset, step


@cocotb.test()
async def test_accumulator(dut):
    await start_and_reset(dut)

    # Add 3, then add 5
    assert await clock_input(dut, ACCUMULATOR, 0x13, 0) == 3
    assert await clock_input(dut, ACCUMULATOR, 0x15, 0) == 0xA8

    # Hold the result
    assert await clock_input(dut, ACCUMULATOR, 0x02, 0) == 0xA8

    # Subtract 7, then clear
    assert await clock_input(dut, ACCUMULATOR, 0x17, 1) == 0x31
    assert await clock_input(dut, ACCUMULATOR, 0x20, 0) == 0


@cocotb.test()
async def test_accumulator_logic(dut):
    await reset_manual(dut)

    # Check AND/OR for every operand pair, including the stored zero and sign flags.
    for a in range(16):
        for b in range(16):
            for operation in (2, 3):
                await step(dut, ACCUMULATOR, 0x20)
                # OR with zero loads A into the accumulator before the operation.
                await step(dut, ACCUMULATOR, 0x10 | a, 3)
                value = a & b if operation == 2 else a | b
                flags = (0x40 if value == 0 else 0) | (0x80 if value & 8 else 0)
                assert await step(dut, ACCUMULATOR, 0x10 | b, operation) == (flags | value)
