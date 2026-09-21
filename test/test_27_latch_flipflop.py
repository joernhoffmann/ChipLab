# SPDX-License-Identifier: Apache-2.0
"""Experiment 27: D latch and D flip-flop."""
import cocotb
from cocotb.triggers import RisingEdge, Timer

from chiplab_helpers import LATCH_FLIPFLOP, reset_manual, sample, start_and_reset, step


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


@cocotb.test()
async def test_comparison_latch_ignores_reset(dut):
    await reset_manual(dut)
    for selection in (LATCH_FLIPFLOP, 0):
        # Initialize both storage elements, then close the latch gate.
        assert await sample(dut, LATCH_FLIPFLOP, 0b11) == 1
        assert await step(dut, LATCH_FLIPFLOP, 0b11) == 3
        assert await sample(dut, LATCH_FLIPFLOP, 0b01) == 3
        await sample(dut, selection, 0)

        # Without a clock edge, reset clears only the flip-flop. The latch holds one.
        dut.rst_n.value = 0
        await Timer(10, unit="ns")
        dut.rst_n.value = 1
        assert await sample(dut, LATCH_FLIPFLOP, 0) == 1

    # Gate and D still control the latch while the flip-flop is held in reset.
    dut.rst_n.value = 0
    assert await sample(dut, LATCH_FLIPFLOP, 0b10) == 0
    assert await sample(dut, LATCH_FLIPFLOP, 0b11) == 1
