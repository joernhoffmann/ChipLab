# SPDX-License-Identifier: Apache-2.0
"""Experiment 4: Route ui_in[0] to one of four outputs."""
import cocotb

from chiplab_helpers import DEMULTIPLEXER, initialize, sample


@cocotb.test()
async def test_demultiplexer(dut):
    """Check all input bytes, including unused bits and invalid inputs."""
    initialize(dut)
    for inputs in range(256):
        # ui_in[2:1] selects the output.
        selected = (inputs >> 1) & 3
        expected = sum((inputs & 1) << bit for bit in range(4) if bit == selected)

        output = await sample(dut, DEMULTIPLEXER, inputs)
        assert output == expected, (
            f"input={inputs:08b}, output={output:08b}, expected={expected:08b}"
        )
