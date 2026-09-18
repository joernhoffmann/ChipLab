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
8. Dual-priority encoder
9. BCD-to-7-segment decoder
10. Hexadecimal-to-7-segment decoder
11. Binary ↔ Gray code conversion
12. Parity generator and checker
13. Small ROM as a lookup table

## 3. Arithmetic and Data Operations

14. Half adder
15. Full adder
16. 4-bit adder
17. 4-bit subtractor and two’s complement
18. Unsigned comparator
19. Signed comparator
20. Logical and arithmetic shifts
21. Rotation
22. Arithmetic logic unit (ALU)

## 4. Storage Elements and Memory

23. Accumulator (with ALU, result register, and feedback)
24. SR latch
25. D latch
26. D flip-flop - comparison with the D latch
27. T flip-flop
28. JK flip-flop
29. Synchronous and asynchronous reset
30. Register with enable
31. Register with parallel load, hold, and clear
32. Small read/write memory

## 5. Shift Registers and Counters

33. Shift register
34. Universal shift register (parallel load and left/right shift)
35. Binary counter
36. Up/down counter
37. Modulo counter
38. BCD counter
39. Ring counter
40. Johnson counter
41. Linear-feedback shift register (LFSR)

## 6. Input Synchronization and Timing

42. Edge detection and pulse generation
43. Synchronization of asynchronous inputs
44. Push-button debouncing
45. Clock division using clock enable
46. Pulse-width modulation (PWM)

## 7. Finite State Machines

47. Moore sequence detector
48. Mealy sequence detector
49. Traffic light controller
50. Handshake controller

## 8. FSM-Controlled Datapaths

51. Sequential multiplier (shift-and-add datapath controlled by an FSM)

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

Experiments 1–22 are implemented. `uio_in[5:0]` selects the experiment using its
number. `uio_in[7:6]` selects an operation where needed. Other codes return zero.
See [the project description](info.md) for pin mappings and behavior.
Interfaces for later experiments remain to be specified.

## Implementation Considerations

Latch inference and asynchronous resets require validation in the IHP flow.
The SR latch experiment must define the forbidden input combination and discuss
its release behavior. RTL simulation does not model analog metastability.
Output selection logic and timer widths contribute to the area budget.
