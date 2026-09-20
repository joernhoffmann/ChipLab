# Local Simulation

The project uses Icarus Verilog and cocotb for RTL simulation with Python 3.13.
The CI workflow uses Python 3.11. Python dependencies are pinned in `test/requirements.txt`.
GTKWave can be used to inspect waveforms.

## Setup

On Debian, a Python 3.13 installation needs both virtual environment support and
the shared runtime library used by cocotb:

```sh
sudo apt install python3.13-venv libpython3.13
python3.13 -m venv .venv
. .venv/bin/activate
python -m pip install -r test/requirements.txt
```

Run the environment commands from the repository root. If Python 3.13 packages
are unavailable in the distribution, use
[uv](https://docs.astral.sh/uv/getting-started/installation/) instead.
Use a uv-managed Python installation to avoid dependencies on distribution-specific
Python packages. From the repository root:

```sh
uv venv --managed-python --python 3.13 .venv
uv pip install --python .venv/bin/python -r test/requirements.txt
. .venv/bin/activate
```

uv downloads a separate Python interpreter; it does not replace the system Python
or require the Debian/Ubuntu `python3.13-venv` package. If a previous setup left an
incomplete `.venv`, rename that directory before creating the new environment.

Python 3.11 matches CI. Python 3.12 and 3.13 are also listed in the
[cocotb 2.0.1 support matrix](https://docs.cocotb.org/en/v2.0.1/platform_support.html);
Python 3.14 is not listed.

The repository also includes a development container configuration.

## Run the RTL Tests

With the virtual environment active:

```sh
cd test
make -B
```

The simulation produces `results.xml` and `tb.fst` in the `test` directory.
To inspect the waveform with GTKWave:

```sh
gtkwave tb.fst tb.gtkw
```

If Make reports that `cocotb-config` is missing, activate the virtual environment
and install the dependencies from `test/requirements.txt`.

If `find_libpython` cannot locate the Python library with a Debian Python 3.13
installation, check that `libpython3.13` is installed. After installing it, verify
discovery inside the active virtual environment:

```sh
python -m find_libpython
```

The command should print the shared library path. The virtual environment does
not need to be recreated when adding the matching system runtime library.

## Source and Test Configuration

List RTL files in both `info.yaml` (`source_files`) and `test/Makefile`
(`PROJECT_SOURCES`). The top module in `info.yaml` must match the module instantiated
by `test/tb.v`. Each experiment has its own test file: `test/test_01_basic_gates.py`,
`test/test_02_boolean_identities.py`, through `test/test_56_psg.py`. Shared interface checks are in
`test/test_interface.py`. See [the test guide](../test/README.md) for individual
test commands and the test structure.

The current RTL implements sections 1–8 in SystemVerilog.
See [the project description](info.md) for selection codes, pin assignments, and
output functions. The cocotb tests check truth tables, selection decoding, and
control-input independence.

## Lint

From the repository root:

```sh
verilator --lint-only -Wall -Isrc --top-module tt_um_chiplab src/*.sv
```

The RTL module names match their `.sv` filenames. Icarus uses SystemVerilog
2012 mode through the cocotb Makefile; `TOPLEVEL_LANG` remains `verilog` for
SystemVerilog sources.

## Gate-Level Simulation

Gate-level simulation requires a generated netlist and the IHP SG13G2 cell models.
Set `PDK_ROOT` to the directory containing `ihp-sg13g2`, and place the netlist at
`test/gate_level_netlist.v`. From the `test` directory, run:

```sh
make -B GATES=yes
```

RTL simulation checks digital behavior. Synthesis and place-and-route are required
to validate the two-tile area target and timing. The GDS workflow targets IHP26b
with the `ihp-sg13g2` PDK.


## BNN configurations

Experiment 57 defaults to eight neurons. The tests automatically detect the built
neuron count through the NEURON register, including changes to the default in RTL.
No separate test setting is needed. To override the RTL define from the repository
root, with the simulation environment activated:

```sh
make -C test COCOTB_TEST_MODULES=test_57_bnn \
  SIM_BUILD=/tmp/chiplab-bnn-4 COMPILE_ARGS="-I../src -DBNN_NEURON_COUNT=4"
```

Valid counts are 1 through 8, including non-powers of two. The module's `initial`
assertion terminates simulation for invalid counts; it is excluded from synthesis.
Use separate build directories when changing defines to avoid stale simulator binaries.
