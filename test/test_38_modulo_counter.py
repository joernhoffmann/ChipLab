# SPDX-License-Identifier: Apache-2.0
"""Experiment 38: Modulo-6 counter."""
import cocotb
from cocotb.triggers import Timer

from chiplab_helpers import MODULO_COUNTER, clock_input, sample, start_and_reset


@cocotb.test()
async def test_modulo_counter(dut):
    await start_and_reset(dut)

    # Reset value
    assert await sample(dut, MODULO_COUNTER, 0) == 0

    # Wrap at six, not at sixteen.
    for step in range(1, 19):
        assert await clock_input(dut, MODULO_COUNTER, 0x10) == step % 6

    # Hold with enable low (or operation 00).
    held = await sample(dut, MODULO_COUNTER, 0)
    for _ in range(3):
        assert await clock_input(dut, MODULO_COUNTER, 0) == held

    # Selecting another experiment must preserve this register.
    for _ in range(3):
        assert await clock_input(dut, 0, 0xFF, 3) == 0
    assert await sample(dut, MODULO_COUNTER, 0) == held

    # Reset also works while this experiment is deselected.
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await Timer(2, unit="ns")
    assert await sample(dut, MODULO_COUNTER, 0) == 0

