// SPDX-License-Identifier: Apache-2.0
`default_nettype none
`include "chiplab_experiments.svh"

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
        .accumulator_selected(uio_in[5:0] == `EXP_ACCUMULATOR),
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
    wire [7:0] fifo_result;
    wire [7:0] stack_result;
    chiplab_04_storage_memory storage_memory (
        .operation(uio_in[7:6]),
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
        .accumulator_result(accumulator_result),
        .fifo_result(fifo_result),
        .stack_result(stack_result)
    );

    // --------------------------------------------------------------------
    // Group 5: Shift Registers and Counters
    // --------------------------------------------------------------------
    wire [7:0] shift_register_result;
    wire [7:0] universal_shift_register_result;
    wire [7:0] binary_counter_result;
    wire [7:0] up_down_counter_result;
    wire [7:0] modulo_counter_result;
    wire [7:0] bcd_counter_result;
    wire [7:0] ring_counter_result;
    wire [7:0] johnson_counter_result;
    wire [7:0] lfsr_result;
    chiplab_05_shift_counters shift_counters (
        .clk(clk),
        .rst_n(rst_n),
        .selection(uio_in[5:0]),
        .operation(uio_in[7:6]),
        .data(ui_in),
        .shift_register_result(shift_register_result),
        .universal_shift_register_result(universal_shift_register_result),
        .binary_counter_result(binary_counter_result),
        .up_down_counter_result(up_down_counter_result),
        .modulo_counter_result(modulo_counter_result),
        .bcd_counter_result(bcd_counter_result),
        .ring_counter_result(ring_counter_result),
        .johnson_counter_result(johnson_counter_result),
        .lfsr_result(lfsr_result)
    );

    // ------------------------------------------------------------------------
    // Group 6: Input Synchronization and Timing
    // ------------------------------------------------------------------------
    wire [7:0] edge_result;
    wire [7:0] synchronizer_result;
    wire [7:0] debounce_result;
    wire [7:0] divider_result;
    wire [7:0] pwm_result;
    chiplab_06_input_timing input_timing (
        .clk(clk), .rst_n(rst_n),
        .selection(uio_in[5:0]), .data(ui_in),
        .edge_result(edge_result),
        .synchronizer_result(synchronizer_result),
        .debounce_result(debounce_result),
        .divider_result(divider_result),
        .pwm_result(pwm_result)
    );

    // ------------------------------------------------------------------------
    // Group 7: Finite State Machines
    // ------------------------------------------------------------------------
    wire [7:0] moore_result;
    wire [7:0] mealy_result;
    wire [7:0] traffic_result;
    wire [7:0] handshake_result;
    wire [7:0] parking_result;
    chiplab_07_state_machines state_machines (
        .clk(clk), .rst_n(rst_n),
        .selection(uio_in[5:0]), .data(ui_in),
        .moore_result(moore_result),
        .mealy_result(mealy_result),
        .traffic_result(traffic_result),
        .handshake_result(handshake_result),
        .parking_result(parking_result)
    );

    // ------------------------------------------------------------------------
    // Group 8: FSM-Controlled Datapaths
    // ------------------------------------------------------------------------
    wire [7:0] multiplier_result;
    chiplab_08_fsm_datapaths fsm_datapaths (
        .clk(clk), .rst_n(rst_n),
        .selection(uio_in[5:0]), .data(ui_in),
        .operation(uio_in[7:6]),
        .multiplier_result(multiplier_result)
    );

    // ------------------------------------------------------------------------
    // Group 9: Sound
    // ------------------------------------------------------------------------
    wire [7:0] psg_result;
    chiplab_09_sound sound (
        .clk(clk), .rst_n(rst_n), .selection(uio_in[5:0]),
        .operation(uio_in[7:6]), .data(ui_in), .psg_result(psg_result)
    );

    // ------------------------------------------------------------------------
    // Main experiment selection
    // ------------------------------------------------------------------------
    always_comb begin
        case (uio_in[5:0])
            `EXP_BASIC_GATES: uo_out = gates;
            `EXP_BOOLEAN_IDENTITIES: uo_out = boolean_laws;
            `EXP_MULTIPLEXER: uo_out = mux_result;
            `EXP_DEMULTIPLEXER: uo_out = demux_result;
            `EXP_BINARY_DECODER: uo_out = decoder_result;
            `EXP_ENCODER: uo_out = encoder_result;
            `EXP_PRIORITY_ENCODER: uo_out = priority_result;
            `EXP_DUAL_PRIORITY: uo_out = dual_priority;
            `EXP_BCD_DECODER: uo_out = bcd_segments;
            `EXP_HEX_DECODER: uo_out = hex_segments;
            `EXP_GRAY_CODE: uo_out = gray_result;
            `EXP_PARITY: uo_out = parity_result;
            `EXP_ROM: uo_out = rom_result;
            `EXP_HALF_ADDER: uo_out = half_adder_result;
            `EXP_FULL_ADDER: uo_out = full_adder_result;
            `EXP_ADDER_4BIT: uo_out = adder_result;
            `EXP_SUBTRACTOR_4BIT: uo_out = subtractor_result;
            `EXP_UNSIGNED_COMPARATOR: uo_out = unsigned_compare_result;
            `EXP_SIGNED_COMPARATOR: uo_out = signed_compare_result;
            `EXP_SHIFTS: uo_out = shift_result;
            `EXP_ROTATION: uo_out = rotate_result;
            `EXP_ALU: uo_out = alu_result;
            `EXP_SR_LATCH: uo_out = sr_latch_result;
            `EXP_D_LATCH: uo_out = d_latch_result;
            `EXP_D_FLIPFLOP: uo_out = d_flipflop_result;
            `EXP_T_FLIPFLOP: uo_out = t_ff_result;
            `EXP_JK_FLIPFLOP: uo_out = jk_ff_result;
            `EXP_LATCH_FLIPFLOP: uo_out = latch_ff_result;
            `EXP_RESET: uo_out = reset_result;
            `EXP_REGISTER_ENABLE: uo_out = register_enable_result;
            `EXP_REGISTER_CONTROL: uo_out = register_control_result;
            `EXP_MEMORY: uo_out = memory_result;
            `EXP_ACCUMULATOR: uo_out = accumulator_result;
            `EXP_FIFO: uo_out = fifo_result;
            `EXP_STACK: uo_out = stack_result;
            `EXP_SHIFT_REGISTER: uo_out = shift_register_result;
            `EXP_UNIVERSAL_SHIFT_REGISTER: uo_out = universal_shift_register_result;
            `EXP_BINARY_COUNTER: uo_out = binary_counter_result;
            `EXP_UP_DOWN_COUNTER: uo_out = up_down_counter_result;
            `EXP_MODULO_COUNTER: uo_out = modulo_counter_result;
            `EXP_BCD_COUNTER: uo_out = bcd_counter_result;
            `EXP_RING_COUNTER: uo_out = ring_counter_result;
            `EXP_JOHNSON_COUNTER: uo_out = johnson_counter_result;
            `EXP_LFSR: uo_out = lfsr_result;
            `EXP_EDGE_DETECTION: uo_out = edge_result;
            `EXP_SYNCHRONIZER: uo_out = synchronizer_result;
            `EXP_DEBOUNCER: uo_out = debounce_result;
            `EXP_CLOCK_ENABLE: uo_out = divider_result;
            `EXP_PWM: uo_out = pwm_result;
            `EXP_MOORE_CONTROL: uo_out = moore_result;
            `EXP_MEALY_CONTROL: uo_out = mealy_result;
            `EXP_TRAFFIC_LIGHT: uo_out = traffic_result;
            `EXP_HANDSHAKE: uo_out = handshake_result;
            `EXP_PARKING_COUNTER: uo_out = parking_result;
            `EXP_MULTIPLIER: uo_out = multiplier_result;
            `EXP_PSG: uo_out = psg_result;
            default: uo_out = 8'b0;
        endcase
    end

    // All bidirectional pins are experiment-selection inputs.
    assign uio_out = 8'b0;
    assign uio_oe = 8'b0;

    // Tiny Tapeout enable does not change an experiment's internal behavior.
    wire _unused = &{ena, 1'b0};
endmodule
