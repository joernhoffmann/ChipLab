# SPDX-License-Identifier: Apache-2.0
"""Integration checks for experiment selection and the shared TT interface.

These tests complement the per-experiment truth tables. The compact output
bytes here describe the public interface; teaching examples are expanded in
test_01_basic_gates.py and test_02_boolean_identities.py. Control independence applies only to the currently
implemented combinational experiments, not to future sequential circuits.
"""
import cocotb

from chiplab_helpers import BASIC_GATES, BOOLEAN_IDENTITIES, initialize, sample

# Index = ui_in[1:0] (B,A) or ui_in[2:0] (C,B,A), respectively.
GATE_OUTPUTS = (0xB3, 0x5A, 0x59, 0x8C)
BOOLEAN_OUTPUTS = (0x0F, 0xC3, 0x03, 0xF0, 0x0F, 0xF3, 0x03, 0xF0)


def expected_output(selection, inputs):
    """Return the specified output; unimplemented selection codes produce zero."""
    if selection == BASIC_GATES:
        return GATE_OUTPUTS[inputs & 3]
    if selection == BOOLEAN_IDENTITIES:
        return BOOLEAN_OUTPUTS[inputs & 7]
    return 0


@cocotb.test()
async def test_unused_inputs(dut):
    """Unused input bits must not affect either implemented experiment."""
    initialize(dut)
    for selection in (BASIC_GATES, BOOLEAN_IDENTITIES):
        for inputs in range(256):
            output = await sample(dut, selection, inputs)
            assert output == expected_output(selection, inputs), (
                f"selection={selection:#04x}, inputs={inputs:#04x}, output={output:#04x}"
            )


@cocotb.test()
async def test_selection_and_controls(dut):
    """Cover every selection, A/B/C combination, and clock/reset/enable state.

    This catches partial decoding (e.g. 0x81 aliasing 0x01), retained outputs
    after switching to an invalid code, and unintended control dependencies.
    """
    initialize(dut)
    for selection in range(256):
        for inputs in range(8):
            for controls in range(8):
                dut.clk.value = controls & 1
                dut.rst_n.value = (controls >> 1) & 1
                dut.ena.value = (controls >> 2) & 1
                output = await sample(dut, selection, inputs)
                assert output == expected_output(selection, inputs), (
                    f"selection={selection:#04x}, inputs={inputs:#04x}, "
                    f"ena/rst_n/clk={controls:03b}, output={output:#04x}"
                )
