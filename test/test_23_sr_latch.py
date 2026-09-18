# SPDX-License-Identifier: Apache-2.0
"""Experiment 23: SR latch."""
import cocotb

from chiplab_helpers import SR_LATCH, initialize, sample


@cocotb.test()
async def test_sr_latch(dut):
    initialize(dut)

    # Set and hold
    assert await sample(dut, SR_LATCH, 0b01) & 3 == 0b01
    assert await sample(dut, SR_LATCH, 0b00) & 3 == 0b01

    # Reset
    assert await sample(dut, SR_LATCH, 0b10) & 3 == 0b10

    # Invalid input
    assert await sample(dut, SR_LATCH, 0b11) & 4
