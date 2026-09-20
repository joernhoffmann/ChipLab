// SPDX-License-Identifier: Apache-2.0
// Programmable Sound Generator (PSG): one voice, 4-bit volume, 1-bit PWM.
//
// Timing and pitch:
//   clk --> [tone prescaler] --> [period counter] --> tick
//                                       ^
//   PERIOD ---------------------------+
//
// Waveform:
//   tick --> [square wave] --+
//                            +--> [source select] --> source
//   tick --> [noise LFSR] ---+
//
// Amplitude:
//   VOLUME ---------------------------+
//                                     +--> [level select] --> level
//   VOLUME --> [decay envelope] ------+
//                    ^  ^
//                    |  |
//   TRIGGER ---------+  +--- [envelope prescaler] <-- clk
//
// Output:
//   clk --> [PWM phase 0..14] -+
//                              +--> [PWM gate] --+
//   level ---------------------+                 |
//                                                +--> [AND] --> audio
//   source --------------------------------------+
//   sound_enable --------------------------------+
//   PWM gate: phase < level.
//
// Operations:
//   00 play sound
//   01 latch address
//   10 write register
//   11 read register
//
// Note:
//  - Address/write act on every selected rising edge.
//  - READ replaces audio/status at the output
//  - Playback continues internally. Deselection freezes state.
//  - Reset clears settings and mutes sound; prescalers return to their defaults.
//
// Register map (unused bits/addresses read zero; TRIGGER is command-only):
//   00 PERIOD_LOW          period[7:0]
//   01 PERIOD_HIGH         period[15:8]
//   02 VOLUME              amplitude[3:0] (0..15)
//   03 CONTROL             [0] sound enable
//                          [2:1] source
//                             00: tone
//                             01: noise
//                             10: tone XOR noise
//                             11: tone AND noise
//                          [3] envelope enable
//   04 DECAY_RATE          envelope prescaler ticks per step - 1 (0..255)
//   05 TRIGGER             write [0]=1: reload envelope from VOLUME
//   06 TONE_PRESCALE       optional exponent[2:0], default 4 (/16)
//   07 ENVELOPE_PRESCALE   optional exponent[2:0], default 2 (/4096)
//
// Timing (in selected, advancing clock cycles):
//   P_tone  = 2^TONE_PRESCALE                 (default: /16)
//   P_env   = 2^(10 + ENVELOPE_PRESCALE)      (default: /4096)
//
//   f_tone       = f_clk / (2 * P_tone * (period + 1))
//   f_noise_step = f_clk / (    P_tone * (period + 1))
//   T_decay_step = P_env   * (DECAY_RATE + 1) / f_clk
//
//   Example:
//      /4096 and DECAY_RATE=9 give 40960 clocks per volume step.
//
// Period:
//      - PERIOD writes restart the oscillator.
//      - PERIOD readback returns the programmed value.
// - TRIGGER restarts only the envelope.
// - Sound off pauses the envelope.
// - Envelope mode off pauses decay.
// - Prescaler writes keep the current counter phase. The first interval may vary.
//
// PWM:
//   - Frequency    : f_clk / 15
//   - Phase slots  : 0..14
//   - Gate duty    : level / 15
//   - Level 0      : mute
//   - Level 15     : pass the source continuously
//   - Volume step  : 1/15 at every level
//   - Source low   : audio low at every level
//   - PWM duty describes the gate, not the complete audio waveform
//   - External low-pass filter and amplifier required

// Output: Register to read back or audio output
//      [7] sound enable
//      [6] envelope running (may be paused)
//      [5:2] level
//      [1] raw enabled source
//      [0] PWM audio.


// Optional extensions
// - Uncomment below or define in the build
// - Disabled extension registers read zero and ignore writes.
// - Source selection is always available.
//
`define PSG_TONE_PRESCALE
`define PSG_ENVELOPE_PRESCALE

// Catch misspelled signals instead of creating implicit wires.
`default_nettype none
`include "chiplab_experiments.svh"

