# SPDX-License-Identifier: Apache-2.0
"""Shared pin-level operations for ChipLab's cocotb experiments.

Only public TT ports are accessed, so the tests also work with a gate-level
netlist. The settling interval is a functional simulation delay, not a measured
propagation delay or a timing specification.
"""
from cocotb.triggers import Timer

BASIC_GATES = 0x01
BOOLEAN_IDENTITIES = 0x02
SETTLE_NS = 10


def initialize(dut):
    """Select no experiment and drive every input to a known state.

    No clock generator is needed for the combinational experiments. Later
    sequential experiments must supply their own clock and reset sequence.
    """
    dut.ena.value = 1
    dut.clk.value = 0
    dut.rst_n.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0


async def sample(dut, selection, inputs):
    """Apply selection and input bytes, settle, and return the output byte."""
    dut.uio_in.value = selection
    dut.ui_in.value = inputs
    await Timer(SETTLE_NS, unit="ns")
    context = f"selection=0x{selection:02X}, inputs=0x{inputs:02X}"
    assert int(dut.uio_oe.value) == 0, f"Selection pins must remain inputs: {context}"
    assert int(dut.uio_out.value) == 0, f"Unused IO output bus must be zero: {context}"
    return int(dut.uo_out.value)


def check_bit(output, bit, expected, expression, inputs):
    """Report the exact output function and inputs when a truth-table row fails."""
    actual = (output >> bit) & 1
    assert actual == expected, (
        f"{expression}: ui_in=0x{inputs:02X}, uo_out[{bit}]={actual}, "
        f"expected {expected} (uo_out=0x{output:02X})"
    )
