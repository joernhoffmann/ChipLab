# SPDX-License-Identifier: Apache-2.0
"""Experiment 5: Decode ui_in[2:0] into one of eight outputs."""
import cocotb

from chiplab_helpers import BINARY_DECODER, initialize, sample


# One-hot output for each 3-bit input.
ONE_HOT = (1, 2, 4, 8, 16, 32, 64, 128)


@cocotb.test()
async def test_binary_decoder(dut):
    """Check all input bytes, including unused bits and invalid inputs."""
    initialize(dut)
    for inputs in range(256):
        # The upper five input bits are ignored.
        expected = ONE_HOT[inputs & 7]

        output = await sample(dut, BINARY_DECODER, inputs)
        assert output == expected, (
            f"input={inputs:08b}, output={output:08b}, expected={expected:08b}"
        )
