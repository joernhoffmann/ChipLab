# SPDX-License-Identifier: Apache-2.0
"""Experiment 53: multiplier."""
import cocotb

from chiplab_helpers import MULTIPLIER, reset_manual, sample, step


@cocotb.test()
async def test_multiplier(dut):
    await reset_manual(dut)

    # Check all operand pairs against multiplication in Python.
    for a in range(16):
        for b in range(16):
            inputs = a | (b << 4)
            assert await step(dut, MULTIPLIER, inputs, 3) == 5
            for completed in range(1, 5):
                # Changing inputs and start during RUN must not change operands.
                output = await step(dut, MULTIPLIER, inputs ^ 0xFF, 3)
                expected_status = (completed << 4) | (10 if completed == 4 else 5)
                assert output == expected_status
            assert await sample(dut, MULTIPLIER, 0, 1) == a * b

            # A held start keeps DONE; lowering it re-arms the controller.
            assert await step(dut, MULTIPLIER, 0, 3) == 74
            assert await step(dut, MULTIPLIER, 0, 0) == a * b

    # Pause a running calculation by selecting another experiment.
    assert await step(dut, MULTIPLIER, 0xF7, 3) == 5    # Start the multiplier with modified inputs
    assert await step(dut, MULTIPLIER, 0, 2) == 21      # Pause the multiplier by selecting another experiment

    for _ in range(3):
        await step(dut, 0, 0)
    assert await sample(dut, MULTIPLIER, 0, 2) == 21

    for _ in range(3):
        await step(dut, MULTIPLIER, 0, 2)
    assert await sample(dut, MULTIPLIER, 0) == 105

    # Reset aborts a calculation.
    await step(dut, MULTIPLIER, 0, 0)
    await step(dut, MULTIPLIER, 0xFF, 1)

    # Reset restores the initial output.
    await reset_manual(dut)
    assert await sample(dut, MULTIPLIER, 0) == 0
