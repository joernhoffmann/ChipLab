// SPDX-License-Identifier: Apache-2.0
`default_nettype none
`include "chiplab_experiments.svh"

module chiplab_07_state_machines (
    input wire clk,
    input wire rst_n,
    input wire [5:0] selection,
    input wire [7:0] data,
    
    output wire [7:0] moore_result,
    output wire [7:0] mealy_result,
    output wire [7:0] traffic_result,
    output wire [7:0] handshake_result,
    output wire [7:0] parking_result
);
    wire enable = data[4];
    wire start = data[0];
    wire stop = data[1];
    wire release_request = data[2];
    wire phase_tick = data[0];
    wire request = data[0];
    wire complete = data[1];

    wire enable_moore = (selection == `EXP_MOORE_CONTROL) && enable;
    wire enable_mealy = (selection == `EXP_MEALY_CONTROL) && enable;
    wire enable_traffic = (selection == `EXP_TRAFFIC_LIGHT) && enable;
    wire enable_handshake = (selection == `EXP_HANDSHAKE) && enable;
    wire enable_parking = (selection == `EXP_PARKING_COUNTER) && enable;

    localparam INACTIVE = 1'b0, ACTIVE = 1'b1;


    // ------------------------------------------------------------------------
    // Experiment 48: Moore control
    // Start enters ACTIVE; stop has priority. Release depends only on the state.
    // ------------------------------------------------------------------------
    logic moore_state, moore_next;

    always_comb begin
        moore_next = moore_state;
        case (moore_state)
            INACTIVE: if (start && !stop)
                moore_next = ACTIVE;

            ACTIVE  : if (stop)
                moore_next = INACTIVE;

            default:
                moore_next = INACTIVE;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            moore_state <= INACTIVE;

        else if (enable_moore)
            moore_state <= moore_next;
    end

    wire moore_release = moore_state == ACTIVE;
    assign moore_result = {6'b0, moore_state, moore_release};


    // ------------------------------------------------------------------------
    // Experiment 49: Mealy control
    // While ACTIVE, release follows release_request without waiting for a clock edge.
    // ------------------------------------------------------------------------
    logic mealy_state, mealy_next;

    always_comb begin
        mealy_next = mealy_state;
        case (mealy_state)
            INACTIVE: if (start && !stop)
                mealy_next = ACTIVE;

            ACTIVE: if (stop)
                mealy_next = INACTIVE;

            default:
                mealy_next = INACTIVE;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            mealy_state <= INACTIVE;

        else if (enable_mealy)
            mealy_state <= mealy_next;
    end

    wire mealy_release = (mealy_state == ACTIVE) && release_request;
    assign mealy_result = {6'b0, mealy_state, mealy_release};


    // ------------------------------------------------------------------------
    // Experiment 50: Traffic light controller
    // Each enabled phase tick advances red, red+amber, green, amber.
    // ------------------------------------------------------------------------
    localparam [1:0]
        RED         = 2'd0,
        RED_AMBER   = 2'd1,
        GREEN       = 2'd2,
        AMBER       = 2'd3;
    logic [1:0] traffic_state;
    logic [2:0] lamps;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            traffic_state <= RED;

        else if (enable_traffic && phase_tick) begin
            case (traffic_state)
                RED         : traffic_state <= RED_AMBER;
                RED_AMBER   : traffic_state <= GREEN;
                GREEN       : traffic_state <= AMBER;
                default     : traffic_state <= RED;
            endcase
        end
    end

    always_comb begin
        case (traffic_state)
            RED         : lamps = 3'b001;
            RED_AMBER   : lamps = 3'b011;
            GREEN       : lamps = 3'b100;
            default     : lamps = 3'b010;
        endcase
    end

    // Output
    assign traffic_result = {3'b0, traffic_state, lamps};


    // ------------------------------------------------------------------------
    // Experiment 51: Handshake controller
    // Accept request, wait for complete, then acknowledge until request is low.
    // ------------------------------------------------------------------------
    localparam [1:0]
        IDLE = 2'd0,
        BUSY = 2'd1,
        ACK  = 2'd2;
    logic [1:0] handshake_state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            handshake_state <= IDLE;

        else if (enable_handshake) begin
            case (handshake_state)
                IDLE: if (request)
                    handshake_state <= BUSY;

                BUSY: if (complete)
                    handshake_state <= ACK;

                ACK: if (!request)
                    handshake_state <= IDLE;

                default:
                    handshake_state <= IDLE;
            endcase
        end
    end

    // Output
    assign handshake_result = {4'b0, handshake_state, handshake_state == BUSY, handshake_state == ACK};


    // ------------------------------------------------------------------------
    // Experiment 52: Parking lot counter
    // Sensors A/B detect direction; count only a complete crossing, not a reversal.
    // ------------------------------------------------------------------------
    wire [1:0] sensors = {data[0], data[1]}; // A, B

    // States
    localparam [2:0]
        PARK_IDLE   = 3'd0,
        ENTER_A     = 3'd1,
        ENTER_AB    = 3'd2,
        ENTER_B     = 3'd3,
        EXIT_B      = 3'd4,
        EXIT_AB     = 3'd5,
        EXIT_A      = 3'd6,
        WAIT_CLEAR  = 3'd7;

    // Signals for state machine and events
    logic [2:0] parking_state, parking_next;
    logic [3:0] occupancy;
    logic enter_event, exit_event;
    logic entered, exited;

    // Next state and event logic
    always_comb begin
        parking_next = parking_state;
        enter_event = 1'b0;
        exit_event = 1'b0;

        case (parking_state)
            PARK_IDLE: case (sensors)
                2'b10: parking_next = ENTER_A;
                2'b01: parking_next = EXIT_B;
                2'b11: parking_next = WAIT_CLEAR;
                default: ;
            endcase

            ENTER_A: case (sensors)
                2'b00: parking_next = PARK_IDLE;
                2'b11: parking_next = ENTER_AB;
                2'b01: parking_next = WAIT_CLEAR;
                default: ;
            endcase

            ENTER_AB: case (sensors)
                2'b10: parking_next = ENTER_A;
                2'b01: parking_next = ENTER_B;
                2'b00: parking_next = WAIT_CLEAR;
                default: ;
            endcase

            ENTER_B: case (sensors)
                2'b11: parking_next = ENTER_AB;
                2'b00: begin
                    parking_next = PARK_IDLE;
                    enter_event = 1'b1;
                end
                2'b10: parking_next = WAIT_CLEAR;
                default: ;
            endcase

            EXIT_B: case (sensors)
                2'b00: parking_next = PARK_IDLE;
                2'b11: parking_next = EXIT_AB;
                2'b10: parking_next = WAIT_CLEAR;
                default: ;
            endcase

            EXIT_AB: case (sensors)
                2'b01: parking_next = EXIT_B;
                2'b10: parking_next = EXIT_A;
                2'b00: parking_next = WAIT_CLEAR;
                default: ;
            endcase

            EXIT_A: case (sensors)
                2'b11: parking_next = EXIT_AB;
                2'b00: begin
                    parking_next = PARK_IDLE;
                    exit_event = 1'b1;
                end
                2'b01: parking_next = WAIT_CLEAR;
                default: ;
            endcase

            default:
                if (sensors == 2'b00) begin
                    parking_next = PARK_IDLE;
                end
        endcase
    end

    // FSM state update logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parking_state <= PARK_IDLE;
            occupancy     <= 4'd0;
            entered       <= 1'b0;
            exited        <= 1'b0;
        end

        else begin
            // Clear event pulses each clock, including while paused.
            entered <= 1'b0;
            exited  <= 1'b0;

            // State update
            if (enable_parking) begin
                parking_state <= parking_next;
                entered       <= enter_event;
                exited        <= exit_event;

                if (enter_event && occupancy != 4'd15)
                    occupancy <= occupancy + 4'd1;

                else if (exit_event && occupancy != 4'd0)
                    occupancy <= occupancy - 4'd1;
            end
        end
    end

    // Output: {WAIT_CLEAR, BUSY, EXITED, ENTERED, OCCUPANCY}
    assign parking_result = {parking_state == WAIT_CLEAR, parking_state != PARK_IDLE, exited, entered, occupancy};

    wire _unused = &{data[7:5], data[3], 1'b0};
endmodule
