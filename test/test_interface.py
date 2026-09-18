# SPDX-License-Identifier: Apache-2.0
"""Shared checks for selection, IO direction, and control signals."""
import cocotb

from chiplab_helpers import initialize, sample

COMBINATIONAL = range(1, 23)


@cocotb.test()
async def test_selection_and_controls(dut):
    """Unassigned codes return zero; controls do not change combinational logic.

    Per-experiment tests check the actual output values for every input byte.
    Here a settled result is the reference for each control combination.
    """
    initialize(dut)
    for selection in list(COMBINATIONAL) + list(range(34, 64)):
        for operation in range(4):
            for inputs in (0, 1, 7, 0x35, 0x80, 0xB4, 0xFF):
                dut.clk.value = 0
                dut.rst_n.value = 1
                dut.ena.value = 1
                reference = await sample(dut, selection, inputs, operation)
                if selection not in COMBINATIONAL:
                    assert reference == 0
                for controls in range(8):
                    dut.clk.value = controls & 1
                    dut.rst_n.value = (controls >> 1) & 1
                    dut.ena.value = (controls >> 2) & 1
                    output = await sample(dut, selection, inputs, operation)
                    assert output == reference


@cocotb.test()
async def test_switching_experiments(dut):
    """Switch to zero and back to catch retained outputs or hidden state."""
    initialize(dut)
    for selection in COMBINATIONAL:
        for operation in range(4):
            for inputs in (0, 1, 0x55, 0xFF):
                reference = await sample(dut, selection, inputs, operation)
                assert await sample(dut, 0, inputs, operation) == 0
                assert await sample(dut, selection, inputs, operation) == reference


@cocotb.test()
async def test_basic_unused_inputs(dut):
    """Keep full-byte coverage for the first two experiments as well."""
    initialize(dut)
    gates = (0xB3, 0x5A, 0x59, 0x8C)
    identities = (0x0F, 0xC3, 0x03, 0xF0, 0x0F, 0xF3, 0x03, 0xF0)
    for inputs in range(256):
        assert await sample(dut, 1, inputs) == gates[inputs & 3]
        assert await sample(dut, 2, inputs) == identities[inputs & 7]
