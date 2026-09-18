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

    wire [7:0] mux_result;
    wire [7:0] demux_result;
    wire [7:0] decoder_result;
    wire [7:0] encoder_result;
    wire [7:0] priority_result;
    wire [7:0] dual_priority;
    wire [7:0] bcd_segments;
    wire [7:0] hex_segments;
    wire [7:0] gray_result;
    wire [7:0] parity_result;
    wire [7:0] rom_result;
    chiplab_02_selection_coding selection_coding (
        .data(ui_in),
        .mux_result(mux_result),
        .demux_result(demux_result),
        .decoder_result(decoder_result),
        .encoder_result(encoder_result),
        .priority_result(priority_result),
        .dual_priority(dual_priority),
        .bcd_segments(bcd_segments),
        .hex_segments(hex_segments),
        .gray_result(gray_result),
        .parity_result(parity_result),
        .rom_result(rom_result)
    );

    // Main experiment selection
    always_comb begin
        case (uio_in)
            8'h01: uo_out = gates;
            8'h02: uo_out = boolean_laws;
            8'h03: uo_out = mux_result;
            8'h04: uo_out = demux_result;
            8'h05: uo_out = decoder_result;
            8'h06: uo_out = encoder_result;
            8'h07: uo_out = priority_result;
            8'h08: uo_out = dual_priority;
            8'h09: uo_out = bcd_segments;
            8'h0A: uo_out = hex_segments;
            8'h0B: uo_out = gray_result;
            8'h0C: uo_out = parity_result;
            8'h0D: uo_out = rom_result;
            default: uo_out = 8'b0;
        endcase
    end

    // All bidirectional pins are experiment-selection inputs.
    assign uio_out = 8'b0;
    assign uio_oe = 8'b0;

    // Currently, combinational experiments do not use clock, reset, or enable.
    wire _unused = &{ena, clk, rst_n, 1'b0};
endmodule
