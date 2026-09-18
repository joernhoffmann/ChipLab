# SPDX-License-Identifier: Apache-2.0
"""Experiment 24: D latch."""
import cocotb

from chiplab_helpers import D_LATCH, initialize, sample


@cocotb.test()
async def test_d_latch(dut):
    initialize(dut)
    assert await sample(dut, D_LATCH, 0b11) == 1
    assert await sample(dut, D_LATCH, 0b00) == 1
    assert await sample(dut, D_LATCH, 0b10) == 0
