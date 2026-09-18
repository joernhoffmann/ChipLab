# SPDX-License-Identifier: Apache-2.0
"""Experiment 33: Accumulator using the shared ALU."""
import cocotb
from chiplab_helpers import ACCUMULATOR, clock_input, start_and_reset

@cocotb.test()
async def test_accumulator(dut):
    await start_and_reset(dut)
    assert await clock_input(dut, ACCUMULATOR, 0x13, 0) == 3
    assert await clock_input(dut, ACCUMULATOR, 0x15, 0) == 0xA8
    assert await clock_input(dut, ACCUMULATOR, 0x02, 0) == 0xA8
    assert await clock_input(dut, ACCUMULATOR, 0x17, 1) == 0x31
    assert await clock_input(dut, ACCUMULATOR, 0x20, 0) == 0
