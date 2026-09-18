// SPDX-License-Identifier: Apache-2.0
`default_nettype none

module tt_um_chiplab (
    input  wire  [7:0] ui_in,
    output logic [7:0] uo_out,
    input  wire  [7:0] uio_in,
    output wire  [7:0] uio_out,
    output wire  [7:0] uio_oe,
    input  wire        ena,
    input  wire        clk,
    input  wire        rst_n
);
    wire [7:0] gates;
    wire [7:0] boolean_laws;

    // --------------------------------------------------------------------
    // Group 1: Basic Boolean Logic
    // --------------------------------------------------------------------
    chiplab_01_basic_boolean basic_boolean (
        .a(ui_in[0]),
        .b(ui_in[1]),
        .c(ui_in[2]),
        .gates(gates),
        .boolean_laws(boolean_laws)
    );

    // --------------------------------------------------------------------
    // Group 2: Selection and Coding
    // --------------------------------------------------------------------
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

    // --------------------------------------------------------------------
    // Group 3: Arithmetic and Data Manipulation
    // --------------------------------------------------------------------
    wire [7:0] half_adder_result;
    wire [7:0] full_adder_result;
    wire [7:0] adder_result;
    wire [7:0] subtractor_result;
    wire [7:0] unsigned_compare_result;
    wire [7:0] signed_compare_result;
    wire [7:0] shift_result;
    wire [7:0] rotate_result;
    wire [3:0] accumulator_value;
    wire [7:0] alu_result;
    chiplab_03_arithmetic_data arithmetic_data (
        .data(ui_in),
        .operation(uio_in[7:6]),
        .accumulator_selected(uio_in[5:0] == 6'd33),
        .accumulator_value(accumulator_value),
        .half_adder_result(half_adder_result),
        .full_adder_result(full_adder_result),
        .adder_result(adder_result),
        .subtractor_result(subtractor_result),
        .unsigned_compare_result(unsigned_compare_result),
        .signed_compare_result(signed_compare_result),
        .shift_result(shift_result),
        .rotate_result(rotate_result),
        .alu_result(alu_result)
    );

    // --------------------------------------------------------------------
    // Group 4: Storage Elements and Memory
    // --------------------------------------------------------------------
    wire [7:0] sr_latch_result;
    wire [7:0] d_latch_result;
    wire [7:0] d_flipflop_result;
    wire [7:0] latch_ff_result;
    wire [7:0] t_ff_result;
    wire [7:0] jk_ff_result;
    wire [7:0] reset_result;
    wire [7:0] register_enable_result;
    wire [7:0] register_control_result;
    wire [7:0] memory_result;
    wire [7:0] accumulator_result;
    chiplab_04_storage_memory storage_memory (
        .clk(clk),
        .rst_n(rst_n),
        .selection(uio_in[5:0]),
        .data(ui_in),
        .alu_result(alu_result),
        .accumulator_value(accumulator_value),
        .sr_latch_result(sr_latch_result),
        .d_latch_result(d_latch_result),
        .d_flipflop_result(d_flipflop_result),
        .latch_ff_result(latch_ff_result),
        .t_ff_result(t_ff_result),
        .jk_ff_result(jk_ff_result),
        .reset_result(reset_result),
        .register_enable_result(register_enable_result),
        .register_control_result(register_control_result),
        .memory_result(memory_result),
        .accumulator_result(accumulator_result)
    );

    // ------------------------------------------------------------------------
    // Main experiment selection
    // ------------------------------------------------------------------------
    always_comb begin
        case (uio_in[5:0])
            6'h01: uo_out = gates;
            6'h02: uo_out = boolean_laws;
            6'h03: uo_out = mux_result;
            6'h04: uo_out = demux_result;
            6'h05: uo_out = decoder_result;
            6'h06: uo_out = encoder_result;
            6'h07: uo_out = priority_result;
            6'h08: uo_out = dual_priority;
            6'h09: uo_out = bcd_segments;
            6'h0A: uo_out = hex_segments;
            6'h0B: uo_out = gray_result;
            6'h0C: uo_out = parity_result;
            6'h0D: uo_out = rom_result;
            6'h0E: uo_out = half_adder_result;
            6'h0F: uo_out = full_adder_result;
            6'h10: uo_out = adder_result;
            6'h11: uo_out = subtractor_result;
            6'h12: uo_out = unsigned_compare_result;
            6'h13: uo_out = signed_compare_result;
            6'h14: uo_out = shift_result;
            6'h15: uo_out = rotate_result;
            6'h16: uo_out = alu_result;
            6'h17: uo_out = sr_latch_result;
            6'h18: uo_out = d_latch_result;
            6'h19: uo_out = d_flipflop_result;
            6'h1A: uo_out = t_ff_result;
            6'h1B: uo_out = jk_ff_result;
            6'h1C: uo_out = latch_ff_result;
            6'h1D: uo_out = reset_result;
            6'h1E: uo_out = register_enable_result;
            6'h1F: uo_out = register_control_result;
            6'h20: uo_out = memory_result;
            6'h21: uo_out = accumulator_result;
            default: uo_out = 8'b0;
        endcase
    end

    // All bidirectional pins are experiment-selection inputs.
    assign uio_out = 8'b0;
    assign uio_oe = 8'b0;

    // Tiny Tapeout enable does not change an experiment's internal behavior.
    wire _unused = &{ena, 1'b0};
endmodule
