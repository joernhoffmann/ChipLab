# SPDX-License-Identifier: Apache-2.0
"""Experiment 46: clock enable."""
import cocotb

from chiplab_helpers import CLOCK_ENABLE, reset_manual, sample, step


@cocotb.test()
async def test_clock_enable(dut):
    await reset_manual(dut)

    # Check all divisors, including divide-by-one and wraparound.
    for period in range(1, 17):
        await reset_manual(dut)
        for edge in range(1, 2 * period + 1):
            count = edge % period
            expected = (count << 1) | (count == 0)
            assert await step(dut, CLOCK_ENABLE, 0x10 | (period - 1)) == expected

    # Disable clears the pulse but preserves the counter.
    await reset_manual(dut)
    assert await step(dut, CLOCK_ENABLE, 0x13) == 2
    assert await step(dut, CLOCK_ENABLE, 0x03) == 2
    await step(dut, 0, 0x13)
    assert await step(dut, CLOCK_ENABLE, 0x13) == 4

    # Reducing the limit wraps immediately at the next enabled edge.
    assert await step(dut, CLOCK_ENABLE, 0x10) == 1
    assert await step(dut, CLOCK_ENABLE, 0) == 0

    # Reset restores the initial output.
    await reset_manual(dut)
    assert await sample(dut, CLOCK_ENABLE, 0) == 0
