// SPDX-License-Identifier: Apache-2.0
// Programmable sound generator (PSG):
// - One voice: square wave or noise.
// - Path: tone/noise -> volume/envelope -> PWM.
// - Envelope: triggered decay to zero.
// - PWM audio: external filter and amplifier.
// - Deselected: pause. Reset: clear settings, mute.
//
// Register map:
// - 0x00 PERIOD_LOW:  tone period, bits [7:0].
// - 0x01 PERIOD_HIGH: tone period, bits [15:8].
// - 0x02 VOLUME:      amplitude [3:0], 0..15.
// - 0x03 CONTROL:     sound enable [0], noise mode [1], envelope mode [2].
// - 0x04 DECAY_RATE:  step interval = 4096*(value+1) clocks.
// - 0x05 TRIGGER:     write [0]=1: restart envelope; read: zero.
//
// Operation (uio_in[7:6]):
// - 00: Play without writing.
// - 01: Address <- ui_in (rising edge).
// - 10: Register <- ui_in (rising edge).
// - 11: Register -> uo_out (replaces audio/status).
`default_nettype none
`include "chiplab_experiments.svh"

module chiplab_09_sound (
    input wire clk,
    input wire rst_n,
    input wire [5:0] selection,
    input wire [1:0] operation,
    input wire [7:0] data,
    output wire [7:0] psg_result
);
    // - Address first, then write/read.
    // - Operation 00: play, keep settings.
    localparam [1:0] ADDRESS = 2'd1, WRITE = 2'd2, READ = 2'd3;
    localparam [7:0] PERIOD_LOW = 8'h00, PERIOD_HIGH = 8'h01,
                     VOLUME = 8'h02, CONTROL = 8'h03,
                     DECAY_RATE = 8'h04, TRIGGER = 8'h05;
    wire selected = selection == `EXP_PSG;
    wire write_register = selected && operation == WRITE;
    logic [7:0] address;
    logic [15:0] period;
    logic [3:0] volume;
    logic [2:0] control;
    logic [7:0] decay_rate;
    wire sound_enable = control[0];
    wire noise_mode = control[1];
    wire envelope_enable = control[2];
    wire trigger_envelope = write_register && address == TRIGGER && data[0];
    wire write_period = write_register && (address == PERIOD_LOW || address == PERIOD_HIGH);


    // ------------------------------------------------------------------------
    // Experiment 56: Programmable sound generator
    // - Register control, tone/noise, decay, 4-bit PWM.
    // ------------------------------------------------------------------------
    // Register bank
    // - Period: pitch. Control: enable, noise, envelope.
    // - Trigger: command; held write repeatedly restarts decay.
    always_ff @(posedge clk or negedge rst_n) begin
        // Reset settings
        if (!rst_n) begin
            address <= 8'd0;
            period <= 16'd0;
            volume <= 4'd0;
            control <= 3'd0;
            decay_rate <= 8'd0;
        end

        // Update while selected
        else if (selected) begin
            // Latch register address
            if (operation == ADDRESS)
                address <= data;
            // Write selected register
            if (write_register) begin
                // Register decode
                case (address)
                    PERIOD_LOW: period[7:0] <= data;
                    PERIOD_HIGH: period[15:8] <= data;
                    VOLUME: volume <= data[3:0];
                    CONTROL: control <= data[2:0];
                    DECAY_RATE: decay_rate <= data;
                    default: ;
                endcase
            end
        end
    end


    // ------------------------------------------------------------------------
    // Tone divider and noise generator
    // ------------------------------------------------------------------------
    // - Divider: 16*(period+1) clocks per toggle/LFSR step.
    // - Tone frequency: f_clk / (32 * (period + 1)).
    // - Noise output: LFSR bit 0.
    // - Disable or period write: restart both generators.
    logic [3:0] tone_prescaler, pwm_phase;
    logic [15:0] tone_count, noise;
    logic tone;
    always_ff @(posedge clk or negedge rst_n) begin
        // Reset phase and noise seed
        if (!rst_n) begin
            tone_prescaler <= 4'd0;
            pwm_phase <= 4'd0;
            tone_count <= 16'd0;
            tone <= 1'b0;
            noise <= 16'h0001;
        end

        // Update while selected
        else if (selected) begin
            // - PWM: 16 slots; runs during writes.
            pwm_phase <= pwm_phase + 4'd1;
            // Restart waveform
            if (!sound_enable || write_period) begin
                tone_prescaler <= 4'd0;
                tone_count <= 16'd0;
                tone <= 1'b0;
                noise <= 16'h0001;
            end

            // Advance waveform timers
            else begin
                tone_prescaler <= tone_prescaler + 4'd1;
                // Tick every 16 clocks
                if (&tone_prescaler) begin
                    // Toggle tone and step noise
                    if (tone_count >= period) begin
                        tone_count <= 16'd0;
                        tone <= ~tone;
                        // - XOR taps: 16,15,13,4 (XAPP052).
                        // - Polynomial: x^16+x^15+x^13+x^4+1.
                        // - Left shift, seed 1, 65535 states.
                        noise <= {noise[14:0], noise[15]^noise[14]^noise[12]^noise[3]};
                    end

                    // Count to next toggle
                    else
                        tone_count <= tone_count + 16'd1;
                end
            end
        end
    end


    // ------------------------------------------------------------------------
    // Falling envelope
    // ------------------------------------------------------------------------
    // - Trigger: load volume, restart timers.
    // - Decay: subtract 1 every 4096*(decay_rate+1) clocks; stop at zero.
    // - Runs only with sound and envelope enabled.
    logic [11:0] envelope_prescaler;
    logic [7:0] decay_count;
    logic [3:0] envelope_level;
    logic envelope_running;
    always_ff @(posedge clk or negedge rst_n) begin
        // Reset envelope
        if (!rst_n) begin
            envelope_prescaler <= 12'd0;
            decay_count <= 8'd0;
            envelope_level <= 4'd0;
            envelope_running <= 1'b0;
        end

        // Update while selected
        else if (selected) begin
            // Start or retrigger decay
            if (trigger_envelope) begin
                envelope_prescaler <= 12'd0;
                decay_count <= 8'd0;
                envelope_level <= volume;
                envelope_running <= volume != 4'd0;
            end

            // Advance active envelope
            else if (sound_enable && envelope_enable && envelope_running) begin
                envelope_prescaler <= envelope_prescaler + 12'd1;
                // Tick every 4096 clocks
                if (&envelope_prescaler) begin
                    // Lower volume
                    if (decay_count >= decay_rate) begin
                        decay_count <= 8'd0;
                        envelope_level <= envelope_level - 4'd1;
                        // Stop at zero
                        if (envelope_level == 4'd1)
                            envelope_running <= 1'b0;
                    end

                    // Count to next decay step
                    else
                        decay_count <= decay_count + 8'd1;
                end
            end
        end
    end


    // ------------------------------------------------------------------------
    // Source selection and PWM volume
    // ------------------------------------------------------------------------
    // - Select tone/noise and fixed volume/envelope.
    // - Source high: level/16 PWM duty; source low: silence.
    // - PWM frequency: f_clk / 16. Zero volume or disabled: mute.
    wire raw_signal = sound_enable && (noise_mode ? noise[0] : tone);
    wire [3:0] level = envelope_enable ? envelope_level : volume;
    wire audio_pwm = raw_signal && pwm_phase < level;


    // ------------------------------------------------------------------------
    // Register readback and output selection
    // ------------------------------------------------------------------------
    // - READ: register data replaces audio/status; playback continues.
    // - Unused addresses and TRIGGER: read zero.
    logic [7:0] read_data;
    always_comb begin
        // Register decode
        case (address)
            PERIOD_LOW: read_data = period[7:0];
            PERIOD_HIGH: read_data = period[15:8];
            VOLUME: read_data = {4'd0, volume};
            CONTROL: read_data = {5'd0, control};
            DECAY_RATE: read_data = decay_rate;
            default: read_data = 8'd0;
        endcase
    end
    // - Status: [7] enable, [6] envelope running, [5:2] level.
    // - Audio: [1] raw source, [0] PWM.
    assign psg_result = operation == READ ? read_data
        : {sound_enable, envelope_running, level, raw_signal, audio_pwm};
endmodule
