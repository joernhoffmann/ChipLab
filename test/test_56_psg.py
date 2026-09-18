# SPDX-License-Identifier: Apache-2.0
"""Experiment 56: register-controlled tone, noise, PWM, and decay envelope."""
import cocotb

from chiplab_helpers import PSG, reset_manual, sample, step

HOLD, ADDRESS, WRITE, READ = range(4)
PERIOD_LOW, PERIOD_HIGH, VOLUME, CONTROL, DECAY_RATE, TRIGGER = range(6)
ENABLE, NOISE, ENVELOPE = 1, 2, 4
AUDIO, RAW, RUNNING = 1, 2, 64


async def write(dut, address, value):
    # Select address, then write
    await step(dut, PSG, address, ADDRESS)
    return await step(dut, PSG, value, WRITE)


async def read(dut, address):
    # Select address, then read
    await step(dut, PSG, address, ADDRESS)
    return await sample(dut, PSG, 0, READ)


@cocotb.test()
async def test_psg_registers(dut):
    # Reset values
    await reset_manual(dut)
    for address in range(6):
        assert await read(dut, address) == 0

    # Register masks and unused addresses
    for address, value, expected in ((0, 0xAB, 0xAB), (1, 0xCD, 0xCD),
                                     (2, 0xFF, 15), (3, 0xF8, 0), (4, 0xFE, 0xFE),
                                     (6, 0xFF, 0), (0xFF, 0xFF, 0)):
        await write(dut, address, value)
        assert await read(dut, address) == expected

    # Independent period bytes
    assert await read(dut, PERIOD_LOW) == 0xAB
    assert await read(dut, PERIOD_HIGH) == 0xCD

    # Keep registers unchanged
    await step(dut, PSG, 0, HOLD)
    await step(dut, PSG, 0, READ)
    await step(dut, 0, 0, WRITE)
    assert await read(dut, VOLUME) == 15

    # Clear settings
    await reset_manual(dut)
    assert await read(dut, VOLUME) == 0


@cocotb.test()
async def test_psg_tone_pwm_noise(dut):
    # Enable tone
    await reset_manual(dut)
    await write(dut, VOLUME, 9)
    await write(dut, CONTROL, ENABLE)

    # Tone timing
    # - Half-period: 16*(period+1) clocks.
    # - Period write: restart oscillator.
    for period in (0, 2, 0x102):
        await write(dut, PERIOD_HIGH, period >> 8)
        await write(dut, PERIOD_LOW, period & 255)
        half_period = 16 * (period + 1)

        # Check one full cycle
        for tick in range(1, 2 * half_period + 1):
            output = await step(dut, PSG, 0)
            assert bool(output & RAW) == bool((tick // half_period) & 1)

    # PWM volume
    # - High half-cycle: volume high slots out of 16.
    for volume in (0, 1, 9, 15):
        await write(dut, VOLUME, volume)
        await write(dut, PERIOD_HIGH, 0)
        await write(dut, PERIOD_LOW, 0)
        pulses = 0

        # Count high PWM slots
        for _ in range(32):
            output = await step(dut, PSG, 0)
            pulses += bool(output & AUDIO)
        assert pulses == volume

    # Noise sequence
    # - XOR taps: 16,15,13,4.
    # - Polynomial: x^16+x^15+x^13+x^4+1.
    # - Left shift, seed 1.
    await write(dut, CONTROL, ENABLE | NOISE)
    await write(dut, PERIOD_LOW, 0)
    state = 1

    # Compare noise bits
    for tick in range(1, 1025):
        # Advance reference every 16 clocks
        if tick % 16 == 0:
            feedback = ((state >> 15) ^ (state >> 14) ^ (state >> 12) ^ (state >> 3)) & 1
            state = ((state << 1) & 0xFFFF) | feedback
        output = await step(dut, PSG, 0)
        assert bool(output & RAW) == bool(state & 1)

    # Pause while deselected
    held = await sample(dut, PSG, 0)
    for _ in range(20):
        await step(dut, 0, 0)
    assert await sample(dut, PSG, 0) == held

    # Mute output
    await write(dut, CONTROL, 0)
    assert (await step(dut, PSG, 0) & (RAW | AUDIO)) == 0


@cocotb.test()
async def test_psg_envelope(dut):
    # Set volume and decay rate
    await reset_manual(dut)
    await write(dut, VOLUME, 2)
    await write(dut, DECAY_RATE, 1)
    await write(dut, CONTROL, ENABLE | ENVELOPE)

    # Start envelope
    output = await write(dut, TRIGGER, 1)
    assert (output >> 2) & 15 == 2
    assert output & RUNNING

    # Decay to zero
    # - One volume step every 8192 clocks.
    for tick in range(1, 16385):
        output = await step(dut, PSG, 0)
        level = 2 - tick // 8192
        assert (output >> 2) & 15 == level
        assert bool(output & RUNNING) == bool(level)

    # Trigger has no stored value
    assert await read(dut, TRIGGER) == 0

    # Held trigger: restart each clock
    await write(dut, TRIGGER, 1)
    for _ in range(5):
        output = await step(dut, PSG, 1, WRITE)
        assert (output >> 2) & 15 == 2

    # Zero-volume trigger
    await write(dut, VOLUME, 0)
    output = await write(dut, TRIGGER, 1)
    assert (output & (RUNNING | 0x3C | AUDIO)) == 0

    # Reset to silence
    await reset_manual(dut)
    assert await sample(dut, PSG, 0) == 0
