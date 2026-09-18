# SPDX-License-Identifier: Apache-2.0
"""Experiment 8: find the two highest set bits in ui_in[7:0]."""
import cocotb

from chiplab_helpers import DUAL_PRIORITY, initialize, sample


@cocotb.test()
async def test_dual_priority_encoder(dut):
    """Check all 256 inputs, including zero and single-bit inputs."""
    initialize(dut)
    for inputs in range(256):
        # The dual priority encoder takes an input byte and outputs the indices of the two highest set bits.
        positions = sorted((i for i in range(8) if inputs & (1 << i)), reverse=True)
        first = positions[0] if positions else 0
        second = positions[1] if len(positions) > 1 else 0
        expected = first | (bool(positions) << 3) | (second << 4) | ((len(positions) > 1) << 7)

        output = await sample(dut, DUAL_PRIORITY, inputs)
        assert output == expected, (
            f"input={inputs:08b}, matches={positions[:2]}, "
            f"output={output:08b}, expected={expected:08b}"
        )
