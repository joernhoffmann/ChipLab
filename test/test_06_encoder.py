# SPDX-License-Identifier: Apache-2.0
"""Experiment 6: Encode one-hot input; zero or multiple bits are invalid."""
import cocotb

from chiplab_helpers import ENCODER, initialize, sample


@cocotb.test()
async def test_encoder(dut):
    """Check all input bytes, including unused bits and invalid inputs."""
    initialize(dut)
    for inputs in range(256):
        # Encode exactly one set bit. Bit 3 marks a valid result.
        matches = [bit for bit in range(8) if inputs & (1 << bit)]
        expected = (8 | matches[0]) if len(matches) == 1 else 0

        output = await sample(dut, ENCODER, inputs)
        assert output == expected, (
            f"input={inputs:08b}, output={output:08b}, expected={expected:08b}"
        )
