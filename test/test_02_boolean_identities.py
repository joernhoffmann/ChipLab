# SPDX-License-Identifier: Apache-2.0
"""Experiment 2: Boolean identities (selection 0x02).

A, B, and C are ui_in[0], ui_in[1], and ui_in[2]. C is needed for
distributivity; the other identities are independent of C. Each identity
has a separate test with expected values taken from an explicit truth table.
Adjacent output bits represent the two sides of the identity.
"""
import cocotb
from chiplab_helpers import BOOLEAN_IDENTITIES, check_bit, initialize, sample

async def check_identity(dut, bits, expressions, rows):
    """Check each side against a truth table, not just against the other side.

    Each row contains A, B, C, and the expected value of both expressions.
    Checking the expected value prevents two equally incorrect outputs passing.
    """
    initialize(dut)
    for a, b, c, expected in rows:
        inputs = a | (b << 1) | (c << 2)
        output = await sample(dut, BOOLEAN_IDENTITIES, inputs)
        for bit, expression in zip(bits, expressions):
            check_bit(output, bit, expected, expression, inputs)

@cocotb.test()
async def test_de_morgan_nand(dut):
    """Experiment 2: NOT(A AND B) = (NOT A) OR (NOT B), outputs 0 and 1."""
    rows = [(a, b, c, value) for a, b, value in
            (
                # A, B, expected
                (0, 0, 1), 
                (0, 1, 1), 
                (1, 0, 1), 
                (1, 1, 0)
            ) for c in (0, 1)]
    await check_identity(dut, (0, 1), ("NOT(A AND B)", "(NOT A) OR (NOT B)"), rows)


@cocotb.test()
async def test_de_morgan_nor(dut):
    """Experiment 2: NOT(A OR B) = (NOT A) AND (NOT B), outputs 2 and 3."""
    rows = [(a, b, c, value) for a, b, value in
            (
                # A, B, expected
                (0, 0, 1), 
                (0, 1, 0), 
                (1, 0, 0), 
                (1, 1, 0)
            ) for c in (0, 1)]
    await check_identity(dut, (2, 3), ("NOT(A OR B)", "(NOT A) AND (NOT B)"), rows)


@cocotb.test()
async def test_distributivity(dut):
    """Experiment 2: A AND (B OR C) = (A AND B) OR (A AND C), outputs 4 and 5."""
    rows = (
        # A, B, C, expected
        (0, 0, 0, 0), 
        (0, 0, 1, 0), 
        (0, 1, 0, 0), 
        (0, 1, 1, 0), 
        (1, 0, 0, 0), 
        (1, 0, 1, 1), 
        (1, 1, 0, 1), 
        (1, 1, 1, 1)
    )
    await check_identity(dut, (4, 5), ("A AND (B OR C)", "(A AND B) OR (A AND C)"), rows)


@cocotb.test()
async def test_absorption(dut):
    """Experiment 2: A OR (A AND B) = A, outputs 6 and 7."""
    rows = [(a, b, c, value) for a, b, value in
            (
                # A, B, expected
                (0, 0, 0), 
                (0, 1, 0), 
                (1, 0, 1), 
                (1, 1, 1)
            ) for c in (0, 1)]
    await check_identity(dut, (6, 7), ("A OR (A AND B)", "A"), rows)
