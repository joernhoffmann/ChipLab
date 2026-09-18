// SPDX-License-Identifier: Apache-2.0
`default_nettype none
`include "chiplab_experiments.svh"

module chiplab_04_storage_memory (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [5:0] selection,
    input  wire [7:0] data,
    input  wire [7:0] alu_result,
    output wire [3:0] accumulator_value,
    output wire [7:0] sr_latch_result,
    output wire [7:0] d_latch_result,
    output wire [7:0] d_flipflop_result,
    output wire [7:0] latch_ff_result,
    output wire [7:0] t_ff_result,
    output wire [7:0] jk_ff_result,
    output wire [7:0] reset_result,
    output wire [7:0] register_enable_result,
    output wire [7:0] register_control_result,
    output wire [7:0] memory_result,
    output wire [7:0] accumulator_result
);
    // Latches and the reset comparison are intentional experiments.
    /* verilator lint_off COMBDLY */
    /* verilator lint_off UNOPTFLAT */
    /* verilator lint_off SYNCASYNCNET */


    // ------------------------------------------------------------------------
    // Experiment 23: SR latch
    // Is a level-sensitive latch that sets on data[0] and resets on data[1].
    // Output:
    //  - Bit 0: Q
    //  - Bit 1: ~Q
    //  - Bit 2: Q & ~Q (should always be 0), e. g. indicates an invalid state.
    //  - Bits 3-7: 0
    // ------------------------------------------------------------------------
    logic sr_q;
    always_latch begin
        if (!rst_n)
            sr_q <= 1'b0;
        
        else if (selection == `EXP_SR_LATCH) begin
            case (data[1:0])
                2'b01: sr_q <= 1'b1;
                2'b10: sr_q <= 1'b0;
                default: sr_q <= sr_q;
            endcase
        end
    end
    assign sr_latch_result = {5'b0, &data[1:0], ~sr_q, sr_q};


    // ------------------------------------------------------------------------
    // Experiment 24: D latch
    // Is a level-sensitive latch that captures data[0] when data[1] is high.
    // Output:
    //  - Bit 0: Q
    //  - Bits 1-7: 0
    // ------------------------------------------------------------------------
    logic d_latch_q;
    always_latch begin
        if (!rst_n)
            d_latch_q <= 1'b0;
        else if ((selection == `EXP_D_LATCH) && data[1])
            d_latch_q <= data[0];
    end
    assign d_latch_result = {7'b0, d_latch_q};


    // ------------------------------------------------------------------------
    // Experiment 25: D flip-flop
    // Captures data[0] on the rising clock edge.
    // ------------------------------------------------------------------------
    logic d_ff_q;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            d_ff_q <= 1'b0;
        else if (selection == `EXP_D_FLIPFLOP)
            d_ff_q <= data[0];
    end
    assign d_flipflop_result = {7'b0, d_ff_q};


    // ------------------------------------------------------------------------
    // Experiment 28: D latch and D flip-flop
    // Compare the gated latch in bit 0 with the edge-triggered flip-flop in bit 1.
    // ------------------------------------------------------------------------
    logic compare_latch_q, compare_ff_q;
    always_latch begin
        if (!rst_n)
            compare_latch_q <= 1'b0;
        else if ((selection == `EXP_LATCH_FLIPFLOP) && data[1])
            compare_latch_q <= data[0];
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            compare_ff_q <= 1'b0;
        else if (selection == `EXP_LATCH_FLIPFLOP)
            compare_ff_q <= data[0];
    end
    assign latch_ff_result = {6'b0, compare_ff_q, compare_latch_q};


    // ------------------------------------------------------------------------
    // Experiment 26: T flip-flop
    // Toggle on each rising clock edge while data[0] is high.
    // ------------------------------------------------------------------------
    logic t_q;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            t_q <= 1'b0;
        else if ((selection == `EXP_T_FLIPFLOP) && data[0])
            t_q <= ~t_q;
    end
    assign t_ff_result = {7'b0, t_q};


    // ------------------------------------------------------------------------
    // Experiment 27: JK flip-flop
    // data[0] is J and data[1] is K.
    // ------------------------------------------------------------------------
    logic jk_q;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            jk_q <= 1'b0;
        else if (selection == `EXP_JK_FLIPFLOP) begin
            case (data[1:0])
                2'b01: jk_q <= 1'b1;
                2'b10: jk_q <= 1'b0;
                2'b11: jk_q <= ~jk_q;
                default: jk_q <= jk_q;
            endcase
        end
    end
    assign jk_ff_result = {7'b0, jk_q};


    // ------------------------------------------------------------------------
    // Experiment 29: Synchronous and asynchronous reset
    // Both flip-flops load data[0]; bits 0 and 1 show sync and async reset.
    // ------------------------------------------------------------------------
    logic sync_reset_q, async_reset_q;
    always_ff @(posedge clk) begin
        if (!rst_n)
            sync_reset_q <= 1'b0;
        else if (selection == `EXP_RESET)
            sync_reset_q <= data[0];
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            async_reset_q <= 1'b0;
        else if (selection == `EXP_RESET)
            async_reset_q <= data[0];
    end
    assign reset_result = {6'b0, async_reset_q, sync_reset_q};


    // ------------------------------------------------------------------------
    // Experiment 30: Register with enable
    // Load data[3:0] on a rising edge while data[4] is high.
    // ------------------------------------------------------------------------
    logic [3:0] enable_register;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            enable_register <= 4'b0;
        else if ((selection == `EXP_REGISTER_ENABLE) && data[4])
            enable_register <= data[3:0];
    end
    assign register_enable_result = {4'b0, enable_register};


    // ------------------------------------------------------------------------
    // Experiment 31: Register with load, hold, and clear
    // data[5:4] selects hold, load, clear, or load; data[3:0] is the input.
    // ------------------------------------------------------------------------
    logic [3:0] control_register;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            control_register <= 4'b0;
        else if (selection == `EXP_REGISTER_CONTROL) begin
            case (data[5:4])
                2'b00: control_register <= control_register;
                2'b01: control_register <= data[3:0];
                2'b10: control_register <= 4'b0;
                default: control_register <= data[3:0];
            endcase
        end
    end
    assign register_control_result = {4'b0, control_register};


    // ------------------------------------------------------------------------
    // Experiment 32: Small read/write memory
    // data[5:4] is the address, data[3:0] is write data, and data[6] enables write.
    // ------------------------------------------------------------------------
    logic [3:0] memory [0:3];
    integer i;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 4; i = i + 1)
                memory[i] <= 4'b0;
        end else if ((selection == `EXP_MEMORY) && data[6]) begin
            memory[data[5:4]] <= data[3:0];
        end
    end
    assign memory_result = {4'b0, memory[data[5:4]]};


    // ------------------------------------------------------------------------
    // Experiment 33: Accumulator
    // data[3:0] is the operand, data[4] enables update, and data[5] clears it.
    // ------------------------------------------------------------------------
    logic [7:0] accumulator;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            accumulator <= 8'b0;
        else if (selection == `EXP_ACCUMULATOR) begin
            if (data[5])
                accumulator <= 8'b0;
            else if (data[4])
                accumulator <= alu_result;
        end
    end
    assign accumulator_value = accumulator[3:0];
    assign accumulator_result = accumulator;

    wire _unused = &{data[7], 1'b0};
    /* verilator lint_on SYNCASYNCNET */
    /* verilator lint_on UNOPTFLAT */
    /* verilator lint_on COMBDLY */
endmodule
