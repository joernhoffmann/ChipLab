# SPDX-License-Identifier: Apache-2.0
"""Experiment 13: Read the zero-terminated ASCII string ChipLab using ui_in[2:0]."""
import cocotb
from chiplab_helpers import ROM, initialize, sample

# The ROM is initialized with the ASCII string "ChipLab\0" at addresses 0 through 7.
WORDS = b"ChipLab\0"

@cocotb.test()
async def test_rom(dut):
    """Check all eight addresses and all combinations of unused input bits."""
    initialize(dut)
    for inputs in range(256):
        # The ROM takes a 3-bit address (ui_in[2:0]) and outputs the corresponding ASCII character from the string "ChipLab\0".       
        expected = WORDS[inputs & 7]
        output = await sample(dut, ROM, inputs)

        assert output == expected, (
            f"input={inputs:08b}, output={output:08b}, expected={expected:08b}"
        )
