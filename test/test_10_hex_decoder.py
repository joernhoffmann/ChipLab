# SPDX-License-Identifier: Apache-2.0
"""Experiment 10: Decode hexadecimal digits using active-high segments."""
import cocotb

from chiplab_helpers import HEX_DECODER, initialize, sample


# Digits 0 .. 9, A, b, C, d, E and F.
# Bit 0 is segment a, bit 1 is segment b, ..., bit 6 is segment g.
# Bit 7 is unused and always zero.
# The segments are active-high, so a lit segment is represented by a 1.
DIGITS = ("abcdef",     # 0
          "bc",         # 1
          "abdeg",      # 2
          "abcdg",      # 3
          "bcfg",       # 4
          "acdfg",      # 5
          "acdefg",     # 6
          "abc",        # 7
          "abcdefg",    # 8
          "abcdfg",     # 9
          "abcefg",     # A
          "cdefg",      # b
          "adef",       # C
          "bcdeg",      # d
          "adefg",      # E
          "aefg")       # F


@cocotb.test()
async def test_hex_decoder(dut):
    """Check all input bytes, including unused bits and invalid inputs."""
    initialize(dut)
    for inputs in range(256):
        # The hex decoder should display digits 0 through F.
        lit = DIGITS[inputs & 15]
        expected = sum(1 << bit for bit, name in enumerate("abcdefg") if name in lit)

        output = await sample(dut, HEX_DECODER, inputs)
        assert output == expected, (
            f"input={inputs:08b}, output={output:08b}, expected={expected:08b}"
        )
