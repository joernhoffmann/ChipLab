// SPDX-License-Identifier: Apache-2.0
// Binarized Neural Network (BNN): one layer, eight binary inputs.
//
//   INPUT --------+
//                 +--> [XNOR] --> [Popcount] --> [Threshold] --> OUTPUT[n]
//   WEIGHTS[n] ---+                                   ^
//                                               THRESHOLD[n]
//
// Operation:
//   00: Calculate one neuron per selected clock
//   01: Select register address
//   10: Write selected register
//   11: Read selected register
//
// Register map:
//   00 INPUT       eight shared input bits
//   01 CONTROL     [0] enable calculation
//   02 OUTPUT      one result bit per neuron, read-only
//   03 STATUS      [0] result valid, read-only
//   04 NEURON      neuron index for register access
//   05 WEIGHTS     eight weights of the selected neuron
//   06 THRESHOLD   threshold[3:0] of the selected neuron
//   07 MATCHES     XNOR result of the selected neuron, read-only
//   08 COUNT       matching bits, 0..8, read-only
//
// Calculation:
//   - Binary values represent -1 and +1
//   - XNOR marks equal input and weight bits
//   - Popcount counts these matches
//   - Output is 1 when count >= threshold
//   - Threshold 0: always 1
//   - Threshold 9..15: always 0
//   - Signed dot product: 2 * count - 8 (not calculated in hardware)
//
// Control:
//   - Input, weight or threshold writes invalidate the result
//   - Calculation restarts at neuron zero
//   - OUTPUT may contain partial results until STATUS[0] is 1
//   - After completion, results hold until configuration changes
//   - Register accesses, disable and deselection pause calculation
//   - Reset clears registers and disables calculation
//   - Invalid neuron selections and writes to read-only registers are ignored
//   - Unused addresses and output bits read zero
//
// Configuration:
//   - BNN_NEURON_COUNT selects the synthesized neuron count (1..8).
//   - Weights and thresholds remain programmable at runtime

`default_nettype none
`include "chiplab_experiments.svh"

`ifndef BNN_NEURON_COUNT
`define BNN_NEURON_COUNT 1
`endif

module chiplab_08_bnn (
    input wire clk,
    input wire rst_n,
    input wire [5:0] selection,
    input wire [1:0] operation,
    input wire [7:0] data,
    output wire [7:0] bnn_result
);
    localparam integer NEURON_COUNT = `BNN_NEURON_COUNT;
    localparam integer INDEX_WIDTH  = (NEURON_COUNT > 1) ? $clog2(NEURON_COUNT) : 1;

    // Check configuration once at simulation startup.
