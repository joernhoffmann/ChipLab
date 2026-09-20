# SPDX-License-Identifier: Apache-2.0
"""Experiment 24: D latch."""
import cocotb
from cocotb.triggers import Timer

from chiplab_helpers import D_LATCH, initialize, reset_manual, sample


@cocotb.test()
async def test_d_latch(dut):
    initialize(dut)

    # Load 1 and close the gate
    assert await sample(dut, D_LATCH, 0b11) == 1
    assert await sample(dut, D_LATCH, 0b01) == 1

    # Change D while the gate is closed
    assert await sample(dut, D_LATCH, 0b00) == 1

    # Open the gate and load 0
    assert await sample(dut, D_LATCH, 0b10) == 0


@cocotb.test()
async def test_d_latch_ignores_reset(dut):
    await reset_manual(dut)
    for value in (0, 1):
        for selection in (D_LATCH, 0):
            # Initialize through the gate; power-up state is unspecified.
            assert await sample(dut, D_LATCH, 0b10 | value) == value
            assert await sample(dut, D_LATCH, value) == value
            await sample(dut, selection, 1 - value)

            # Reset cannot change a closed latch, even with opposite D at its input.
            dut.rst_n.value = 0
            await Timer(10, unit="ns")
            dut.rst_n.value = 1
            assert await sample(dut, D_LATCH, 1 - value) == value

    # An open latch still follows D while global reset is asserted.
    dut.rst_n.value = 0
    assert await sample(dut, D_LATCH, 0b10) == 0
    assert await sample(dut, D_LATCH, 0b11) == 1
