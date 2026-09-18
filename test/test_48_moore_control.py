# SPDX-License-Identifier: Apache-2.0
"""Experiment 48: Moore release control."""
import cocotb

from chiplab_helpers import MOORE_CONTROL, reset_manual, sample, step

START = 1 << 0
STOP = 1 << 1
REQUEST = 1 << 2
ENABLE = 1 << 4


@cocotb.test()
async def test_moore_control(dut):
    await reset_manual(dut)

    # IDLE ignores request. Start only takes effect on the clock edge.
    assert await sample(dut, MOORE_CONTROL, REQUEST) == 0
    assert await sample(dut, MOORE_CONTROL, ENABLE | START) == 0
    assert await step(dut, MOORE_CONTROL, ENABLE | START) == 3

    # Moore release stays high when request changes.
    assert await sample(dut, MOORE_CONTROL, ENABLE | REQUEST) == 3
    assert await sample(dut, MOORE_CONTROL, ENABLE) == 3

    # Stop waits for an enabled edge. Enable only controls state updates.
    assert await sample(dut, MOORE_CONTROL, STOP | REQUEST) == 3
    assert await step(dut, MOORE_CONTROL, STOP | REQUEST) == 3
    assert await step(dut, MOORE_CONTROL, ENABLE | STOP | REQUEST) == 0

    # Stop wins over start in both states.
    assert await step(dut, MOORE_CONTROL, ENABLE | START | STOP) == 0
    assert await step(dut, MOORE_CONTROL, ENABLE | START) == 3
    assert await step(dut, MOORE_CONTROL, ENABLE | START | STOP) == 0

    # Deselecting preserves ACTIVE.
    assert await step(dut, MOORE_CONTROL, ENABLE | START | REQUEST) == 3
    await step(dut, 0, ENABLE | STOP)
    assert await sample(dut, MOORE_CONTROL, REQUEST) == 3

    # Reset returns to IDLE.
    await reset_manual(dut)
    assert await sample(dut, MOORE_CONTROL, REQUEST) == 0
