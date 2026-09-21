# SPDX-License-Identifier: Apache-2.0
"""Experiment 24: D flip-flop."""
import cocotb

from chiplab_helpers import D_FLIPFLOP, reset_manual, sample, step


@cocotb.test()
async def test_d_flipflop(dut):
    await reset_manual(dut)

    # Load 1 on a rising edge
    assert await step(dut, D_FLIPFLOP, 1) == 1

    # Keep the clock stopped and allow D to settle before checking that Q holds.
    assert await sample(dut, D_FLIPFLOP, 0) == 1

    # Load 0 on the next rising edge
    assert await step(dut, D_FLIPFLOP, 0) == 0

    # A rising D also leaves Q unchanged until a clock edge.
    assert await sample(dut, D_FLIPFLOP, 1) == 0
