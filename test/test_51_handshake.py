# SPDX-License-Identifier: Apache-2.0
"""Experiment 51: handshake."""
import cocotb

from chiplab_helpers import HANDSHAKE, reset_manual, sample, step


@cocotb.test()
async def test_handshake(dut):
    await reset_manual(dut)

    # Completion alone cannot start a transaction.
    assert await step(dut, HANDSHAKE, 0x12) == 0

    # Request -> busy -> acknowledge; request stays high until acknowledged.
    assert await step(dut, HANDSHAKE, 0x11) == 6
    for _ in range(3):
        assert await step(dut, HANDSHAKE, 0x11) == 6
    assert await step(dut, HANDSHAKE, 0x13) == 9
    assert await step(dut, HANDSHAKE, 0x11) == 9
    assert await step(dut, HANDSHAKE, 0x10) == 0

    # Enable and selection both gate state transitions.
    assert await step(dut, HANDSHAKE, 1) == 0
    assert await step(dut, HANDSHAKE, 0x11) == 6
    assert await step(dut, HANDSHAKE, 3) == 6
    await step(dut, 0, 0x13)
    assert await sample(dut, HANDSHAKE, 0) == 6
    assert await step(dut, HANDSHAKE, 0x13) == 9

    # Reset restores the initial output.
    await reset_manual(dut)
    assert await sample(dut, HANDSHAKE, 0) == 0
