# SPDX-License-Identifier: Apache-2.0
"""Experiment 39: BCD counter."""
import cocotb
from cocotb.triggers import Timer

from chiplab_helpers import BCD_COUNTER, clock_input, sample, start_and_reset


@cocotb.test()
async def test_bcd_counter(dut):
    await start_and_reset(dut)

    # Reset value
    assert await sample(dut, BCD_COUNTER, 0) == 0

    # Every output remains a valid decimal digit.
    for step in range(1, 31):
        assert await clock_input(dut, BCD_COUNTER, 0x10) == step % 10

    # Hold with enable low (or operation 00).
    held = await sample(dut, BCD_COUNTER, 0)
    for _ in range(3):
        assert await clock_input(dut, BCD_COUNTER, 0) == held

    # Selecting another experiment must preserve this register.
    for _ in range(3):
        assert await clock_input(dut, 0, 0xFF, 3) == 0
    assert await sample(dut, BCD_COUNTER, 0) == held

    # Reset also works while this experiment is deselected.
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await Timer(2, unit="ns")
    assert await sample(dut, BCD_COUNTER, 0) == 0

