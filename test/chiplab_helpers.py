# SPDX-License-Identifier: Apache-2.0
"""Shared pin-level operations for ChipLab's cocotb experiments.

Only public TT ports are accessed, so the tests also work with a gate-level
netlist. The settling interval is a functional simulation delay, not a measured
propagation delay or a timing specification.
"""
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

BASIC_GATES = 0x01
BOOLEAN_IDENTITIES = 0x02
MULTIPLEXER = 0x03
DEMULTIPLEXER = 0x04
BINARY_DECODER = 0x05
ENCODER = 0x06
PRIORITY_ENCODER = 0x07
DUAL_PRIORITY = 0x08
BCD_DECODER = 0x09
HEX_DECODER = 0x0A
GRAY_CODE = 0x0B
PARITY = 0x0C
ROM = 0x0D
HALF_ADDER = 0x0E
FULL_ADDER = 0x0F
ADDER_4BIT = 0x10
SUBTRACTOR_4BIT = 0x11
UNSIGNED_COMPARATOR = 0x12
SIGNED_COMPARATOR = 0x13
SHIFTS = 0x14
ROTATION = 0x15
ALU = 0x16
SR_LATCH = 0x17
D_LATCH = 0x18
D_FLIPFLOP = 0x19
T_FLIPFLOP = 0x1A
JK_FLIPFLOP = 0x1B
LATCH_FLIPFLOP = 0x1C
RESET = 0x1D
REGISTER_ENABLE = 0x1E
REGISTER_CONTROL = 0x1F
MEMORY = 0x20
ACCUMULATOR = 0x21
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


async def start_and_reset(dut):
    """Start the 50 MHz test clock and apply an asynchronous reset."""
    initialize(dut)
    cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())
    dut.rst_n.value = 0
    await Timer(2, unit="ns")
    dut.rst_n.value = 1


async def clock_input(dut, selection, inputs, operation=0):
    """Apply inputs, wait for a rising edge, and return the output."""
    dut.uio_in.value = selection | (operation << 6)
    dut.ui_in.value = inputs
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    return int(dut.uo_out.value)


async def sample(dut, selection, inputs, operation=0):
    """Apply selection and input bytes, settle, and return the output byte."""
    dut.uio_in.value = selection | (operation << 6)
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
