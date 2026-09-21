// SPDX-License-Identifier: Apache-2.0
`default_nettype none
`include "chiplab_experiments.svh"

module chiplab_08_fsm_datapaths (
    input wire clk,
    input wire rst_n,
    input wire [5:0] selection,
    input wire [1:0] operation,
    input wire [7:0] data,
    output wire [7:0] multiplier_result
);
    wire selected = selection == `EXP_MULTIPLIER;
    wire start = operation[0];
    wire show_status = operation[1];
    wire [3:0] operand_a = data[3:0];
    wire [3:0] operand_b = data[7:4];


    // ------------------------------------------------------------------------
    // Experiment 54: Sequential multiplier
    // Capture A and B on start, then shift and add over four clock cycles.
    // The multiplication is comparable to the traditional method of multiplying binary numbers by hand.
    // Example:
    //        0010
    //      x 1111
    //  ----------
    //        0010  // Step 1: Multiply LSB of B with A and add to product
    //   +   0010   // Step 2: Multiply next bit of B with A and add to product
    //   +  0010    // Step 3: Multiply next bit of B with A and add to product
    //   + 0010     // Step 4: Multiply MSB of B with A and add to product
    //   ---------
    //    00011110
    // ------------------------------------------------------------------------
    localparam [1:0] 
        STATE_IDLE = 2'd0, 
        STATE_RUN     = 2'd1, 
        STATE_DONE    = 2'd2;
    localparam [2:0] LAST_STEP = 3'd3;
    logic [1:0] state;
    logic [2:0] steps;
    logic [7:0] product, shifted_a;
    logic [3:0] remaining_b;

    // Two separate instances of the group 3 adder module form the 8-bit sum.
    wire [7:0] sum;
    wire low_carry, high_carry, low_overflow, high_overflow;

    // Connect the low adder's carry-out to the high adder's carry-in.
    chiplab_adder_4bit low_adder (
        .a(product[3:0]),
        .b(shifted_a[3:0]),
        .carry_in(1'b0),
        .sum(sum[3:0]),
        .carry_out(low_carry),
        .overflow(low_overflow)
    );
    chiplab_adder_4bit high_adder (
        .a(product[7:4]),
        .b(shifted_a[7:4]),
        .carry_in(low_carry),
        .sum(sum[7:4]),
        .carry_out(high_carry),
        .overflow(high_overflow)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_IDLE;
            steps <= 3'b0;
            product <= 8'b0;
            shifted_a <= 8'b0;
            remaining_b <= 4'b0;
        end

        else if (selected) begin
            case (state)
                // IDLE state: wait for start signal
                STATE_IDLE: begin
                    if (start) begin
                        shifted_a   <= {4'b0, operand_a};
                        remaining_b <= operand_b;
                        product     <= 8'b0;
                        steps       <= 3'b0;
                        state       <= STATE_RUN;
                    end
                end

                // RUN state: shift and add over four clock cycles
                STATE_RUN: begin
                    if (remaining_b[0])
                        product <= sum;
                    
                    shifted_a   <= shifted_a << 1;
                    remaining_b <= remaining_b >> 1;

                    steps       <= steps + 3'd1;
                    if (steps == LAST_STEP)
                        state <= STATE_DONE;
                end

                // Holding start high cannot launch the same request twice.
                STATE_DONE: begin
                    if (!start) 
                        state <= STATE_IDLE;
                end

                default:
                    state <= STATE_IDLE;
            endcase
        end
    end

    // Output the multiplier result based on the show_status signal.
    wire [7:0] status = {1'b0, steps, state, state == STATE_DONE, state == STATE_RUN};
    assign multiplier_result = show_status ? status : product;

    // Mark unused signals to avoid synthesis warnings.
    wire _unused = &{high_carry, low_overflow, high_overflow, 1'b0};
endmodule
