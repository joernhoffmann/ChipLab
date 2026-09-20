# SPDX-License-Identifier: Apache-2.0
"""Experiment 55: 4 x 4-bit stack."""
import random

import cocotb

from chiplab_helpers import STACK, reset_manual, sample, step

# Stack operation codes and status flags.
HOLD, PUSH, POP, RESERVED = range(4)
EMPTY = 1 << 7

# Helper function to compute the expected output of the stack.
def expected_output(items):
    count = len(items)
    value = items[-1] if items else 0
    return value | (EMPTY if not items else 0) | (count << 4)


@cocotb.test()
async def test_stack(dut):
    await reset_manual(dut)
    items = []
    assert await sample(dut, STACK, 0) == EMPTY

    async def command(operation, value=0):
        # Update the reference buffer, then compare data, flags, and fill count.
        if operation == PUSH and len(items) < 4:
            items.append(value & 15)
        elif operation == POP and items:
            items.pop(-1)
        output = await step(dut, STACK, value, operation)
        assert output == expected_output(items)

    # Underflow, fill, overflow, and read order; all nibble values are covered.
    await command(POP)
    for base in range(0, 16, 4):
        for value in range(base, base + 4):
            await command(PUSH, value)
        await command(PUSH, 15)
        await command(HOLD, 7)
        await command(RESERVED, 9)
        for _ in range(5):
            await command(POP)

    # Interleaved operations exercise reused slots and FIFO pointer wraparound.
    rng = random.Random(54)
    for _ in range(300):
        await command(rng.choice((PUSH, POP)), rng.randrange(256))

    # Other selections cannot modify the stored entries.
    await step(dut, 0, 15, PUSH)
    await step(dut, 0, 0, POP)
    assert await sample(dut, STACK, 0) == expected_output(items)

    # Reset clears validity; old stored data must not become visible again.
    await reset_manual(dut)
    items.clear()
    assert await sample(dut, STACK, 0) == EMPTY
    await command(POP)
    await command(PUSH, 10)
    await command(POP)
