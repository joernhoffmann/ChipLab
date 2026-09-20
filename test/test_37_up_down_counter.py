# SPDX-License-Identifier: Apache-2.0
"""Experiment 37: Up/down counter."""
import cocotb
from cocotb.triggers import Timer

from chiplab_helpers import UP_DOWN_COUNTER, clock_input, sample, start_and_reset


@cocotb.test()
async def test_up_down_counter(dut):
    await start_and_reset(dut)

    # Reset value
    assert await sample(dut, UP_DOWN_COUNTER, 0) == 0

    # Count down from zero, then up through wraparound.
    for step in range(1, 18):
        assert await clock_input(dut, UP_DOWN_COUNTER, 0x11) == (-step) % 16
    for step in range(1, 18):
        assert await clock_input(dut, UP_DOWN_COUNTER, 0x10) == (15 + step) % 16

    # Enable low holds the register; operation bits are unused.
    held = await sample(dut, UP_DOWN_COUNTER, 0)
    for _ in range(3):
        assert await clock_input(dut, UP_DOWN_COUNTER, 0) == held

    # Selecting another experiment must preserve this register.
    for _ in range(3):
        assert await clock_input(dut, 0, 0xFF, 3) == 0
    assert await sample(dut, UP_DOWN_COUNTER, 0) == held

    # Reset also works while this experiment is deselected.
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await Timer(2, unit="ns")
    assert await sample(dut, UP_DOWN_COUNTER, 0) == 0
