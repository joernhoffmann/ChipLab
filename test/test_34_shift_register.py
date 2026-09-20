# SPDX-License-Identifier: Apache-2.0
"""Experiment 34: Shift register."""
import cocotb
from cocotb.triggers import Timer

from chiplab_helpers import SHIFT_REGISTER, clock_input, sample, start_and_reset


@cocotb.test()
async def test_shift_register(dut):
    await start_and_reset(dut)

    # Reset value
    assert await sample(dut, SHIFT_REGISTER, 0) == 0

    # Shift serial bits into the register.
    for bit, expected in ((1, 1), (0, 2), (1, 5), (1, 11), (0, 6)):
        assert await clock_input(dut, SHIFT_REGISTER, 0x10 | bit) == expected

    # Enable low holds the register; operation bits are unused.
    held = await sample(dut, SHIFT_REGISTER, 0)
    for _ in range(3):
        assert await clock_input(dut, SHIFT_REGISTER, 0) == held

    # Selecting another experiment must preserve this register.
    for _ in range(3):
        assert await clock_input(dut, 0, 0xFF, 3) == 0
    assert await sample(dut, SHIFT_REGISTER, 0) == held

    # Reset also works while this experiment is deselected.
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await Timer(2, unit="ns")
    assert await sample(dut, SHIFT_REGISTER, 0) == 0
