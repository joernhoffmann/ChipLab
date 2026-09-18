// SPDX-License-Identifier: Apache-2.0
`ifndef CHIPLAB_EXPERIMENTS_SVH
`define CHIPLAB_EXPERIMENTS_SVH

// Experiment numbers on uio_in[5:0]. Zero selects no experiment.
`define EXP_NONE 6'd0

// Basic and Boolean Logic
`define EXP_BASIC_GATES 6'd1
`define EXP_BOOLEAN_IDENTITIES 6'd2

// Data Selection and Coding
`define EXP_MULTIPLEXER 6'd3
`define EXP_DEMULTIPLEXER 6'd4
`define EXP_BINARY_DECODER 6'd5
`define EXP_ENCODER 6'd6
`define EXP_PRIORITY_ENCODER 6'd7
`define EXP_DUAL_PRIORITY 6'd8
`define EXP_BCD_DECODER 6'd9
`define EXP_HEX_DECODER 6'd10
`define EXP_GRAY_CODE 6'd11
`define EXP_PARITY 6'd12
`define EXP_ROM 6'd13

// Arithmetic and Data Operations
`define EXP_HALF_ADDER 6'd14
`define EXP_FULL_ADDER 6'd15
`define EXP_ADDER_4BIT 6'd16
`define EXP_SUBTRACTOR_4BIT 6'd17
`define EXP_UNSIGNED_COMPARATOR 6'd18
`define EXP_SIGNED_COMPARATOR 6'd19
`define EXP_SHIFTS 6'd20
`define EXP_ROTATION 6'd21
`define EXP_ALU 6'd22

// Storage Elements and Memory
`define EXP_SR_LATCH 6'd23
`define EXP_D_LATCH 6'd24
`define EXP_D_FLIPFLOP 6'd25
`define EXP_T_FLIPFLOP 6'd26
`define EXP_JK_FLIPFLOP 6'd27
`define EXP_LATCH_FLIPFLOP 6'd28
`define EXP_RESET 6'd29
`define EXP_REGISTER_ENABLE 6'd30
`define EXP_REGISTER_CONTROL 6'd31
`define EXP_MEMORY 6'd32
`define EXP_ACCUMULATOR 6'd33

// Shift Registers and Counters
`define EXP_SHIFT_REGISTER 6'd34
`define EXP_UNIVERSAL_SHIFT_REGISTER 6'd35
`define EXP_BINARY_COUNTER 6'd36
`define EXP_UP_DOWN_COUNTER 6'd37
`define EXP_MODULO_COUNTER 6'd38
`define EXP_BCD_COUNTER 6'd39
`define EXP_RING_COUNTER 6'd40
`define EXP_JOHNSON_COUNTER 6'd41
`define EXP_LFSR 6'd42

`endif
