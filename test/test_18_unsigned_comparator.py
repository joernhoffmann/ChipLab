# SPDX-License-Identifier: Apache-2.0
"""Experiment 18: unsigned 4-bit comparator."""
import cocotb
from chiplab_helpers import UNSIGNED_COMPARATOR, initialize, sample

@cocotb.test()
async def test_unsigned_comparator(dut):
    initialize(dut)
    for inputs in range(256):
        a, b = inputs & 15, inputs >> 4
        expected = (a < b) | ((a == b) << 1) | ((a > b) << 2)
        assert await sample(dut, UNSIGNED_COMPARATOR, inputs) == expected
