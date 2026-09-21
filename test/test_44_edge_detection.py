# SPDX-License-Identifier: Apache-2.0
"""Experiment 44: edge detection."""
import cocotb

from chiplab_helpers import EDGE_DETECTION, reset_manual, sample, step


@cocotb.test()
async def test_edge_detection(dut):
    await reset_manual(dut)

    # A transition produces one pulse, a steady level produces none.
    for level, expected in ((0, 0), (1, 5), (1, 4), (0, 2), (0, 0), (1, 5)):
        assert await step(dut, EDGE_DETECTION, level) == expected

    # No update while deselected; returning high creates no new edge.
    await step(dut, 0, 0)
    assert await step(dut, EDGE_DETECTION, 1) == 4

    # Reset restores the initial output.
    await reset_manual(dut)
    assert await sample(dut, EDGE_DETECTION, 0) == 0
