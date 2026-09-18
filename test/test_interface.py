# SPDX-License-Identifier: Apache-2.0
"""Shared checks for selection, IO direction, and control signals."""
import cocotb

from chiplab_helpers import initialize, sample

IMPLEMENTED = range(1, 14)


@cocotb.test()
async def test_selection_and_controls(dut):
    """Unassigned codes return zero; clock, reset, and enable have no effect.

    Per-experiment tests check the actual output values for every input byte.
    Here a settled result is the reference for each control combination.
    """
    initialize(dut)
    for selection in range(256):
        for inputs in (0, 1, 7, 0x35, 0x80, 0xB4, 0xFF):
            dut.clk.value = 0
            dut.rst_n.value = 1
            dut.ena.value = 1
            reference = await sample(dut, selection, inputs)
            if selection not in IMPLEMENTED:
                assert reference == 0, f"Unassigned code {selection:#04x} returned {reference:#04x}"
            for controls in range(8):
                dut.clk.value = controls & 1
                dut.rst_n.value = (controls >> 1) & 1
                dut.ena.value = (controls >> 2) & 1
                output = await sample(dut, selection, inputs)
                assert output == reference, (
                    f"selection={selection:#04x}, input={inputs:#04x}, "
                    f"ena/rst_n/clk={controls:03b}, output={output:#04x}"
                )


@cocotb.test()
async def test_switching_experiments(dut):
    """Switch to zero and back to catch retained outputs or hidden state."""
    initialize(dut)
    for selection in IMPLEMENTED:
        for inputs in (0, 1, 0x55, 0xFF):
            reference = await sample(dut, selection, inputs)
            assert await sample(dut, 0, inputs) == 0
            assert await sample(dut, selection, inputs) == reference


@cocotb.test()
async def test_basic_unused_inputs(dut):
    """Keep full-byte coverage for the first two experiments as well."""
    initialize(dut)
    gates = (0xB3, 0x5A, 0x59, 0x8C)
    identities = (0x0F, 0xC3, 0x03, 0xF0, 0x0F, 0xF3, 0x03, 0xF0)
    for inputs in range(256):
        assert await sample(dut, 1, inputs) == gates[inputs & 3]
        assert await sample(dut, 2, inputs) == identities[inputs & 7]
