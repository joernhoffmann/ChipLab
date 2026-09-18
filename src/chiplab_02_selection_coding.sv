// SPDX-License-Identifier: Apache-2.0
`default_nettype none

module chiplab_02_selection_coding (
    input  wire  [7:0] data,
    output wire  [7:0] mux_result,
    output wire  [7:0] demux_result,
    output wire  [7:0] decoder_result,
    output wire  [7:0] encoder_result,
    output wire  [7:0] priority_result,
    output wire  [7:0] dual_priority,
    output wire  [7:0] bcd_segments,
    output wire  [7:0] hex_segments,
    output wire  [7:0] gray_result,
    output wire  [7:0] parity_result,
    output logic [7:0] rom_result
);

    // ------------------------------------------------------------------------
    // Experiment 3: Mux
    // Select one of data[3:0] using data[5:4].
    // ------------------------------------------------------------------------
    wire [1:0] mux_select = data[5:4];
    assign mux_result = {7'b0, data[{1'b0, mux_select}]};

    // ------------------------------------------------------------------------
    // Experiment 4: Demux
    // Route data[0] to one of four outputs using data[2:1].
    // ------------------------------------------------------------------------
    wire [1:0] demux_select = data[2:1];
    assign demux_result = {4'b0, (4'b0001 << demux_select) & {4{data[0]}}};

    // ------------------------------------------------------------------------
    // Experiment 5: Binary decoder
    // Set one output bit for the address in data[2:0].
    // ------------------------------------------------------------------------
    wire [2:0] decoder_select = data[2:0];
    assign decoder_result = 8'b00000001 << decoder_select;
 
    // ------------------------------------------------------------------------
    // Experiment 6: Encoder (one-hot)
    // Encode a single set bit; zero or multiple set bits are invalid.
    // Return valid bit in bit 3, and the encoded value in bits [2:0].
    // ------------------------------------------------------------------------
    // Shared helper for experiments 6-8.
    // Last match wins, so the result is the highest set bit.
    function automatic logic [2:0] highest_bit(input logic [7:0] bits);
        highest_bit = 3'd0;
        for (int i = 0; i < 8; i++)
            if (bits[i])
                highest_bit = 3'(i);
    endfunction
    wire one_hot = (data != 8'b0) && ((data & (data - 8'd1)) == 8'b0);
    assign encoder_result = {4'b0, one_hot, one_hot ? highest_bit(data) : 3'b0};

    // ------------------------------------------------------------------------
    // Experiment 7: Priority encoder
    // Encode the highest set bit; output bit 3 marks a valid result.
    // ------------------------------------------------------------------------
    assign priority_result = {4'b0, |data, highest_bit(data)};

    // ------------------------------------------------------------------------
    // Experiment 8: Dual-priority encoder
    // Find the two highest set bits by calling the same function twice.
    // ------------------------------------------------------------------------
    logic [7:0] remaining;
    logic [2:0] first, second;
    logic first_valid, second_valid;

    always_comb begin
        first_valid = |data;
        first = highest_bit(data);

        // Remove the first match, then reuse the function.
        remaining = data;
        remaining[first] = 1'b0;
        second_valid = |remaining;
        second = highest_bit(remaining);
    end

    assign dual_priority = {second_valid, second, first_valid, first};

    // Shared decoder: active-high segments, bits [6:0] = gfedcba.
    function automatic logic [6:0] seven_segment(input logic [3:0] digit);
        case (digit)
            4'h0: seven_segment = 7'b0111111;   // Digit 0, Segments f, e, d, c, b, a
            4'h1: seven_segment = 7'b0000110;   // Digit 1, Segments b, c
            4'h2: seven_segment = 7'b1011011;   
            4'h3: seven_segment = 7'b1001111;   
            4'h4: seven_segment = 7'b1100110;   
            4'h5: seven_segment = 7'b1101101;   
            4'h6: seven_segment = 7'b1111101;   
            4'h7: seven_segment = 7'b0000111;   // ...
            4'h8: seven_segment = 7'b1111111;   
            4'h9: seven_segment = 7'b1101111;   
            4'hA: seven_segment = 7'b1110111;   
            4'hB: seven_segment = 7'b1111100;   
            4'hC: seven_segment = 7'b0111001;   
            4'hD: seven_segment = 7'b1011110;   
            4'hE: seven_segment = 7'b1111001;   
            4'hF: seven_segment = 7'b1110001;   // Digit F, Segments g, f, e, a

            default: seven_segment = 7'b0;
        endcase
    endfunction

    // ------------------------------------------------------------------------
    // Experiment 9: BCD-to-7-segment decoder
    // Display digits 0-9; values 10-15 blank the display.
    // ------------------------------------------------------------------------
    assign bcd_segments = data[3:0] <= 4'd9 ? hex_segments : 8'b0;

    // ------------------------------------------------------------------------
    // Experiment 10: HEX-to-7-segment decoder
    // Display data[3:0] as 0-9, A, b, C, d, E, or F.
    // ------------------------------------------------------------------------
    assign hex_segments = {1'b0, seven_segment(data[3:0])};

    // ------------------------------------------------------------------------
    // Experiment 11: Binary / Gray conversion
    // data[4] selects the direction: 0 = binary to Gray, 1 = Gray to binary.
    // ------------------------------------------------------------------------
    wire [3:0] binary_value;
    assign binary_value[3] = data[3];
    assign binary_value[2] = ^data[3:2];
    assign binary_value[1] = ^data[3:1];
    assign binary_value[0] = ^data[3:0];
    assign gray_result = {4'b0, data[4] ? binary_value :
                             (data[3:0] ^ {1'b0, data[3:1]})};

    // ------------------------------------------------------------------------
    // Experiment 12: Parity generator and checker
    // Generate even parity for data[6:0] and check the received bit data[7].
    // ------------------------------------------------------------------------
    assign parity_result = {6'b0, ^data, ^data[6:0]};

    // ------------------------------------------------------------------------
    // Experiment 13: ROM
    // Read the ASCII string "ChipLab" and its zero terminator using data[2:0].
    // ------------------------------------------------------------------------
    wire [2:0] rom_address = data[2:0];
    always_comb begin
        case (rom_address)
            3'd0: rom_result = "C";     // 0x43
            3'd1: rom_result = "h";     // 0x68
            3'd2: rom_result = "i";     // 0x69
            3'd3: rom_result = "p";     // 0x70
            3'd4: rom_result = "L";     // 0x4C
            3'd5: rom_result = "a";     // 0x61
            3'd6: rom_result = "b";     // 0x62
            3'd7: rom_result = 8'h00;   // NULL terminator
            default: rom_result = 8'b0;
        endcase
    end
endmodule
