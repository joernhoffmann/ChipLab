# SPDX-License-Identifier: Apache-2.0
"""Experiment 7: Encode the highest set bit; output bit 3 marks a valid result."""
import cocotb

from chiplab_helpers import PRIORITY_ENCODER, initialize, sample


@cocotb.test()
async def test_priority_encoder(dut):
    """Check all input bytes, including unused bits and invalid inputs."""
    initialize(dut)
    for inputs in range(256):
        # The priority encoder takes an input byte and outputs the index of the highest set bit.
        # If no bits are set, the output is invalid (0).
        expected = (8 | (inputs.bit_length() - 1)) if inputs else 0

        output = await sample(dut, PRIORITY_ENCODER, inputs)
        assert output == expected, (
            f"input={inputs:08b}, output={output:08b}, expected={expected:08b}"
        )
