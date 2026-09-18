# SPDX-License-Identifier: Apache-2.0
"""Experiment 25: D flip-flop."""
import cocotb

from chiplab_helpers import D_FLIPFLOP, clock_input, start_and_reset


@cocotb.test()
async def test_d_flipflop(dut):
    await start_and_reset(dut)

    # Load 1 on a rising edge
    assert await clock_input(dut, D_FLIPFLOP, 1) == 1

    # Changing D without an edge keeps Q
    dut.ui_in.value = 0
    assert int(dut.uo_out.value) == 1

    # Load 0 on the next rising edge
    assert await clock_input(dut, D_FLIPFLOP, 0) == 0