`ifndef SYNTHESIS
    initial begin
        assert (NEURON_COUNT >= 1 && NEURON_COUNT <= 8)
            else $fatal(1, "BNN_NEURON_COUNT must be between 1 and 8");
    end
`endif

    // Operations
    localparam [1:0] OP_RUN    = 2'd0,
                     OP_ADDRESS = 2'd1,
                     OP_WRITE   = 2'd2,
                     OP_READ    = 2'd3;

    // Register addresses
    localparam [7:0] REG_ADDR_INPUT     = 8'h00,
                     REG_ADDR_CONTROL   = 8'h01,
                     REG_ADDR_OUTPUT    = 8'h02,
                     REG_ADDR_STATUS    = 8'h03,
                     REG_ADDR_NEURON    = 8'h04,
                     REG_ADDR_WEIGHTS   = 8'h05,
                     REG_ADDR_THRESHOLD = 8'h06,
                     REG_ADDR_MATCHES   = 8'h07,
                     REG_ADDR_COUNT     = 8'h08;

    // Register bank
    logic [7:0] address;
    logic [7:0] input_bits;
    logic enable;
    logic [INDEX_WIDTH-1:0] neuron_select;

    // Selection and write signals
    wire selected = selection == `EXP_BNN;
    wire write_register = selected && operation == OP_WRITE;
    wire configuration_write = write_register &&
        (address == REG_ADDR_INPUT ||
         address == REG_ADDR_WEIGHTS ||
         address == REG_ADDR_THRESHOLD);

    // Yosys specific: implement the resettable weight bank as individual registers
    // Thus as flipflops rather than a memory array.
    (* mem2reg *) logic [7:0] weights [0:NEURON_COUNT-1];
    (* mem2reg *) logic [3:0] thresholds [0:NEURON_COUNT-1];

    // Calculation state
    logic [INDEX_WIDTH-1:0] neuron_index;
    logic [NEURON_COUNT-1:0] outputs;
    logic result_valid;


    // Count set bits with a balanced adder tree. Result ranges from 0 to 8.
    // This is a divide and conquer approach for counting set bits.
    function automatic logic [3:0] popcount8(input logic [7:0] bits);
        logic [1:0] count_01, count_23, count_45, count_67;
        logic [2:0] count_left, count_right;

        // 2-bit sums
        count_01 = {1'b0, bits[0]} + {1'b0, bits[1]};
        count_23 = {1'b0, bits[2]} + {1'b0, bits[3]};
        count_45 = {1'b0, bits[4]} + {1'b0, bits[5]};
        count_67 = {1'b0, bits[6]} + {1'b0, bits[7]};

        // 3-bit sums 
        count_left  = {1'b0, count_01} + {1'b0, count_23};
        count_right = {1'b0, count_45} + {1'b0, count_67};

        // 4-bit result
        popcount8 = {1'b0, count_left} + {1'b0, count_right};
    endfunction


    // ------------------------------------------------------------------------
    // Experiment 55: Shared neuron datapath
    // ------------------------------------------------------------------------
    // - Calculation uses neuron_index.
    // - Readback uses neuron_select.
    // - Register access pauses calculation, so both share the same hardware.
    wire [INDEX_WIDTH-1:0] active_neuron =
        operation == OP_READ ? neuron_select : neuron_index;

    // Compute the match bits for the active neuron.
    wire [7:0] match_bits = ~(input_bits ^ weights[active_neuron]);

    wire [3:0] match_count = popcount8(match_bits);

    // Determine the output of the active neuron based on the match count and threshold.
    wire neuron_output = match_count >= thresholds[active_neuron];


    // ------------------------------------------------------------------------
    // Register bank
    // ------------------------------------------------------------------------
    integer i;
    always_ff @(posedge clk or negedge rst_n) begin
        // Reset settings and weights
        if (!rst_n) begin
            address       <= 8'd0;
            input_bits    <= 8'd0;
            enable        <= 1'b0;
            neuron_select <= '0;

            for (i = 0; i < NEURON_COUNT; i = i + 1) begin
                weights[i]    <= 8'd0;
                thresholds[i] <= 4'd0;
            end
        end

        // Update while selected
        else if (selected) begin
            // Latch register address
            if (operation == OP_ADDRESS)
                address <= data;

            // Write selected register
            if (write_register) begin
                case (address)
                    REG_ADDR_INPUT      : input_bits                <= data;
                    REG_ADDR_CONTROL    : enable                    <= data[0];
                    REG_ADDR_WEIGHTS    : weights[neuron_select]    <= data;
                    REG_ADDR_THRESHOLD  : thresholds[neuron_select] <= data[3:0];
                    REG_ADDR_NEURON     :
                        if (data < 8'(NEURON_COUNT))
                            neuron_select <= data[INDEX_WIDTH-1:0];

                    default: ;
                endcase
            end
        end
    end


    // ------------------------------------------------------------------------
    // Sequential calculation
    // ------------------------------------------------------------------------
    // - Process one neuron per clock during OP_RUN.
    // - A counter selects the weights and destination output bit.
    // - Configuration writes restart calculation without copying the bank.
    always_ff @(posedge clk or negedge rst_n) begin
        // Reset results and progress
        if (!rst_n) begin
            neuron_index <= '0;
            outputs      <= '0;
            result_valid <= 1'b0;
        end

        // Update while selected
        else if (selected) begin
            // Discard results based on the previous configuration
            if (configuration_write) begin
                neuron_index <= '0;
                outputs      <= '0;
                result_valid <= 1'b0;
            end

            // Calculate the next neuron
            else if (operation == OP_RUN && enable && !result_valid) begin
                outputs[neuron_index] <= neuron_output;

                // The final output bit and valid flag update on the same edge
                if (neuron_index == INDEX_WIDTH'(NEURON_COUNT - 1))
                    result_valid <= 1'b1;

                // Continue with the next weight set
                else
                    neuron_index <= neuron_index + 1'b1;
            end
        end
    end


    // ------------------------------------------------------------------------
    // Register readback and output selection
    // ------------------------------------------------------------------------
    // - Explicitly extend unsigned values to eight bits for readback.
    // - MATCHES and COUNT expose the selected neuron's calculation directly.
    wire [7:0] output_data = 8'(outputs);
    wire [7:0] neuron_select_data = 8'(neuron_select);
    logic [7:0] read_data;

    always_comb begin
        case (address)
            REG_ADDR_INPUT:     read_data = input_bits;
            REG_ADDR_CONTROL:   read_data = {7'd0, enable};
            REG_ADDR_OUTPUT:    read_data = output_data;
            REG_ADDR_STATUS:    read_data = {7'd0, result_valid};
            REG_ADDR_NEURON:    read_data = neuron_select_data;
            REG_ADDR_WEIGHTS:   read_data = weights[neuron_select];
            REG_ADDR_THRESHOLD: read_data = {4'd0, thresholds[neuron_select]};
            REG_ADDR_MATCHES:   read_data = match_bits;
            REG_ADDR_COUNT:     read_data = {4'd0, match_count};
            default:            read_data = 8'd0;
        endcase
    end

    assign bnn_result = operation == OP_READ ? read_data : output_data;
endmodule
