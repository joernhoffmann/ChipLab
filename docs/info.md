# ChipLab

ChipLab is an educational digital logic chip for Tiny Tapeout IHP26b.
The first implemented block covers basic gates and Boolean identities.

## How it works

The design uses synthesizable SystemVerilog. `uio_in[7:0]` selects an experiment.
All bidirectional pins are inputs (`uio_oe = 0`); `uio_out` is zero.
`ui_in[0]`, `ui_in[1]`, and `ui_in[2]` provide A, B, and C.
`ui_in[7:3]` is unused. Results appear on `uo_out[7:0]`.

| Selection | Experiment |
|---|---|
| `0x01` | Basic gates |
| `0x02` | Boolean identities |
| All other codes | All outputs zero |

Both experiments are combinational: clock, reset, and enable do not change their
results. Changing the selection immediately selects the corresponding outputs;
there is no stored state. Allow signals to settle before sampling.

| Output bit | Basic gates (`0x01`) | Boolean identities (`0x02`) |
|---|---|---|
| 0 | NOT A | NOT (A AND B) |
| 1 | NOT B | (NOT A) OR (NOT B) |
| 2 | A AND B | NOT (A OR B) |
| 3 | A OR B | (NOT A) AND (NOT B) |
| 4 | A NAND B | A AND (B OR C) |
| 5 | A NOR B | (A AND B) OR (A AND C) |
| 6 | A XOR B | A OR (A AND B) |
| 7 | A XNOR B | A |

In the Boolean experiment, pairs (0, 1) and (2, 3) demonstrate De Morgan’s laws,
(4, 5) demonstrates distributivity, and (6, 7) demonstrates absorption.
Each pair has the same settled output for every input combination. Synthesis may
merge equivalent logic; these experiments compare truth tables, not physical
implementations or propagation delays.

## How to test

Select `0x01` and try all four combinations of A and B. Select `0x02` and try all
eight combinations of A, B, and C; each adjacent output pair must agree.
For example, A = 1, B = 0, C = 0 gives `uo_out = 0x5A` for `0x01`
and `uo_out = 0xC3` for `0x02`.

The cocotb tests cover every input byte for both experiments, all 256 selection
codes, unused inputs, and independence from clock, reset, and enable.
See [Local Simulation](local-simulation.md) for setup and commands, and
[Experiment Plan](experiment-plan.md) for the full curriculum.

## External hardware

Digital switches or a controller can supply the selection and input signals.
Observe outputs with a logic analyzer or an LED interface with suitable drivers
and current limiting. Follow the development board’s I/O voltage requirements.
