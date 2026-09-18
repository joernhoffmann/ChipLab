// SPDX-License-Identifier: Apache-2.0
`default_nettype none

/* verilator lint_off DECLFILENAME */
// ------------------------------------------------------------------------
// Half adder
// Adds two bits: a and b.
// Returns sum and carry.
// ------------------------------------------------------------------------
module chiplab_half_adder (
    input  wire a,
    input  wire b,
    output wire sum,
    output wire carry
);
    // Sum is the XOR of a and b, carry is the AND of a and b
    // Truth table 
    // a b | sum carry
    // 0 0 |  0    0
    // 0 1 |  1    0
    // 1 0 |  1    0
    // 1 1 |  0    1
    assign sum = a ^ b;
    assign carry = a & b;
endmodule

// ------------------------------------------------------------------------
// Full adder
// Adds three bits: a, b, and carry_in.
// Returns sum and carry_out.
// ------------------------------------------------------------------------
module chiplab_full_adder (
    input  wire a,
    input  wire b,
    input  wire carry_in,
    output wire sum,
    output wire carry_out
);
    wire first_sum, first_carry, second_carry;

    // First half adder: add a and b
    chiplab_half_adder first_half_adder (
        .a          (a), 
        .b          (b), 
        .sum        (first_sum), 
        .carry      (first_carry)
    );

    // Second half adder: add first sum and carry_in
    chiplab_half_adder second_half_adder (
        .a          (first_sum), 
        .b          (carry_in), 
        .sum        (sum), 
        .carry      (second_carry)
    );

    // Final carry out is the OR of the two carry outputs
    assign carry_out = first_carry | second_carry;
endmodule

// ------------------------------------------------------------------------
// 4-bit ripple-carry adder
// Adds two 4-bit numbers a and b, with an optional carry_in.
// Returns 4-bit sum, carry_out, and overflow.
// ------------------------------------------------------------------------
module chiplab_adder_4bit (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       carry_in,
    output wire [3:0] sum,
    output wire       carry_out,
    output wire       overflow
);
    wire [4:0] carry;
    assign carry[0] = carry_in;

    // Generate four full adders.
    // Each takes a bit from a and b, along with the carry from the previous adder
    // The carry ripples through the adders, and the final carry_out is taken from the last adder.
    for (genvar i = 0; i < 4; i++) begin : ripple
        chiplab_full_adder full_adder (
            .a          (a[i]), 
            .b          (b[i]), 
            .carry_in   (carry[i]),
            .sum        (sum[i]), 
            .carry_out  (carry[i + 1])
        );
    end

    // Output carry and overflow flags
    assign carry_out = carry[4];
    assign overflow = carry[3] ^ carry[4];
endmodule

// ------------------------------------------------------------------------
// Main module for experiments group 3
// ------------------------------------------------------------------------
module chiplab_03_arithmetic_data (
    input  wire [7:0] data,
    input  wire [1:0] operation,
    output wire [7:0] half_adder_result,
    output wire [7:0] full_adder_result,
    output wire [7:0] adder_result,
    output wire [7:0] subtractor_result,
    output wire [7:0] unsigned_compare_result,
    output wire [7:0] signed_compare_result,
    output logic [7:0] shift_result,
    output wire [7:0] rotate_result,
    output logic [7:0] alu_result
);
    wire [3:0] a = data[3:0];
    wire [3:0] b = data[7:4];

    // ------------------------------------------------------------------------
    // Experiment 14: Half adder
    // Add data[0] and data[1]; return sum in bit 0 and carry in bit 1.
    // ------------------------------------------------------------------------
    wire half_sum, half_carry;
    chiplab_half_adder half_adder (
        .a          (data[0]),          // First input bit
        .b          (data[1]),          // Second input bit
        .sum        (half_sum),         // Sum output of the half adder
        .carry      (half_carry)        // Carry output of the half adder
    );
    assign half_adder_result = {6'b0, half_carry, half_sum};

    // ------------------------------------------------------------------------
    // Experiment 15: Full adder
    // Add data[0], data[1], and carry-in data[2].
    // ------------------------------------------------------------------------
    wire full_sum, full_carry;
    chiplab_full_adder full_adder (
        .a          (data[0]),          // First input bit
        .b          (data[1]),          // Second input bit
        .carry_in   (data[2]),          // Carry-in bit
        .sum        (full_sum),         // Sum output of the full adder
        .carry_out  (full_carry)        // Carry output of the full adder
    );
    assign full_adder_result = {6'b0, full_carry, full_sum};

    // ------------------------------------------------------------------------
    // Experiment 16: 4-bit adder
    // Add a=data[3:0] and b=data[7:4] with four full adders.
    // ------------------------------------------------------------------------
    wire [3:0] add_sum;
    wire add_carry, add_overflow;
    chiplab_adder_4bit adder (
        .a          (a),                    // Operand a: direct from input
        .b          (b),                    // Operand b: direct from input
        .carry_in   (1'b0),                 // Carry-in of 0 for standard addition
        .sum        (add_sum),              // Sum output from the 4-bit adder
        .carry_out  (add_carry),            // Carry-out from the 4-bit adder
        .overflow   (add_overflow)          // Overflow flag for signed addition
    );
    assign adder_result = {2'b0, add_overflow, add_carry, add_sum};

    // ------------------------------------------------------------------------
    // Experiment 17: 4-bit subtractor
    // Calculate a-b as a+(NOT b)+1 using the same 4-bit adder.
    // ------------------------------------------------------------------------
    wire [3:0] difference;
    wire no_borrow, subtract_overflow;
    chiplab_adder_4bit subtractor (
        .a          (a),                    // Operand a: direct from input
        .b          (~b),                   // Operand b: inverted for subtraction
        .carry_in   (1'b1),                 // Carry-in of 1 for two's complement subtraction
        .sum        (difference),           // Sum is now called difference for clarity
        .carry_out  (no_borrow),            // Carry-out indicates if there was no borrow (1 means no borrow, 0 means borrow occurred)
        .overflow   (subtract_overflow)     // Overflow flag for signed subtraction
    );
    assign subtractor_result = {2'b0, subtract_overflow, no_borrow, difference};

    // ------------------------------------------------------------------------
    // Experiment 18: Unsigned comparator
    // Compare a and b; bits 0, 1, and 2 mean less, equal, and greater.
    // ------------------------------------------------------------------------
    assign unsigned_compare_result = {5'b0, a > b, a == b, a < b};

    // ------------------------------------------------------------------------
    // Experiment 19: Signed comparator
    // Interpret a and b as 4-bit two's-complement numbers.
    // ------------------------------------------------------------------------
    wire signed [3:0] signed_a = a;
    wire signed [3:0] signed_b = b;
    assign signed_compare_result = {
        5'b0, signed_a > signed_b, signed_a == signed_b, signed_a < signed_b
    };

    // ------------------------------------------------------------------------
    // Experiment 20: Shifts
    // Shift a by data[5:4]; operation selects left, right, or arithmetic right.
    // ------------------------------------------------------------------------
    always_comb begin
        case (operation)
            2'b00: shift_result = {4'b0, a << data[5:4]};
            2'b01: shift_result = {4'b0, a >> data[5:4]};
            2'b10: shift_result = {4'b0, $signed(a) >>> data[5:4]};
            default: shift_result = 8'b0;
        endcase
    end

    // ------------------------------------------------------------------------
    // Experiment 21: Rotation
    // Rotate a by data[5:4]; operation[0] selects left or right.
    // ------------------------------------------------------------------------
    logic [3:0] rotated_value;
    wire shift_dir = operation[0];
    wire [1:0] shift_amount = data[5:4];
    
    always_comb begin
        // Rotation by re arranging bits based on the operation and shift amount
        case ({shift_dir, shift_amount})
            // Left rotation
            3'b000: rotated_value = a;
            3'b001: rotated_value = {a[2:0], a[3]};
            3'b010: rotated_value = {a[1:0], a[3:2]};
            3'b011: rotated_value = {a[0], a[3:1]};
            
            // Right rotation
            3'b100: rotated_value = a;
            3'b101: rotated_value = {a[0], a[3:1]};
            3'b110: rotated_value = {a[1:0], a[3:2]};
            default: rotated_value = {a[2:0], a[3]};
        endcase
    end
    assign rotate_result = {4'b0, rotated_value};

    // ------------------------------------------------------------------------
    // Experiment 22: ALU
    // Apply add, subtract, AND, or OR to a and b using operation[1:0].
    // ------------------------------------------------------------------------
    wire [3:0] alu_a = a;                               // Operand a: direct from input
    wire [3:0] alu_b = operation == 2'b01 ? ~b : b;     // Operand b: inverted for subtraction
    wire [3:0] alu_sum;
    wire alu_carry, alu_overflow;
    
    // ALU result and flags
    logic [3:0] alu_value;
    logic alu_flag_carry, alu_flag_overflow;
    
    // Instantiate the 4-bit adder for the ALU operations
    chiplab_adder_4bit alu_adder (
        .a          (alu_a), 
        .b          (alu_b), 
        .carry_in   (operation == 2'b01), 
        .sum        (alu_sum),
        .carry_out  (alu_carry), 
        .overflow   (alu_overflow)
    );

    // Main ALU logic to select the operation and set flags
    always_comb begin
        alu_flag_carry = 1'b0;
        alu_flag_overflow = 1'b0;
        
        case (operation)
            // Add 
            2'b00: begin
                alu_value = alu_sum;
                alu_flag_carry = alu_carry;
                alu_flag_overflow = alu_overflow;
            end

            // Subtract
            2'b01: begin
                alu_value = alu_sum;
                alu_flag_carry = alu_carry;
                alu_flag_overflow = alu_overflow;
            end

            // AND
            2'b10: alu_value = a & b;

            // OR
            default: alu_value = a | b;
        endcase

        // Output: [7] = sign bit, [6] = zero flag, [5] = overflow flag, [4] = carry flag, [3:0] = result
        alu_result = {alu_value[3], alu_value == 4'b0, alu_flag_overflow, alu_flag_carry, alu_value[3:0]};
    end
endmodule
