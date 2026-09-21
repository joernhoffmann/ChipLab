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

23. D latch
24. D flip-flop
25. T flip-flop
26. JK flip-flop
27. D flip-flop - comparison with the D latch
28. Synchronous and asynchronous reset
29. Register with enable
30. Register with parallel load, hold, and clear
31. Small read/write memory
32. Accumulator (with ALU, result register, and feedback)
33. FIFO: 4 × 4 bits, oldest entry first
34. Stack: 4 × 4 bits, newest entry first

## 5. Shift Registers and Counters

35. Shift register
36. Universal shift register (parallel load and left/right shift)
37. Binary counter
38. Up/down counter
39. Modulo counter
40. BCD counter
41. Ring counter
42. Johnson counter
43. Linear-feedback shift register (LFSR)

## 6. Input Synchronization and Timing

44. Edge detection and pulse generation
45. Synchronization of asynchronous inputs
46. Push-button debouncing
47. Clock division using clock enable
48. Pulse-width modulation (PWM)

## 7. Finite State Machines

49. Moore release control (IDLE / ACTIVE)
50. Mealy release control (IDLE / ACTIVE, with request)
51. Traffic light controller
52. Handshake controller
53. Parking lot occupancy counter (two sensors, direction detection)

## 8. FSM-Controlled Datapaths

- 54. **Sequential multiplier:** shift-and-add datapath controlled by an FSM.
- 55. **Binarized neural network:** 1–8 neurons sharing XNOR, popcount, and threshold logic.

## 9. Sound

56. **Programmable sound generator:** register bank, tone/noise, decay envelope, PWM

## Design Targets

The target footprint is two tiles (`1x2`). Area and timing must be confirmed by
synthesis and place-and-route.

| Component | Planned size |
|---|---|
| Arithmetic, ALU, and accumulator operands | 4 bits |
| Sequential multiplier | 4 × 4 bits, 8-bit result |
| Binarized neural network | 1–8 neurons, 8 inputs, 8-bit weights and 4-bit thresholds per neuron |
| Registers and counters | 4 or 8 bits |
| Read/write memory | 4 words × 4 bits |
| FIFO and stack | 4 entries × 4 bits each |

Related experiments may share arithmetic units, display decoders, and registers.
Separate circuits are required where comparing their behavior is part of the
experiment. State machines should expose their state for observation.

## Experiment Interface

Experiments 1–56 are implemented. `uio_in[5:0]` selects the experiment using its
number. `uio_in[7:6]` selects an operation where needed. Other codes return zero.
See [the project description](info.md) for pin mappings and behavior.
Clocked storage, timing, and FSM experiments use `clk` and `rst_n`.
The D latches in experiments 23 and 27 have no reset and must be initialized through their gate.

## Implementation Considerations

Latch inference and asynchronous resets require validation in the IHP flow.
Latch data must be stable when the gate closes. RTL simulation does not model analog metastability.
Output selection logic and timer widths contribute to the area budget.
