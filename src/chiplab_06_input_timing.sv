// SPDX-License-Identifier: Apache-2.0
`default_nettype none
`include "chiplab_experiments.svh"

module chiplab_06_input_timing (
    input wire clk,
    input wire rst_n,
    input wire [5:0] selection,
    input wire [7:0] data,
    output wire [7:0] edge_result,
    output wire [7:0] synchronizer_result,
    output wire [7:0] debounce_result,
    output wire [7:0] divider_result,
    output wire [7:0] pwm_result
);
    wire select_edge     = selection == `EXP_EDGE_DETECTION;
    wire select_sync     = selection == `EXP_SYNCHRONIZER;
    wire select_debounce = selection == `EXP_DEBOUNCER;
    wire select_divider  = selection == `EXP_CLOCK_ENABLE;
    wire select_pwm      = selection == `EXP_PWM;

    wire signal_in       = data[0];

    // ------------------------------------------------------------------------
    // Experiment 44: Edge detection
    // Sample a synchronous input; bits 0 and 1 pulse on rising and falling edges.
    // ------------------------------------------------------------------------
    logic previous_input, rise_pulse, fall_pulse;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            previous_input <= 1'b0;
            rise_pulse <= 1'b0;
            fall_pulse <= 1'b0;
        end

        else if (select_edge) begin
            rise_pulse <= signal_in && !previous_input;
            fall_pulse <= !signal_in && previous_input;
            previous_input <= signal_in;
        end
    end
    assign edge_result = {5'b0, previous_input, fall_pulse, rise_pulse};


    // ------------------------------------------------------------------------
    // Experiment 45: Input synchronizer
    // Two flip-flops sample an asynchronous input; use only the second stage.
    // ------------------------------------------------------------------------
    (* async_reg = "true" *) logic sync_first, sync_second;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_first <= 1'b0;
            sync_second <= 1'b0;
        end else if (select_sync) begin
            sync_first <= signal_in;
            sync_second <= sync_first;
        end
    end
    assign synchronizer_result = {7'b0, sync_second};


    // ------------------------------------------------------------------------
    // Experiment 46: Push-button debouncer
    // After synchronization, accept a changed level after four equal samples.
    // ------------------------------------------------------------------------
    (* async_reg = "true" *) logic button_first, button_sync;
    logic button_value;
    logic [1:0] stable_count;
    localparam [1:0] LAST_SAMPLE = 2'd3;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            button_first <= 1'b0;
            button_sync  <= 1'b0;
            button_value <= 1'b0;
            stable_count <= 2'b0;
        end

        else if (select_debounce) begin
            button_first <= signal_in;
            button_sync  <= button_first;

            if (button_sync == button_value)
                stable_count <= 2'b0;

            else if (stable_count == LAST_SAMPLE) begin
                button_value <= button_sync;
                stable_count <= 2'b0;

            end else
                stable_count <= stable_count + 2'd1;
        end
    end

    assign debounce_result = {4'b0, stable_count, button_sync, button_value};


    // ------------------------------------------------------------------------
    // Experiment 47: Clock enable divider
    // Divider generates a tick every limit + 1 enabled clocks.
    // The divider runs synchronously with the main clock.
    // ------------------------------------------------------------------------
    logic [3:0] divider_count;
    logic tick;

    wire divider_enable      = data[4];
    wire [3:0] divider_limit = data[3:0];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            divider_count <= 4'b0;
            tick <= 1'b0;
        end

        else if (select_divider) begin
            tick <= 1'b0;

            if (divider_enable) begin
                if (divider_count >= divider_limit) begin
                    divider_count <= 4'b0;
                    tick <= 1'b1;
                end

                else
                    divider_count <= divider_count + 4'd1;
            end
        end
    end

    assign divider_result = {3'b0, divider_count, tick};


    // ------------------------------------------------------------------------
    // Experiment 48: PWM
    // A 16-clock period
    //  - duty 0    : off
    //  - duty >=16 : fully on
    // ------------------------------------------------------------------------
    wire pwm_enable = data[5];
    wire [4:0] duty = data[4:0];
    logic [3:0] pwm_phase;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pwm_phase <= 4'b0;

        else if (select_pwm && pwm_enable)
            pwm_phase <= pwm_phase + 4'd1;
    end

    wire pwm_out = select_pwm && pwm_enable && ({1'b0, pwm_phase} < duty);
    assign pwm_result = {3'b0, pwm_phase, pwm_out};

    wire _unused = &{data[7:6], 1'b0};
endmodule
