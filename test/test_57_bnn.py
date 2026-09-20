# SPDX-License-Identifier: Apache-2.0
"""Experiment 57: register-programmed binary neurons sharing one datapath."""
import random

import cocotb

from chiplab_helpers import BNN, reset_manual, sample, step

OP_PLAY, OP_ADDRESS, OP_WRITE, OP_READ = range(4)
REG_ADDR_INPUT      = 0x00
REG_ADDR_CONTROL    = 0x01
REG_ADDR_OUTPUT     = 0x02
REG_ADDR_STATUS     = 0x03
REG_ADDR_NEURON     = 0x04
REG_ADDR_WEIGHTS    = 0x05
REG_ADDR_THRESHOLD  = 0x06
REG_ADDR_MATCHES    = 0x07
REG_ADDR_COUNT      = 0x08

# Helper functions for register access and BNN configuration.
async def write(dut, address, value):
    await step(dut, BNN, address, OP_ADDRESS)
    return await step(dut, BNN, value, OP_WRITE)

# Helper function for reading a register.
async def read(dut, address):
    await step(dut, BNN, address, OP_ADDRESS)
    return await sample(dut, BNN, 0, OP_READ)

# Detect the built neuron count through the public register interface.
async def reset_and_detect_neurons(dut):
    await reset_manual(dut)
    neuron_count = 1
    for index in range(1, 8):
        await write(dut, REG_ADDR_NEURON, index)
        selected = await read(dut, REG_ADDR_NEURON)
        if selected == index:
            assert neuron_count == index, "Neuron indices must be contiguous"
            neuron_count += 1
        else:
            assert selected == neuron_count - 1, "Invalid selection must retain the previous index"

    dut._log.info("Detected %d BNN neurons", neuron_count)
    # Leave the device in its reset state for the actual test.
    await reset_manual(dut)
    return neuron_count

# Helper function for configuring the BNN with weights and thresholds.
async def configure(dut, weights, thresholds):
    neuron_count = len(weights)
    assert len(thresholds) == neuron_count
    for index in range(neuron_count):
        await write(dut, REG_ADDR_NEURON, index)
        await write(dut, REG_ADDR_WEIGHTS, weights[index])
        await write(dut, REG_ADDR_THRESHOLD, thresholds[index])

# Helper function for calculating and checking all BNN neuron outputs.
async def calculate(dut, inputs, weights, thresholds):
    neuron_count = len(weights)
    # Initialize the calculation by writing the input and ensuring the status and output are cleared.
    await write(dut, REG_ADDR_INPUT, inputs)
    assert await read(dut, REG_ADDR_STATUS) == 0
    assert await read(dut, REG_ADDR_OUTPUT) == 0
    expected = 0

    # Perform the calculation for each neuron and update the expected output accordingly.
    for index in range(neuron_count):
        count = (255 ^ (inputs ^ weights[index])).bit_count()
        expected |= int(count >= thresholds[index]) << index
        assert await step(dut, BNN, 0, OP_PLAY) == expected

        # Readback must not advance the calculation.
        assert await read(dut, REG_ADDR_STATUS) == int(index == neuron_count - 1)

    # After completing all neuron calculations, the output should match the expected value.
    assert await read(dut, REG_ADDR_OUTPUT) == expected
    return expected

@cocotb.test()
async def test_bnn_registers(dut):
    neuron_count = await reset_and_detect_neurons(dut)
    for address in range(REG_ADDR_THRESHOLD + 1):
        assert await read(dut, address) == 0

    # Diagnostic outputs are live, not reset registers: zero matches zero.
    assert await read(dut, REG_ADDR_MATCHES) == 255
    assert await read(dut, REG_ADDR_COUNT) == 8

    # Test control register behavior.
    await write(dut, REG_ADDR_CONTROL, 0xFE)
    assert await read(dut, REG_ADDR_CONTROL) == 0
    await write(dut, REG_ADDR_CONTROL, 0xFF)
    assert await read(dut, REG_ADDR_CONTROL) == 1

    # Test weight and threshold configuration.
    weights = [(0x31 * i + 7) & 255 for i in range(neuron_count)]
    thresholds = [(i + 9) & 15 for i in range(neuron_count)]
    await configure(dut, weights, [value | 0xF0 for value in thresholds])
    for index in range(neuron_count):
        await write(dut, REG_ADDR_NEURON, index)
        assert await read(dut, REG_ADDR_WEIGHTS) == weights[index]
        assert await read(dut, REG_ADDR_THRESHOLD) == thresholds[index]

    # Reject the full out-of-range byte; do not truncate it into a valid index.
    for invalid in (neuron_count, 8, 255):
        await write(dut, REG_ADDR_NEURON, invalid)
        assert await read(dut, REG_ADDR_NEURON) == neuron_count - 1

    # Attempt to write to read-only registers and ensure the values do not change.
    for address in (REG_ADDR_OUTPUT, REG_ADDR_STATUS, REG_ADDR_MATCHES, REG_ADDR_COUNT, 0xFF):
        before = await read(dut, address)
        await write(dut, address, 255)
        assert await read(dut, address) == before

    # Deselecting prevents register writes, and reset clears every weight bank.
    await step(dut, BNN, REG_ADDR_INPUT, OP_ADDRESS)
    await step(dut, 0, 255, OP_WRITE)
    assert await read(dut, REG_ADDR_INPUT) == 0

    # After a manual reset, all weight banks should be cleared.
    await reset_manual(dut)
    for index in range(neuron_count):
        await write(dut, REG_ADDR_NEURON, index)
        assert await read(dut, REG_ADDR_WEIGHTS) == 0
        assert await read(dut, REG_ADDR_THRESHOLD) == 0