module chiplab_09_sound (
    input wire clk,
    input wire rst_n,
    input wire [5:0] selection,
    input wire [1:0] operation,
    input wire [7:0] data,
    output logic [7:0] psg_result
);
    // - Address first, then write/read.
    // - Operation 00: play, keep settings.
    localparam [1:0] OP_PLAY    = 2'd0,
                     OP_ADDRESS = 2'd1,
                     OP_WRITE   = 2'd2,
                     OP_READ    = 2'd3;

    localparam [7:0] REG_ADDR_PERIOD_LOW         = 8'h00,
                     REG_ADDR_PERIOD_HIGH        = 8'h01,
                     REG_ADDR_VOLUME             = 8'h02,
                     REG_ADDR_CONTROL            = 8'h03,
                     REG_ADDR_DECAY_RATE         = 8'h04,
                     REG_ADDR_TRIGGER            = 8'h05,
                     REG_ADDR_TONE_PRESCALE      = 8'h06,
                     REG_ADDR_ENVELOPE_PRESCALE  = 8'h07;

    // Selection of the PSG (Programmable Sound Generator) module
    wire selected = selection == `EXP_PSG;
    wire write_register = selected && operation == OP_WRITE;

    // PSG register values
    logic [7:0]  address;
    logic [15:0] period;
    logic [3:0]  volume;
    logic [3:0]  control;
    logic [7:0]  decay_rate;

    // Control signals
    wire sound_enable         = control[0];
    wire [1:0] source_select  = control[2:1];
    wire envelope_enable      = control[3];
    wire trigger_envelope     = write_register && address == REG_ADDR_TRIGGER && data[0];
    wire write_period         = write_register && (address == REG_ADDR_PERIOD_LOW || address == REG_ADDR_PERIOD_HIGH);

`ifdef PSG_TONE_PRESCALE
    logic [2:0] tone_divider;
`endif

`ifdef PSG_ENVELOPE_PRESCALE
    logic [2:0] envelope_divider;
`endif


    // ------------------------------------------------------------------------
    // Experiment 56: Programmable sound generator
    // - Register control, tone/noise, decay, 4-bit PWM.
    // ------------------------------------------------------------------------
    // Register bank
    // - Period: pitch
    // - Control: enable, source, envelope
    // - Trigger: command; held write repeatedly restarts decay
    always_ff @(posedge clk or negedge rst_n) begin
        // Reset settings
        if (!rst_n) begin
            address <= 8'd0;
            period  <= 16'd0;
            volume  <= 4'd0;
            control <= 4'd0;
            decay_rate <= 8'd0;
`ifdef PSG_TONE_PRESCALE
            tone_divider <= 3'd4;
`endif
`ifdef PSG_ENVELOPE_PRESCALE
            envelope_divider <= 3'd2;
`endif
        end

        // Update while selected
        else if (selected) begin
            // Latch register address
            if (operation == OP_ADDRESS)
                address <= data;

            // Write selected register
            if (write_register) begin
                // Register decode
                case (address)
                    REG_ADDR_PERIOD_LOW     : period[7:0]   <= data;
                    REG_ADDR_PERIOD_HIGH    : period[15:8]  <= data;
                    REG_ADDR_VOLUME         : volume        <= data[3:0];
                    REG_ADDR_CONTROL        : control       <= data[3:0];
                    REG_ADDR_DECAY_RATE     : decay_rate    <= data;
`ifdef PSG_TONE_PRESCALE
                    REG_ADDR_TONE_PRESCALE  : tone_divider  <= data[2:0];
`endif
`ifdef PSG_ENVELOPE_PRESCALE
                    REG_ADDR_ENVELOPE_PRESCALE : envelope_divider <= data[2:0];
