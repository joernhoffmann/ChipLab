# SPDX-License-Identifier: Apache-2.0
"""Experiment 25: T flip-flop."""
import cocotb
from chiplab_helpers import T_FLIPFLOP, clock_input, start_and_reset


@cocotb.test()
async def test_t_flipflop(dut):
    await start_and_reset(dut)

    # Toggle twice
    assert await clock_input(dut, T_FLIPFLOP, 1) == 1
    assert await clock_input(dut, T_FLIPFLOP, 1) == 0

    # Hold
    assert await clock_input(dut, T_FLIPFLOP, 0) == 0
