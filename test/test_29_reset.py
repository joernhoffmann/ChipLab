# SPDX-License-Identifier: Apache-2.0
"""Experiment 29: Synchronous and asynchronous reset."""
import cocotb
from cocotb.triggers import Timer

from chiplab_helpers import RESET, clock_input, start_and_reset


@cocotb.test()
async def test_reset_types(dut):
    await start_and_reset(dut)

    # Set both flip-flops
    assert await clock_input(dut, RESET, 1) == 3

    # Only the asynchronous output resets immediately
    dut.rst_n.value = 0
    await Timer(1, unit="ns")
    output = int(dut.uo_out.value)
    assert output == 1

    # The synchronous output resets on the next edge
    assert await clock_input(dut, RESET, 0) == 0
    dut.rst_n.value = 1