@cocotb.test()
async def test_bnn_datapath(dut):
    neuron_count = await reset_and_detect_neurons(dut)
    await write(dut, REG_ADDR_WEIGHTS, 0xA5)
    # Exhaust every XNOR pattern and popcount result through the public bus.
    for inputs in range(256):
        await write(dut, REG_ADDR_INPUT, inputs)
        matches = 255 ^ (inputs ^ 0xA5)
        assert await read(dut, REG_ADDR_MATCHES) == matches
        assert await read(dut, REG_ADDR_COUNT) == matches.bit_count()

    await write(dut, REG_ADDR_CONTROL, 1)
    # All threshold boundaries, including always-true and always-false values.
    weights = [0] * neuron_count
    for threshold in range(16):
        thresholds = [threshold] * neuron_count
        await configure(dut, weights, thresholds)
        for count in range(9):
            inputs = 255 ^ ((1 << count) - 1)
            await calculate(dut, inputs, weights, thresholds)

    # Distinct weight banks must route to the correct result and diagnostic bits.
    rng = random.Random(57)
    for _ in range(24):
        weights = [rng.randrange(256) for _ in range(neuron_count)]
        thresholds = [rng.randrange(10) for _ in range(neuron_count)]
        inputs = rng.randrange(256)
        await configure(dut, weights, thresholds)
        await calculate(dut, inputs, weights, thresholds)
        for index in range(neuron_count):
            await write(dut, REG_ADDR_NEURON, index)
            matches = 255 ^ (inputs ^ weights[index])
            assert await read(dut, REG_ADDR_MATCHES) == matches
            assert await read(dut, REG_ADDR_COUNT) == matches.bit_count()


@cocotb.test()
async def test_bnn_pause_restart(dut):
    neuron_count = await reset_and_detect_neurons(dut)
    await write(dut, REG_ADDR_CONTROL, 1)

    # Reset thresholds are zero: every neuron produces one.
    progress = max(0, neuron_count // 2)
    for _ in range(progress):
        await step(dut, BNN, 0, OP_PLAY)
    partial = (1 << progress) - 1
    assert await read(dut, REG_ADDR_OUTPUT) == partial
    assert await read(dut, REG_ADDR_STATUS) == 0

    # Deselection and register reads pause calculation without resetting progress.
    for _ in range(10):
        await step(dut, 0, 0, OP_PLAY)
        await step(dut, BNN, 0, OP_READ)
    await write(dut, REG_ADDR_CONTROL, 0)

    # CONTROL = 0 pauses calculation even while the BNN remains selected.
    for _ in range(10):
        assert await step(dut, BNN, 0, OP_PLAY) == partial
    assert await read(dut, REG_ADDR_STATUS) == 0
    await write(dut, REG_ADDR_CONTROL, 1)

    # Continue calculation from the paused state.
    for index in range(progress, neuron_count):
        assert await step(dut, BNN, 0, OP_PLAY) == (1 << (index + 1)) - 1
    assert await read(dut, REG_ADDR_STATUS) == 1
    for _ in range(10):
        assert await step(dut, BNN, 0, OP_PLAY) == (1 << neuron_count) - 1

    # Every writable configuration field clears completion and partial outputs.
    for address, value in ((REG_ADDR_INPUT, 0xFF), (REG_ADDR_WEIGHTS, 0xFF), (REG_ADDR_THRESHOLD, 9)):
        await write(dut, address, value)
        assert await read(dut, REG_ADDR_STATUS) == 0
        assert await read(dut, REG_ADDR_OUTPUT) == 0
        for _ in range(neuron_count):
            await step(dut, BNN, 0, OP_PLAY)
        assert await read(dut, REG_ADDR_STATUS) == 1

    # A write during a calculation must restart at neuron zero.
    await write(dut, REG_ADDR_THRESHOLD, 0)
    if neuron_count > 1:
        await step(dut, BNN, 0, OP_PLAY)
    await write(dut, REG_ADDR_INPUT, 0)

    # Check the complete output sequence after the restart.
    for index in range(neuron_count):
        assert await step(dut, BNN, 0, OP_PLAY) == (1 << (index + 1)) - 1
        assert await read(dut, REG_ADDR_STATUS) == int(index == neuron_count - 1)
    await reset_manual(dut)
    assert await read(dut, REG_ADDR_STATUS) == 0
    assert await read(dut, REG_ADDR_OUTPUT) == 0
