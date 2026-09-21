# SPDX-License-Identifier: Apache-2.0
"""Experiment 41: Ring counter."""
import cocotb
from cocotb.triggers import Timer

from chiplab_helpers import RING_COUNTER, clock_input, sample, start_and_reset


@cocotb.test()
async def test_ring_counter(dut):
    await start_and_reset(dut)

    # Reset value
    assert await sample(dut, RING_COUNTER, 0) == 1

    # Exactly one bit moves around the ring.
    for expected in (2, 4, 8, 1) * 3:
        assert await clock_input(dut, RING_COUNTER, 0x10) == expected

    # Enable low holds the register; operation bits are unused.
    held = await sample(dut, RING_COUNTER, 0)
    for _ in range(3):
        assert await clock_input(dut, RING_COUNTER, 0) == held

    # Selecting another experiment must preserve this register.
    for _ in range(3):
        assert await clock_input(dut, 0, 0xFF, 3) == 0
    assert await sample(dut, RING_COUNTER, 0) == held

    # Reset also works while this experiment is deselected.
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await Timer(2, unit="ns")
    assert await sample(dut, RING_COUNTER, 0) == 1
