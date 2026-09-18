# SPDX-License-Identifier: Apache-2.0
"""Experiment 31: Register with load, hold, and clear."""
import cocotb

from chiplab_helpers import REGISTER_CONTROL, clock_input, start_and_reset


@cocotb.test()
async def test_register_control(dut):
    await start_and_reset(dut)

    # Load A
    assert await clock_input(dut, REGISTER_CONTROL, 0x1A) == 0x0A

    # Hold
    assert await clock_input(dut, REGISTER_CONTROL, 0x05) == 0x0A

    # Clear
    assert await clock_input(dut, REGISTER_CONTROL, 0x2F) == 0
