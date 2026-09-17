// SPDX-License-Identifier: Apache-2.0
`default_nettype none

module chiplab_01_basic_boolean (
    input  wire a,
    input  wire b,
    input  wire c,
    output wire [7:0] gates,
    output wire [7:0] boolean_laws
);
    // Boolean gates
    assign gates[0] = ~a;           // NOT a
    assign gates[1] = ~b;           // NOT b
    assign gates[2] = a & b;        // a AND b
    assign gates[3] = a | b;        // a OR b
    assign gates[4] = ~(a & b);     // a NAND b
    assign gates[5] = ~(a | b);     // a NOR b
    assign gates[6] = a ^ b;        // a XOR b
    assign gates[7] = ~(a ^ b);     // a XNOR b
    
    // De Morgan: each adjacent pair represents equivalent expressions.
    assign boolean_laws[0] = ~(a & b);
    assign boolean_laws[1] = ~a | ~b;
    assign boolean_laws[2] = ~(a | b);
    assign boolean_laws[3] = ~a & ~b;

    // Distributivity.
    assign boolean_laws[4] = a & (b | c);
    assign boolean_laws[5] = (a & b) | (a & c);
    
    // Absorption.
    assign boolean_laws[6] = a | (a & b);
    assign boolean_laws[7] = a;
endmodule
