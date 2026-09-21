# SPDX-License-Identifier: Apache-2.0
"""Experiment 45: synchronizer."""
import cocotb

from chiplab_helpers import SYNCHRONIZER, reset_manual, sample, step


@cocotb.test()
async def test_synchronizer(dut):
    await reset_manual(dut)

    # Changes between edges do not appear at the synchronized output.
    assert await sample(dut, SYNCHRONIZER, 1) == 0
    assert await step(dut, SYNCHRONIZER, 1) == 0
    assert await step(dut, SYNCHRONIZER, 1) == 1

    # The falling transition also needs two sampling edges.
    assert await step(dut, SYNCHRONIZER, 0) == 1
    assert await step(dut, SYNCHRONIZER, 0) == 0

    # Deselecting holds both stages.
    await step(dut, 0, 1)
    assert await step(dut, SYNCHRONIZER, 1) == 0
    assert await step(dut, SYNCHRONIZER, 1) == 1

    # Reset restores the initial output.
    await reset_manual(dut)
    assert await sample(dut, SYNCHRONIZER, 0) == 0
