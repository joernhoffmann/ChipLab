// SPDX-License-Identifier: Apache-2.0
// Standalone RTL checks: PWM range and output gating.
// Run from repository root:
// iverilog -g2012 -I src -s tb -o /tmp/psg-test \
//   src/chiplab_09_sound.sv test/psg_extensions_tb.sv && vvp /tmp/psg-test
`include "chiplab_experiments.svh"

module tb;
    reg clk = 0;
    always #5 clk = ~clk;
    reg rst_n = 0;
    reg [5:0] selection = `EXP_PSG;
    reg [1:0] operation = 0;
    reg [7:0] data = 0;
    wire [7:0] result;
    chiplab_09_sound dut(clk, rst_n, selection, operation, data, result);

    task cycle(input [1:0] op, input [7:0] value);
        begin
            @(negedge clk);
            operation = op;
            data = value;
            @(posedge clk);
            #1;
        end
    endtask

    task write_register(input [7:0] address, input [7:0] value);
        begin
            cycle(1, address);
            cycle(2, value);
        end
    endtask

    integer level, i, pulses;
    initial begin
        #1;
        #10;
        rst_n = 1;
        write_register(3, 1);

        // Isolate PWM from the oscillator: check all levels over a full cycle.
        force dut.source_signal = 1'b1;
        for (level = 0; level < 16; level = level + 1) begin
            write_register(2, level);
            pulses = 0;
            for (i = 0; i < 15; i = i + 1) begin
                cycle(0, 0);
                pulses = pulses + result[0];
            end
            if (pulses != level)
                $fatal(1, "PWM level %d: %d pulses", level, pulses);
        end

        // Maximum volume must still respect source-low and sound-disable.
        force dut.source_signal = 1'b0;
        cycle(0, 0);
        if (result[0]) $fatal(1, "Low source must remain silent");
        force dut.source_signal = 1'b1;
        write_register(3, 0);
        if (result[0]) $fatal(1, "Disabled sound must remain silent");
        release dut.source_signal;

        $display("PASS: PWM range, gating and mute");
        $finish;
    end
endmodule
