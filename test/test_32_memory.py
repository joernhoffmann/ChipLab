# SPDX-License-Identifier: Apache-2.0
"""Experiment 32: 4 x 4-bit read/write memory."""
import cocotb

from chiplab_helpers import MEMORY, clock_input, start_and_reset


@cocotb.test()
async def test_memory(dut):
    await start_and_reset(dut)
    assert await clock_input(dut, MEMORY, 0x55) == 5
    assert await clock_input(dut, MEMORY, 0x6A) == 0x0A
    assert await clock_input(dut, MEMORY, 0x15) == 5
    assert await clock_input(dut, MEMORY, 0x2A) == 0x0A
