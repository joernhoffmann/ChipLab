# SPDX-License-Identifier: Apache-2.0
"""Experiment 48: pwm."""
import cocotb

from chiplab_helpers import PWM, reset_manual, sample, step


@cocotb.test()
async def test_pwm(dut):
    await reset_manual(dut)

    # Count high samples over complete PWM periods for every duty setting.
    for duty in range(32):
        await reset_manual(dut)
        high_samples = 0
        for edge in range(1, 33):
            output = await step(dut, PWM, 0x20 | duty)
            phase = edge % 16
            assert output >> 1 == phase
            assert output & 1 == (phase < duty)
            high_samples += output & 1
        assert high_samples == 2 * min(duty, 16)

    # Disabled output is low and the phase holds.
    assert await step(dut, PWM, 0x28) == 3
    assert await step(dut, PWM, 8) == 2
    await step(dut, 0, 0x28)
    assert await sample(dut, PWM, 0x28) == 3

    # Reset restores the initial output.
    await reset_manual(dut)
    assert await sample(dut, PWM, 0) == 0
