// SPDX-License-Identifier: Apache-2.0
`default_nettype none

module tt_um_chiplab (
    input  wire [7:0] ui_in,
    output logic [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);
    wire [7:0] gates;
    wire [7:0] boolean_laws;

    chiplab_01_basic_boolean basic_boolean (
        .a(ui_in[0]),
        .b(ui_in[1]),
        .c(ui_in[2]),
        .gates(gates),
        .boolean_laws(boolean_laws)
    );

    // Main experiment selection
    always_comb begin
        case (uio_in)
            8'h01: uo_out = gates;
            8'h02: uo_out = boolean_laws;
            default: uo_out = 8'b0;
        endcase
    end

    // All bidirectional pins are experiment-selection inputs.
    assign uio_out = 8'b0;
    assign uio_oe = 8'b0;

    // Currently, combinational experiments do not use clock, reset, or enable.
    wire _unused = &{ui_in[7:3], ena, clk, rst_n, 1'b0};
endmodule
