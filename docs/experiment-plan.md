# ChipLab Experiment Plan

ChipLab is an educational digital logic chip for Tiny Tapeout IHP26b.
The experiments cover combinational logic, storage elements, sequential circuits,
and finite state machines with datapaths.

## 1. Basic and Boolean Logic

1. Basic gates: NOT, AND, OR, NAND, NOR, XOR, XNOR
2. Boolean functions and De Morgan’s laws

## 2. Data Selection and Coding

3. Multiplexer
4. Demultiplexer
5. Binary decoder
6. Encoder
7. Priority encoder
8. BCD-to-7-segment decoder
9. Hexadecimal-to-7-segment decoder
10. Binary ↔ Gray code conversion
11. Parity generator and checker
12. Small ROM as a lookup table

## 3. Arithmetic and Data Operations

13. Half adder
14. Full adder
15. 4-bit adder
16. 4-bit subtractor and two’s complement
17. Unsigned comparator
18. Signed comparator
19. Logical and arithmetic shifts
20. Rotation
21. Arithmetic logic unit (ALU)
22. Accumulator — ALU, result register, and feedback

## 4. Storage Elements and Memory

23. SR latch
24. D latch
25. D flip-flop — comparison with the D latch
26. T flip-flop
27. JK flip-flop
28. Synchronous and asynchronous reset
29. Register with enable
30. Register with parallel load, hold, and clear
31. Small read/write memory

## 5. Shift Registers and Counters

32. Shift register
33. Universal shift register — parallel load and left/right shift
34. Binary counter
35. Up/down counter
36. Modulo counter
37. BCD counter
38. Ring counter
39. Johnson counter
40. Linear-feedback shift register (LFSR)

## 6. Input Synchronization and Timing

41. Edge detection and pulse generation
42. Synchronization of asynchronous inputs
43. Push-button debouncing
44. Clock division using clock enable
45. Pulse-width modulation (PWM)

## 7. Finite State Machines

46. Moore sequence detector
47. Mealy sequence detector
48. Traffic light controller
49. Handshake controller

## 8. FSM-Controlled Datapaths

50. Sequential multiplier — shift-and-add datapath controlled by an FSM

## Design Targets

The target footprint is two tiles (`1x2`). Area and timing must be confirmed by
synthesis and place-and-route.

| Component | Planned size |
|---|---|
| Arithmetic, ALU, and accumulator operands | 4 bits |
| Sequential multiplier | 4 × 4 bits, 8-bit result |
| Registers and counters | 4 or 8 bits |
| Read/write memory | 4 words × 4 bits |

Related experiments may share arithmetic units, display decoders, and registers.
Separate circuits are required where comparing their behavior is part of the
experiment. State machines should expose their state for observation.

## Experiment Interface

Experiment selection is planned through `uio_in[7:0]`. The experiment numbers
above indicate teaching order; selection codes are not yet assigned. Each
experiment requires a pin mapping, control inputs, and an output representation.
Reset behavior, experiment switching, invalid selection codes, clock frequency,
and timer intervals remain to be specified.

## Implementation Considerations

Latch inference and asynchronous resets require validation in the IHP flow.
The SR latch experiment must define the forbidden input combination and discuss
its release behavior. RTL simulation does not model analog metastability.
Output selection logic and timer widths contribute to the area budget.
