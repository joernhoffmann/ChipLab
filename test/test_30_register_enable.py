# SPDX-License-Identifier: Apache-2.0
"""Experiment 30: Register with enable."""
import cocotb

from chiplab_helpers import REGISTER_ENABLE, clock_input, start_and_reset


@cocotb.test()
async def test_register_enable(dut):
    await start_and_reset(dut)
    assert await clock_input(dut, REGISTER_ENABLE, 0x1A) == 0x0A
    assert await clock_input(dut, REGISTER_ENABLE, 0x05) == 0x0A
    assert await clock_input(dut, REGISTER_ENABLE, 0x13) == 0x03
