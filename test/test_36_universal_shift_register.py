# SPDX-License-Identifier: Apache-2.0
"""Experiment 36: Universal shift register."""
import cocotb
from cocotb.triggers import Timer

from chiplab_helpers import UNIVERSAL_SHIFT_REGISTER, clock_input, sample, start_and_reset


@cocotb.test()
async def test_universal_shift_register(dut):
    await start_and_reset(dut)

    # Reset value
    assert await sample(dut, UNIVERSAL_SHIFT_REGISTER, 0) == 0

    # Parallel load, then shift in both directions.
    assert await clock_input(dut, UNIVERSAL_SHIFT_REGISTER, 0x0A, 3) == 10
    assert await clock_input(dut, UNIVERSAL_SHIFT_REGISTER, 1, 1) == 5
    assert await clock_input(dut, UNIVERSAL_SHIFT_REGISTER, 1, 2) == 10
    assert await clock_input(dut, UNIVERSAL_SHIFT_REGISTER, 0, 2) == 5

    # Load every possible word.
    for value in range(16):
        assert await clock_input(dut, UNIVERSAL_SHIFT_REGISTER, value, 3) == value

    # Operation 00 holds the universal shift register.
    held = await sample(dut, UNIVERSAL_SHIFT_REGISTER, 0)
    for _ in range(3):
        assert await clock_input(dut, UNIVERSAL_SHIFT_REGISTER, 0) == held

    # Selecting another experiment must preserve this register.
    for _ in range(3):
        assert await clock_input(dut, 0, 0xFF, 3) == 0
    assert await sample(dut, UNIVERSAL_SHIFT_REGISTER, 0) == held

    # Reset also works while this experiment is deselected.
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await Timer(2, unit="ns")
    assert await sample(dut, UNIVERSAL_SHIFT_REGISTER, 0) == 0
