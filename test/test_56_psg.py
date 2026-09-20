# SPDX-License-Identifier: Apache-2.0
"""Experiment 56: register-controlled tone, noise, PWM, and decay envelope."""
import cocotb

from chiplab_helpers import PSG, reset_manual, sample, step

# Operation codes for the PSG module
OP_PLAY, OP_ADDRESS, OP_WRITE, OP_READ = range(4)

# PSG register addresses and bit masks
REG_ADDR_PERIOD_LOW     = 0x00
REG_ADDR_PERIOD_HIGH    = 0x01
REG_ADDR_VOLUME         = 0x02
REG_ADDR_CONTROL        = 0x03
REG_ADDR_DECAY_RATE     = 0x04
REG_ADDR_TRIGGER        = 0x05
REG_ADDR_TONE_PRESCALE  = 0x06      # Optional
REG_ADDR_ENVELOPE_PRESCALE = 0x07   # Optional

# Control and status bit masks
ENABLE, NOISE, ENVELOPE = 1, 2, 8
AUDIO, RAW, RUNNING = 1, 2, 64

async def write(dut, address, value):
    # Select address, then write
    await step(dut, PSG, address, OP_ADDRESS)
    return await step(dut, PSG, value, OP_WRITE)


async def read(dut, address):
    # Select address, then read
    await step(dut, PSG, address, OP_ADDRESS)
    return await sample(dut, PSG, 0, OP_READ)


@cocotb.test()
async def test_psg_registers(dut):
    # Reset values
    await reset_manual(dut)
    for address in (REG_ADDR_PERIOD_LOW,
                    REG_ADDR_PERIOD_HIGH,
                    REG_ADDR_VOLUME,
                    REG_ADDR_CONTROL,
                    REG_ADDR_DECAY_RATE,
                    REG_ADDR_TRIGGER):
        assert await read(dut, address) == 0


    # Register masks and unused addresses
    for address, value, expected in (
        (REG_ADDR_PERIOD_LOW, 0xAB, 0xAB),
        (REG_ADDR_PERIOD_HIGH, 0xCD, 0xCD),
        (REG_ADDR_VOLUME, 0xFF, 15),
        (REG_ADDR_CONTROL, 0xFF, 15),
        (REG_ADDR_DECAY_RATE, 0xFE, 0xFE),
        (0xFF, 0xFF, 0),
    ):
        await write(dut, address, value)
        assert await read(dut, address) == expected

    # Unimplemented addresses ignore writes and read zero.
    for address in (0x08, 0x09, 0x0A):
        await write(dut, address, 0xFF)
        assert await read(dut, address) == 0

    # Independent period bytes
    assert await read(dut, REG_ADDR_PERIOD_LOW) == 0xAB
    assert await read(dut, REG_ADDR_PERIOD_HIGH) == 0xCD

    # Keep registers unchanged
    await step(dut, PSG, 0, OP_PLAY)
    await step(dut, PSG, 0, OP_READ)
    await step(dut, 0, 0, OP_WRITE)
    assert await read(dut, REG_ADDR_VOLUME) == 15

    # Clear settings
    await reset_manual(dut)
    assert await read(dut, REG_ADDR_VOLUME) == 0


