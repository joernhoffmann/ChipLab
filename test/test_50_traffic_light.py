# SPDX-License-Identifier: Apache-2.0
"""Experiment 50: traffic light."""
import cocotb

from chiplab_helpers import TRAFFIC_LIGHT, reset_manual, sample, step


@cocotb.test()
async def test_traffic_light(dut):
    await reset_manual(dut)

    # Reset means red; each tick advances one phase.
    assert await sample(dut, TRAFFIC_LIGHT, 0) == 1
    for expected in (11, 20, 26, 1) * 3:
        assert await step(dut, TRAFFIC_LIGHT, 0x11) == expected
        assert await step(dut, TRAFFIC_LIGHT, 0x10) == expected
        assert await step(dut, TRAFFIC_LIGHT, 0x01) == expected

    # The phase holds while another experiment is selected.
    assert await step(dut, TRAFFIC_LIGHT, 0x11) == 11
    await step(dut, 0, 0x11)
    assert await sample(dut, TRAFFIC_LIGHT, 0) == 11

    # Reset restores the initial output.
    await reset_manual(dut)
    assert await sample(dut, TRAFFIC_LIGHT, 0) == 1
