# SPDX-License-Identifier: Apache-2.0
"""Experiment 31: 4 x 4-bit read/write memory."""
import cocotb

from chiplab_helpers import MEMORY, reset_manual, sample, step


@cocotb.test()
async def test_memory(dut):
    await reset_manual(dut)
    expected = [0] * 4
    for address in range(4):
        assert await sample(dut, MEMORY, address << 4) == 0

    # Write every nibble to every address; other words must remain unchanged.
    for value in range(16):
        for address in range(4):
            expected[address] = value ^ address
            inputs = 0x40 | (address << 4) | expected[address]
            assert await step(dut, MEMORY, inputs) == expected[address]
            for read_address in range(4):
                assert await sample(dut, MEMORY, read_address << 4) == expected[read_address]

    # Clock edges without write enable must not store the changed input data.
    for address in range(4):
        inputs = (address << 4) | (expected[address] ^ 15)
        assert await step(dut, MEMORY, inputs) == expected[address]

    # A write command while deselected must not alter any word.
    await step(dut, 0, 0xFF)
    for address in range(4):
        assert await sample(dut, MEMORY, address << 4) == expected[address]

    # Reset clears the complete bank, including while another experiment is selected.
    await reset_manual(dut)
    for address in range(4):
        assert await sample(dut, MEMORY, address << 4) == 0
