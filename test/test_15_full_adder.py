# SPDX-License-Identifier: Apache-2.0
"""Experiment 15: full adder built from two half adders."""
import cocotb

from chiplab_helpers import FULL_ADDER, initialize, sample


@cocotb.test()
async def test_full_adder(dut):
    initialize(dut)
    for inputs in range(256):
        # Add A, B, and carry-in.
        total = (inputs & 1) + ((inputs >> 1) & 1) + ((inputs >> 2) & 1)
        expected = (total & 1) | ((total > 1) << 1)

        assert await sample(dut, FULL_ADDER, inputs) == expected
