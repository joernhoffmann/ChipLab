# SPDX-License-Identifier: Apache-2.0
"""Experiment 26: JK flip-flop."""
import cocotb

from chiplab_helpers import JK_FLIPFLOP, clock_input, start_and_reset


@cocotb.test()
async def test_jk_flipflop(dut):
    await start_and_reset(dut)

    # Set and hold
    assert await clock_input(dut, JK_FLIPFLOP, 0b01) == 1
    assert await clock_input(dut, JK_FLIPFLOP, 0b00) == 1

    # Toggle and reset
    assert await clock_input(dut, JK_FLIPFLOP, 0b11) == 0
    assert await clock_input(dut, JK_FLIPFLOP, 0b10) == 0
