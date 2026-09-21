// SPDX-License-Identifier: Apache-2.0
`default_nettype none
`include "chiplab_experiments.svh"

module chiplab_05_shift_counters (
    input wire clk,
    input wire rst_n,
    input wire [5:0] selection,
    input wire [1:0] operation,
    input wire [7:0] data,
    output wire [7:0] shift_register_result,
    output wire [7:0] universal_shift_register_result,
    output wire [7:0] binary_counter_result,
    output wire [7:0] up_down_counter_result,
    output wire [7:0] modulo_counter_result,
    output wire [7:0] bcd_counter_result,
    output wire [7:0] ring_counter_result,
    output wire [7:0] johnson_counter_result,
    output wire [7:0] lfsr_result
);
    // Internal enable signal derived from data[4]
    wire enable = data[4];

    // Decode the experiment number
    wire select_shift     = selection == `EXP_SHIFT_REGISTER;
    wire select_universal = selection == `EXP_UNIVERSAL_SHIFT_REGISTER;
    wire select_binary    = selection == `EXP_BINARY_COUNTER;
    wire select_up_down   = selection == `EXP_UP_DOWN_COUNTER;
    wire select_modulo    = selection == `EXP_MODULO_COUNTER;
    wire select_bcd       = selection == `EXP_BCD_COUNTER;
    wire select_ring      = selection == `EXP_RING_COUNTER;
    wire select_johnson   = selection == `EXP_JOHNSON_COUNTER;
    wire select_lfsr      = selection == `EXP_LFSR;

    // Enable
    wire enable_shift     = select_shift    && enable;
    wire enable_universal = select_universal;           // Uses operation 00 to hold instead of enable.
    wire enable_binary    = select_binary   && enable;
    wire enable_up_down   = select_up_down  && enable;
    wire enable_modulo    = select_modulo   && enable;
    wire enable_bcd       = select_bcd      && enable;
    wire enable_ring      = select_ring     && enable;
    wire enable_johnson   = select_johnson  && enable;
    wire enable_lfsr      = select_lfsr     && enable;

    // ------------------------------------------------------------------------
    // Experiment 35: Shift register
    // - shifts data in and to the left
    // - data[0] is serial input
    // ------------------------------------------------------------------------
    logic [3:0] shift_register;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shift_register <= 4'd0;

        else if (enable_shift) begin
            shift_register <= {shift_register[2:0], data[0]};
        end
    end
    assign shift_register_result = {4'b0, shift_register};


    // ------------------------------------------------------------------------
    // Experiment 36: Universal shift register
    // Operation:
    //  - 00 hold
    //  - 01 left
    //  - 10 right
    //  - 11 load data[3:0]
    // ------------------------------------------------------------------------
    logic [3:0] universal_shift_register;
    localparam [1:0]
        OP_HOLD        = 2'b00,
        OP_SHIFT_LEFT  = 2'b01,
        OP_SHIFT_RIGHT = 2'b10,
        OP_LOAD        = 2'b11;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            universal_shift_register <= 4'd0;

        else if (enable_universal) begin
            case (operation)
                OP_HOLD:        universal_shift_register <= universal_shift_register;
                OP_SHIFT_LEFT:  universal_shift_register <= {universal_shift_register[2:0], data[0]};
                OP_SHIFT_RIGHT: universal_shift_register <= {data[0], universal_shift_register[3:1]};
                OP_LOAD:        universal_shift_register <= data[3:0];
                default: ;
            endcase
        end
    end

    assign universal_shift_register_result = {4'b0, universal_shift_register};


    // ------------------------------------------------------------------------
    // Experiment 37: Binary counter
    // Count 0 through 15.
    // ------------------------------------------------------------------------
    logic [3:0] binary_counter;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            binary_counter <= 4'd0;

        else if (enable_binary) begin
            binary_counter <= binary_counter + 4'd1;
        end
    end
    assign binary_counter_result = {4'b0, binary_counter};


    // ------------------------------------------------------------------------
    // Experiment 38: Up/down counter
    // data[0]: 0 counts up, 1 counts down
    // ------------------------------------------------------------------------
    logic [3:0] up_down_counter;
    wire dir_down = data[0];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            up_down_counter <= 4'd0;

        else if (enable_up_down) begin
            // Increment up/down counter based on data[0]
            up_down_counter <= dir_down ? up_down_counter - 4'd1 : up_down_counter + 4'd1;
        end
    end
    assign up_down_counter_result = {4'b0, up_down_counter};


    // ------------------------------------------------------------------------
    // Experiment 39: Modulo-6 counter
    // Count 0 through 5, then wrap to 0
    // ------------------------------------------------------------------------
    logic [3:0] modulo_counter;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            modulo_counter <= 4'd0;

        else if (enable_modulo) begin
            // Increment modulo-6 counter, wrap to 0 after 5
            modulo_counter <= modulo_counter == 4'd5 ? 4'd0 : modulo_counter + 4'd1;
        end
    end
    assign modulo_counter_result = {4'b0, modulo_counter};


    // ------------------------------------------------------------------------
    // Experiment 40: BCD counter
    // Count 0 through 9, then wrap to 0
    // ------------------------------------------------------------------------
    logic [3:0] bcd_counter;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bcd_counter <= 4'd0;

        else if (enable_bcd) begin
            // Increment BCD counter, wrap to 0 after 9
            bcd_counter <= bcd_counter == 4'd9 ? 4'd0 : bcd_counter + 4'd1;
        end
    end
    assign bcd_counter_result = {4'b0, bcd_counter};


    // ------------------------------------------------------------------------
    // Experiment 41: Ring counter
    // Rotate one set bit
    // Reset seeds "0001"
    // ------------------------------------------------------------------------
    logic [3:0] ring_counter;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ring_counter <= 4'd1;

        else if (enable_ring) begin
            ring_counter <= {ring_counter[2:0], ring_counter[3]};
        end
    end
    assign ring_counter_result = {4'b0, ring_counter};


    // ------------------------------------------------------------------------
    // Experiment 42: Johnson counter
    // Feed the inverted high bit back into bit 0
    // ------------------------------------------------------------------------
    logic [3:0] johnson_counter;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            johnson_counter <= 4'd0;

        else if (enable_johnson) begin
            johnson_counter <= {johnson_counter[2:0], ~johnson_counter[3]};
        end
    end
    assign johnson_counter_result = {4'b0, johnson_counter};


    // ------------------------------------------------------------------------
    // Experiment 43: LFSR
    // XOR bits 3 and 2 for a 15-state sequence.
    // - Tap polynomial       : x^4 + x^3 + 1 (stages 4 and 3, left shift)
    // - Forward recurrence   : s[n+4] = s[n+1] XOR s[n]
    // Reset seeds "0001"
    // ------------------------------------------------------------------------
    logic [3:0] lfsr;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            lfsr <= 4'd1;

        else if (enable_lfsr) begin
            lfsr <= {lfsr[2:0], lfsr[3] ^ lfsr[2]};
        end
    end
    assign lfsr_result = {4'b0, lfsr};

    wire _unused = &{data[7:5], 1'b0};
endmodule
