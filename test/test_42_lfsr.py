# SPDX-License-Identifier: Apache-2.0
"""Experiment 42: LFSR."""
import cocotb
from cocotb.triggers import Timer

from chiplab_helpers import LFSR, clock_input, sample, start_and_reset


@cocotb.test()
async def test_lfsr(dut):
    await start_and_reset(dut)

    # Reset value
    assert await sample(dut, LFSR, 0) == 1

    # Tap polynomial: x^4 + x^3 + 1 (stages 4 and 3).
    # Shift left; bit 3 XOR bit 2 feeds the new bit 0.
    # Visit every nonzero state before returning to the seed.
    sequence = (2, 4, 9, 3, 6, 13, 10, 5, 11, 7, 15, 14, 12, 8, 1)
    seen = set()
    for expected in sequence:
        output = await clock_input(dut, LFSR, 0x10)
        assert output == expected
        assert output not in seen
        seen.add(output)
    assert seen == set(range(1, 16))

    # Enable low holds the register; operation bits are unused.
    held = await sample(dut, LFSR, 0)
    for _ in range(3):
        assert await clock_input(dut, LFSR, 0) == held

    # Selecting another experiment must preserve this register.
    for _ in range(3):
        assert await clock_input(dut, 0, 0xFF, 3) == 0
    assert await sample(dut, LFSR, 0) == held

    # Reset also works while this experiment is deselected.
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await Timer(2, unit="ns")
    assert await sample(dut, LFSR, 0) == 1
