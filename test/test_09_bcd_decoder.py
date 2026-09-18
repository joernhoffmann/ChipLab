# SPDX-License-Identifier: Apache-2.0
"""Experiment 9: Decode decimal digits; values 10 through 15 blank the display."""
import cocotb

from chiplab_helpers import BCD_DECODER, initialize, sample


# Lit segments for digits 0 through 9; output bits 0..6 mean a..g.
DIGITS = ("abcdef",     # 0
          "bc",         # 1
          "abdeg",      # 2
          "abcdg",      # 3
          "bcfg",       # 4
          "acdfg",      # 5
          "acdefg",     # 6
          "abc",        # 7
          "abcdefg",    # 8
          "abcdfg"      # 9
                        # 10..15 are blank
)


@cocotb.test()
async def test_bcd_decoder(dut):
    """Check all input bytes, including unused bits and invalid inputs."""
    initialize(dut)
    for inputs in range(256):
        # The BCD decoder should only display digits 0 through 9.
        # For inputs 10 through 15, the display should be blank (no segments lit).
        digit = inputs & 15
        lit = DIGITS[digit] if digit < 10 else ""
        expected = sum(1 << bit for bit, name in enumerate("abcdefg") if name in lit)

        output = await sample(dut, BCD_DECODER, inputs)
        assert output == expected, (
            f"input={inputs:08b}, output={output:08b}, expected={expected:08b}"
        )
