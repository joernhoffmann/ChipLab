# SPDX-License-Identifier: Apache-2.0
"""Experiment 19: signed 4-bit comparator."""
import cocotb

from chiplab_helpers import SIGNED_COMPARATOR, initialize, sample


def signed_4bit(value):
    return value - 16 if value & 8 else value


@cocotb.test()
async def test_signed_comparator(dut):
    initialize(dut)
    for inputs in range(256):
        a = signed_4bit(inputs & 15)
        b = signed_4bit(inputs >> 4)
        expected = (a < b) | ((a == b) << 1) | ((a > b) << 2)
        assert await sample(dut, SIGNED_COMPARATOR, inputs) == expected
