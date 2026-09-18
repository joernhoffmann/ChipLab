# SPDX-License-Identifier: Apache-2.0
"""Experiment 1: basic gates (selection 0x01).

A is ui_in[0], B is ui_in[1]; the remaining input bits are unused.
The truth table lists each output explicitly, independently of the RTL.
"""
import cocotb

from chiplab_helpers import BASIC_GATES, check_bit, initialize, sample


# Columns: A, B, NOT A, NOT B, AND, OR, NAND, NOR, XOR, XNOR.
# The eight result columns correspond to uo_out[0] through uo_out[7].
GATE_ROWS = (
    (0, 0, 1, 1, 0, 0, 1, 1, 0, 1),
    (0, 1, 1, 0, 0, 1, 1, 0, 1, 0),
    (1, 0, 0, 1, 0, 1, 1, 0, 1, 0),
    (1, 1, 0, 0, 1, 1, 0, 0, 0, 1),
)
GATE_NAMES = ("NOT A", "NOT B", "AND", "OR", "NAND", "NOR", "XOR", "XNOR")


@cocotb.test()
async def test_basic_gates(dut):
    """Experiment 1: verify all eight gate outputs for all four input pairs."""
    initialize(dut)
    for a, b, *expected in GATE_ROWS:
        inputs = a | (b << 1)
        output = await sample(dut, BASIC_GATES, inputs)
        for bit, (name, value) in enumerate(zip(GATE_NAMES, expected)):
            check_bit(output, bit, value, name, inputs)
