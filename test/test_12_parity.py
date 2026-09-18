# SPDX-License-Identifier: Apache-2.0
"""Experiment 12: Generate even parity and check the received parity bit at ui_in[7]."""
import cocotb
from chiplab_helpers import PARITY, initialize, sample

@cocotb.test()
async def test_parity(dut):
    """Check all input bytes, including unused bits and invalid inputs."""
    initialize(dut)
    for inputs in range(256):
        # The parity generator takes the lower 7 bits of the input (ui_in[6:0]) and generates an even parity bit at ui_in[7].
        generated = (inputs & 127).bit_count() % 2
        error = inputs.bit_count() % 2
        expected = generated | (error << 1)

        output = await sample(dut, PARITY, inputs)
        assert output == expected, (
            f"input={inputs:08b}, output={output:08b}, expected={expected:08b}"
        )
