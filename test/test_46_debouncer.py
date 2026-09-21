# SPDX-License-Identifier: Apache-2.0
"""Experiment 46: debouncer."""
import cocotb

from chiplab_helpers import DEBOUNCER, reset_manual, sample, step


@cocotb.test()
async def test_debouncer(dut):
    await reset_manual(dut)

    # Short alternating pulses must not change the debounced output.
    for level in (1, 0) * 6:
        assert (await step(dut, DEBOUNCER, level)) & 1 == 0
    for _ in range(6):
        assert (await step(dut, DEBOUNCER, 0)) & 1 == 0

    # Two synchronizer edges, then four stable samples.
    for expected in (0, 2, 6, 10, 14, 3):
        assert await step(dut, DEBOUNCER, 1) == expected

    # Short release bounce is ignored.
    for level in (0, 1) * 6:
        assert (await step(dut, DEBOUNCER, level)) & 1 == 1
    for _ in range(6):
        await step(dut, DEBOUNCER, 1)
    for expected in (3, 1, 5, 9, 13, 0):
        assert await step(dut, DEBOUNCER, 0) == expected

    # Reset restores the initial output.
    await reset_manual(dut)
    assert await sample(dut, DEBOUNCER, 0) == 0