`endif
                    default: ;
                endcase
            end
        end
    end


    // ------------------------------------------------------------------------
    // Tone divider and noise generator
    // ------------------------------------------------------------------------
    // - Divider: P_tone*(period+1) clocks per toggle/LFSR step.
    // - Reduction AND detects the last count: n low bits give a /2^n tick.
    // - Noise output: LFSR bit 0.
    // - Disable or period write: restart both generators.
`ifdef PSG_TONE_PRESCALE
    logic [6:0] tone_prescaler;
    logic tone_tick;

    always_comb begin
        // Reduction AND: all selected low bits must be one.
        case (tone_divider)
            3'd0: tone_tick = 1'b1;
            3'd1: tone_tick = &tone_prescaler[0:0];
            3'd2: tone_tick = &tone_prescaler[1:0];
            3'd3: tone_tick = &tone_prescaler[2:0];
            3'd4: tone_tick = &tone_prescaler[3:0];
            3'd5: tone_tick = &tone_prescaler[4:0];
            3'd6: tone_tick = &tone_prescaler[5:0];

            default:
                  tone_tick = &tone_prescaler[6:0];
        endcase
    end
`else
    logic [3:0] tone_prescaler;
    wire tone_tick = &tone_prescaler;
`endif
    logic [3:0] pwm_phase;
    logic [15:0] tone_count, noise;
    logic tone;

    always_ff @(posedge clk or negedge rst_n) begin
        // Reset phase and noise seed
        if (!rst_n) begin
            tone_prescaler  <= '0;
            pwm_phase       <=  4'd0;
            tone_count      <= 16'd0;
            tone            <=  1'b0;
            noise           <= 16'h0001;
        end

        // Update while selected
        else if (selected) begin
            // - PWM: 15 slots, equal volume steps, runs during writes.
            pwm_phase <= (pwm_phase == 4'd14) ? 4'd0 : pwm_phase + 4'd1;

            // Restart waveform
            if (!sound_enable || write_period) begin
                tone_prescaler  <= '0;
                tone_count      <= 16'd0;
                tone            <=  1'b0;
                noise           <= 16'h0001;
            end

            // Advance waveform timers
            else begin
                // Advance on the selected divider tick
                if (tone_tick) begin
                    tone_prescaler <= '0;

                    // Toggle tone and step noise
                    if (tone_count >= period) begin
                        tone_count <= 16'd0;
                        tone <= ~tone;

                        // Noise generation using LFSR
                        // - XOR taps   : 16, 15, 13, 4 (XAPP052).
                        // - Polynomial : x^16 + x^15 + x^13 + x^4 + 1.
                        // - Left shift, seed 1, 65535 states.
                        noise <= {noise[14:0], noise[15] ^ noise[14] ^ noise[12] ^ noise[3]};
                    end

                    // Count to next toggle
                    else
                        tone_count <= tone_count + 16'd1;
                end

                // Count clocks to the next divider tick
                else
                    tone_prescaler <= tone_prescaler + 1'b1;
            end
        end // else if (selected)
    end


    // ------------------------------------------------------------------------
    // Falling envelope
    // ------------------------------------------------------------------------
    // - Trigger: load volume, restart timers.
    // - Decay: subtract 1 every P_env*(decay_rate+1) clocks; stop at zero.
    // - Runs only with sound and envelope enabled.
`ifdef PSG_ENVELOPE_PRESCALE
    logic [16:0] envelope_prescaler;
    logic envelope_tick;

    always_comb begin
        // Reduction AND: all selected low bits must be one
        case (envelope_divider)
            3'd0: envelope_tick = &envelope_prescaler[9:0];
            3'd1: envelope_tick = &envelope_prescaler[10:0];
            3'd2: envelope_tick = &envelope_prescaler[11:0];
            3'd3: envelope_tick = &envelope_prescaler[12:0];
            3'd4: envelope_tick = &envelope_prescaler[13:0];
            3'd5: envelope_tick = &envelope_prescaler[14:0];
            3'd6: envelope_tick = &envelope_prescaler[15:0];
            default:
                  envelope_tick = &envelope_prescaler[16:0];
        endcase
    end
`else
    logic [11:0] envelope_prescaler;
    wire envelope_tick = &envelope_prescaler;
`endif
    logic [7:0] decay_count;
    logic [3:0] envelope_level;
    logic envelope_running;
    always_ff @(posedge clk or negedge rst_n) begin

        // Reset envelope
        if (!rst_n) begin
            envelope_prescaler <= '0;
            decay_count <= 8'd0;
            envelope_level <= 4'd0;
            envelope_running <= 1'b0;
        end

        // Update while selected
        else if (selected) begin
            // Start or retrigger decay
            if (trigger_envelope) begin
                envelope_prescaler <= '0;
                decay_count <= 8'd0;
                envelope_level <= volume;
                envelope_running <= volume != 4'd0;
            end

            // Advance active envelope
            else if (sound_enable && envelope_enable && envelope_running)
            begin
                // Advance on the selected divider tick
                if (envelope_tick) begin
                    envelope_prescaler <= '0;

                    // Lower volume
                    if (decay_count >= decay_rate) begin
                        decay_count <= 8'd0;
                        envelope_level <= envelope_level - 4'd1;

                        // Old level 1 becomes zero after the nonblocking subtraction
                        if (envelope_level == 4'd1)
                            envelope_running <= 1'b0;
                    end

                    // Count to next decay step
                    else
                        decay_count <= decay_count + 8'd1;
                end

                // Count clocks to the next envelope tick
                else
                    envelope_prescaler <= envelope_prescaler + 1'b1;
            end
        end
    end


    // ------------------------------------------------------------------------
    // Source selection and PWM volume
    // ------------------------------------------------------------------------
    // - Select tone/noise combination and fixed volume/envelope
    // - Levels 0..15   : level/15 PWM gate duty
    // - Level 15       : pass full source
    // - Source low     : silence, including at maximum volume
    // - PWM frequency  : f_clk / 15
    // - Zero volume or disabled: mute
    logic source_signal;
    always_comb begin
        // Combine the two generators without another oscillator
        case (source_select)
            2'b00: source_signal = tone;
            2'b01: source_signal = noise[0];
            2'b10: source_signal = tone ^ noise[0];
            2'b11: source_signal = tone & noise[0];
            default: source_signal = 1'b0;
        endcase
    end

    // Output signal generation
    wire raw_signal     = sound_enable && source_signal;                            // Raw audio signal before PWM and volume control
    wire [3:0] level    = envelope_enable ? envelope_level : volume;                // Select between envelope level and fixed volume
    wire audio_pwm      = raw_signal && (pwm_phase < level);  // PWM output based on level and phase

    // ------------------------------------------------------------------------
    // Register readback and output selection
    // ------------------------------------------------------------------------
    // - READ: register data replaces audio/status and playback continues.
    // - Unused addresses, omitted extensions and TRIGGER: read zero.
    logic [7:0] read_data;
    always_comb begin
        // Register decode
        case (address)
            REG_ADDR_PERIOD_LOW         : read_data = period[7:0];
            REG_ADDR_PERIOD_HIGH        : read_data = period[15:8];
            REG_ADDR_VOLUME             : read_data = {4'd0, volume};
            REG_ADDR_CONTROL            : read_data = {4'd0, control};
            REG_ADDR_DECAY_RATE         : read_data = decay_rate;
`ifdef PSG_TONE_PRESCALE
            REG_ADDR_TONE_PRESCALE      : read_data = {5'd0, tone_divider};
`endif
`ifdef PSG_ENVELOPE_PRESCALE
            REG_ADDR_ENVELOPE_PRESCALE : read_data = {5'd0, envelope_divider};
`endif
            default: read_data = 8'd0;
        endcase
    end

    // Output: register readback or audio output
    wire [7:0] audio_out = {sound_enable, envelope_running, level, raw_signal, audio_pwm};
    always_comb begin
        case (operation)
            OP_PLAY, OP_ADDRESS, OP_WRITE:  psg_result = audio_out;
            OP_READ:                        psg_result = read_data;
            default:                        psg_result = 8'd0;
        endcase
    end
endmodule
