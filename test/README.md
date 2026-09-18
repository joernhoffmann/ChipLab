# ChipLab Testbench

The ChipLab testbench uses [cocotb](https://docs.cocotb.org/en/stable/) to drive the DUT and check the outputs.
See below to get started or for more information, check the [website](https://tinytapeout.com/hdl/testing/).

## Test Organization

| File | Purpose |
|---|---|
| `tb.v` | Connects the simulator to the public Tiny Tapeout ports |
| `chiplab_helpers.py` | Initializes inputs, waits for settling, checks IO direction, and reports bit-level failures |
| `test_01_basic_gates.py` | Experiment 1: all basic gate truth tables |
| `test_02_boolean_identities.py` | Experiment 2: separate tests for De Morgan’s laws, distributivity, and absorption |
| `test_interface.py` | Selection decoding, unused input bits, and control-input independence |

The experiment tests follow **initialize → apply inputs → wait → check outputs**.
Truth-table columns name the expected functions rather than hiding them in packed
hexadecimal values. Both sides of each identity are checked against their expected
value; comparing the two sides alone would miss identical errors on both outputs.

These experiments are combinational, so no running clock or reset sequence is
needed. The 10 ns wait lets simulation events settle; it is not a measurement of
silicon propagation delay. All tests access only public ports, allowing the same
checks to run against RTL and the gate-level netlist.

Use one file per experiment, numbered according to the experiment plan. Add
future experiments as `test_03_multiplexer.py`, etc., and register them in
`COCOTB_TEST_MODULES` in the Makefile. Sequential experiments should explicitly
provide their required clock and reset sequence. RTL files remain organized by
curriculum block; their numbering is independent of test experiment numbering.

## Setting up

1. Edit [Makefile](Makefile) and modify `PROJECT_SOURCES` to point to your Verilog files.
2. Keep the top module in [tb.v](tb.v) and `info.yaml` consistent (`tt_um_chiplab`).

See [Local Simulation](../docs/local-simulation.md) for Python environment setup.
The tests verify the basic gates and Boolean identities described in the
[project documentation](../docs/info.md).

## How to run

To run the RTL simulation:

```sh
make -B
```

To run only experiment 1 (basic gates):

```sh
make -B COCOTB_TEST_MODULES=test_01_basic_gates
```

To run only experiment 2 (Boolean identities):

```sh
make -B COCOTB_TEST_MODULES=test_02_boolean_identities
```

To run only the absorption test within experiment 2:

```sh
make -B COCOTB_TEST_MODULES=test_02_boolean_identities COCOTB_TEST_FILTER='test_absorption$'
```

To run only the shared interface checks:

```sh
make -B COCOTB_TEST_MODULES=test_interface
```

Each test appears separately in the console summary and `results.xml`. A failed
experiment reports the expression, input byte, output bit, and expected value.

To run gate-level simulation, first harden the project and copy the unpowered IHP
netlist to `gate_level_netlist.v`:

```sh
cp ../runs/wokwi/final/nl/tt_um_chiplab.nl.v gate_level_netlist.v
```

Set `PDK_ROOT` to the directory containing the `ihp-sg13g2` PDK.

Then run:

```sh
make -B GATES=yes
```

If you wish to save the waveform in VCD format instead of FST format, edit tb.v to use `$dumpfile("tb.vcd");` and then run:

```sh
make -B FST=
```

This will generate `tb.vcd` instead of `tb.fst`.

## How to view the waveform file

Using GTKWave

```sh
gtkwave tb.fst tb.gtkw
```

Using Surfer

```sh
surfer tb.fst
```
