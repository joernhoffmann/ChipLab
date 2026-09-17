# SPDX-License-Identifier: Apache-2.0
import cocotb
from cocotb.triggers import Timer


# Bit 0 is A, bit 1 is B. Entries are complete output truth tables.
GATE_TABLE = [0xB3, 0x5A, 0x59, 0x8C]
# Bit 2 is C. Adjacent output bits must show equal Boolean functions.
BOOLEAN_TABLE = [0x0F, 0xC3, 0x03, 0xF0, 0x0F, 0xF3, 0x03, 0xF0]


def initialize(dut):
    dut.ena.value = 1
    dut.clk.value = 0
    dut.rst_n.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0


@cocotb.test()
async def test_basic_boolean_truth_tables(dut):
    """Cover every input byte, including unused inputs, for both experiments."""
    initialize(dut)
    for selection, table, mask in [(1, GATE_TABLE, 3), (2, BOOLEAN_TABLE, 7)]:
        dut.uio_in.value = selection
        for inputs in range(256):
            dut.ui_in.value = inputs
            await Timer(10, unit="ns")
            assert int(dut.uo_out.value) == table[inputs & mask], (
                f"selection={selection}, inputs={inputs:#04x}"
            )
            assert int(dut.uio_oe.value) == 0
            assert int(dut.uio_out.value) == 0


@cocotb.test()
async def test_selection_and_control_inputs(dut):
    """Check full selection decoding and clock/reset/enable independence."""
    initialize(dut)
    for selection in range(256):
        dut.uio_in.value = selection
        for inputs in range(8):
            dut.ui_in.value = inputs
            expected = (GATE_TABLE[inputs & 3] if selection == 1 else
                        BOOLEAN_TABLE[inputs] if selection == 2 else 0)
            for controls in range(8):
                dut.clk.value = controls & 1
                dut.rst_n.value = (controls >> 1) & 1
                dut.ena.value = (controls >> 2) & 1
                await Timer(10, unit="ns")
                assert int(dut.uo_out.value) == expected
                assert int(dut.uio_oe.value) == 0
                assert int(dut.uio_out.value) == 0