@cocotb.test()
async def test_psg_tone_pwm_noise(dut):
    # Enable tone
    await reset_manual(dut)
    await write(dut, REG_ADDR_VOLUME, 9)
    await write(dut, REG_ADDR_CONTROL, ENABLE)

    # Tone timing
    # - Half-period: 16*(period+1) clocks.
    # - Period write: restart oscillator.
    for period in (0, 2, 0x102):
        await write(dut, REG_ADDR_PERIOD_HIGH, period >> 8)
        await write(dut, REG_ADDR_PERIOD_LOW, period & 255)
        half_period = 16 * (period + 1)

        # Check one full cycle
        for tick in range(1, 2 * half_period + 1):
            output = await step(dut, PSG, 0)
            assert bool(output & RAW) == bool((tick // half_period) & 1)

    # PWM volume
    # - A 240-clock high half-cycle contains 16 complete 15-slot PWM cycles.
    # - Each volume step adds exactly 16 pulses, including the final step.
    for volume in range(16):
        await write(dut, REG_ADDR_VOLUME, volume)
        await write(dut, REG_ADDR_PERIOD_HIGH, 0)
        await write(dut, REG_ADDR_PERIOD_LOW, 14)
        pulses = 0

        # Count one complete tone cycle, independent of starting PWM phase.
        for _ in range(480):
            output = await step(dut, PSG, 0)
            pulses += bool(output & AUDIO)
            if not output & RAW:
                assert not output & AUDIO
        assert pulses == volume * 16

    # Noise sequence
    # - XOR taps: 16,15,13,4.
    # - Polynomial: x^16+x^15+x^13+x^4+1.
    # - Left shift, seed 1.
    await write(dut, REG_ADDR_CONTROL, ENABLE | NOISE)
    await write(dut, REG_ADDR_PERIOD_LOW, 0)
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
    await write(dut, REG_ADDR_CONTROL, 0)
    assert (await step(dut, PSG, 0) & (RAW | AUDIO)) == 0


@cocotb.test()
async def test_psg_envelope(dut):
    # Set volume and decay rate
    await reset_manual(dut)
    await write(dut, REG_ADDR_VOLUME, 2)
    await write(dut, REG_ADDR_DECAY_RATE, 1)
    await write(dut, REG_ADDR_CONTROL, ENABLE | ENVELOPE)

    # Start envelope
    output = await write(dut, REG_ADDR_TRIGGER, 1)
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
    assert await read(dut, REG_ADDR_TRIGGER) == 0

    # Held trigger: restart each clock
    await write(dut, REG_ADDR_TRIGGER, 1)
    for _ in range(5):
        output = await step(dut, PSG, 1, OP_WRITE)
        assert (output >> 2) & 15 == 2

    # Zero-volume trigger
    await write(dut, REG_ADDR_VOLUME, 0)
    output = await write(dut, REG_ADDR_TRIGGER, 1)
    assert (output & (RUNNING | 0x3C | AUDIO)) == 0

    # Reset to silence
    await reset_manual(dut)
    assert await sample(dut, PSG, 0) == 0


# Test optional sources and prescalers
@cocotb.test()
async def test_psg_sources_and_prescalers(dut):
    # Optional divider registers: defaults, masks and absent-register behavior.
    await reset_manual(dut)
    for address, default in (
        (REG_ADDR_TONE_PRESCALE, 4),
        (REG_ADDR_ENVELOPE_PRESCALE, 2),
    ):
        actual = await read(dut, address)
        assert actual in (0, default)
        await write(dut, address, 255)
        assert await read(dut, address) == (7 if actual else 0)

    # Check each source against independently stepped tone and LFSR models.
    for source in range(4):
        await reset_manual(dut)
        await write(dut, REG_ADDR_VOLUME, 15)
        await write(dut, REG_ADDR_CONTROL, ENABLE | (source << 1))
        await write(dut, REG_ADDR_PERIOD_LOW, 0)
        state = 1
        for tick in range(1, 1025):
            if tick % 16 == 0:
                feedback = ((state >> 15) ^ (state >> 14) ^ (state >> 12) ^ (state >> 3)) & 1
                state = ((state << 1) & 65535) | feedback
            tone, noise = (tick // 16) & 1, state & 1
            expected = (tone, noise, tone ^ noise, tone & noise)[source]
            output = await step(dut, PSG, 0)
            assert bool(output & RAW) == bool(expected)
            assert bool(output & AUDIO) == bool(expected)

    # Every programmable tone divider, or fixed /16 when omitted.
    await reset_manual(dut)
    programmable = bool(await read(dut, REG_ADDR_TONE_PRESCALE))
    for exponent in range(8) if programmable else (4,):
        await write(dut, REG_ADDR_TONE_PRESCALE, exponent)
        await write(dut, REG_ADDR_CONTROL, ENABLE)
        await write(dut, REG_ADDR_PERIOD_LOW, 1)
        half_period = (1 << exponent) * 2
        for tick in range(1, 2 * half_period + 1):
            output = await step(dut, PSG, 0)
            assert bool(output & RAW) == bool((tick // half_period) & 1)

    # Fastest programmable envelope divider, including stop at zero.
    await reset_manual(dut)
    programmable = bool(await read(dut, REG_ADDR_ENVELOPE_PRESCALE))
    await write(dut, REG_ADDR_ENVELOPE_PRESCALE, 0)
    await write(dut, REG_ADDR_VOLUME, 1)
    await write(dut, REG_ADDR_CONTROL, ENABLE | ENVELOPE)
    await write(dut, REG_ADDR_TRIGGER, 1)
    interval = 1024 if programmable else 4096
    for tick in range(1, interval + 1):
        output = await step(dut, PSG, 0)
        assert ((output >> 2) & 15) == (tick < interval)
        assert bool(output & RUNNING) == (tick < interval)
