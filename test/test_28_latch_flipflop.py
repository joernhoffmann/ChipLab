# SPDX-License-Identifier: Apache-2.0
"""Experiment 28: D latch and D flip-flop."""
import cocotb
from cocotb.triggers import RisingEdge, Timer

from chiplab_helpers import LATCH_FLIPFLOP, start_and_reset


@cocotb.test()
async def test_latch_and_flipflop(dut):
    await start_and_reset(dut)
    dut.uio_in.value = LATCH_FLIPFLOP
    dut.ui_in.value = 0b11

    # The latch changes while the clock is still low
    await Timer(2, unit="ns")
    output = int(dut.uo_out.value)
    assert output & 1 == 1
    assert output & 2 == 0

    # The flip-flop changes on the rising edge
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    output = int(dut.uo_out.value)
    assert output & 3 == 3
