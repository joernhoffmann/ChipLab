# SPDX-License-Identifier: Apache-2.0
"""Experiment 29: Register with enable."""
import cocotb

from chiplab_helpers import REGISTER_ENABLE, clock_input, start_and_reset


@cocotb.test()
async def test_register_enable(dut):
    await start_and_reset(dut)

    # Load A
    assert await clock_input(dut, REGISTER_ENABLE, 0x1A) == 0x0A

    # Hold while enable is low
    assert await clock_input(dut, REGISTER_ENABLE, 0x05) == 0x0A

    # Load 3
    assert await clock_input(dut, REGISTER_ENABLE, 0x13) == 0x03
