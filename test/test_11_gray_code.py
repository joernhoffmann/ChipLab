# SPDX-License-Identifier: Apache-2.0
"""Experiment 11: Convert four bits in both directions; ui_in[4] selects Gray to binary."""
import cocotb

from chiplab_helpers import GRAY_CODE, initialize, sample


# Reflected Gray sequence, indexed by binary value.
# The grey encoding of a binary number is obtained by performing a bitwise XOR between the number and its right-shifted version.
# For example, the Gray code for binary 3 (0011) is calculated as follows:
# 1. Right shift the binary number: 0011 >> 1 = 000
# 2. Perform bitwise XOR: 0011 ^ 0001 = 0010 (which is 2 in decimal)
GRAY = (0, 1, 3, 2, 6, 7, 5, 4, 12, 13, 15, 14, 10, 11, 9, 8)


@cocotb.test()
async def test_gray_code(dut):
    """Check all input bytes, including unused bits and invalid inputs."""
    initialize(dut)
    for inputs in range(256):
        # The Gray code converter takes a 4-bit input (ui_in[3:0]) and converts it to its corresponding Gray code representation.
        value = inputs & 15
        expected = GRAY.index(value) if inputs & 16 else GRAY[value]

        output = await sample(dut, GRAY_CODE, inputs)
        assert output == expected, (
            f"input={inputs:08b}, output={output:08b}, expected={expected:08b}"
        )
