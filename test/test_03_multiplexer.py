# SPDX-License-Identifier: Apache-2.0
"""Experiment 3: Select one of four data bits with ui_in[5:4]."""
import cocotb
from chiplab_helpers import MULTIPLEXER, initialize, sample

@cocotb.test()
async def test_multiplexer(dut):
    """Check all input bytes, including unused bits and invalid inputs."""
    initialize(dut)
    for inputs in range(256):
        # The multiplexer selects one of the four data bits (ui_in[3:0]) based on the selector bits (ui_in[5:4]).
        channels = [(inputs >> bit) & 1 for bit in range(4)]
        expected = channels[(inputs >> 4) & 3]

        output = await sample(dut, MULTIPLEXER, inputs)
        assert output == expected, (
            f"input={inputs:08b}, output={output:08b}, expected={expected:08b}"
        )
