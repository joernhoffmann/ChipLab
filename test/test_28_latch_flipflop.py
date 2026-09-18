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

    await Timer(2, unit="ns")
    assert int(dut.uo_out.value) & 1 == 1
    assert int(dut.uo_out.value) & 2 == 0

    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    assert int(dut.uo_out.value) & 3 == 3
