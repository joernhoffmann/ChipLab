// SPDX-License-Identifier: Apache-2.0
`default_nettype none

module chiplab_01_basic_boolean (
    input  wire a,
    input  wire b,
    input  wire c,
    output wire [7:0] gates,
    output wire [7:0] boolean_laws
);


    // ------------------------------------------------------------------------
    // Experiment 1: Basic gates
    // Apply basic boolean operations to inputs a and b.
    // ------------------------------------------------------------------------
    assign gates[0] = ~a;           // NOT  (a)
    assign gates[1] = ~b;           // NOT  (b)
    assign gates[2] =   a & b;      // AND  (a, b)
    assign gates[3] =   a | b;      // OR   (a, b)
    assign gates[4] = ~(a & b);     // NAND (a, b)
    assign gates[5] = ~(a | b);     // NOR  (a, b)
    assign gates[6] =   a ^ b;      // XOR  (a, b)
    assign gates[7] = ~(a ^ b);     // XNOR (a, b)


    // ------------------------------------------------------------------------
    // Experiment 2: Boolean identities
    // Apply De Morgan's, distributivity, and absorption laws to inputs a, b, and c.
    // ------------------------------------------------------------------------

    // De Morgan's Laws
    assign boolean_laws[0] = ~(a & b);
    assign boolean_laws[1] =  ~a | ~b;
    assign boolean_laws[2] = ~(a | b);
    assign boolean_laws[3] =  ~a & ~b;

    // Distributivity Law (c is needed for this law)
    assign boolean_laws[4] = a & (b | c);
    assign boolean_laws[5] = (a & b) | (a & c);
    
    // Absorption Law
    assign boolean_laws[6] = a | (a & b);
    assign boolean_laws[7] = a;
endmodule
