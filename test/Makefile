# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

# defaults
SIM ?= icarus
FST ?= -fst # Use more efficient FST format
TOPLEVEL_LANG ?= verilog
SRC_DIR = $(CURDIR)/../src
CUSTOM_COMPILE_DEPS += $(SRC_DIR)/chiplab_experiments.svh
PROJECT_SOURCES = tt_um_chiplab.sv chiplab_01_basic_boolean.sv chiplab_02_selection_coding.sv chiplab_03_arithmetic_data.sv chiplab_04_storage_memory.sv chiplab_05_shift_counters.sv

PROJECT_SOURCES += chiplab_06_input_timing.sv chiplab_07_state_machines.sv chiplab_08_fsm_datapaths.sv

ifneq ($(GATES),yes)

# RTL simulation:
SIM_BUILD				= sim_build/rtl
VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))

else

# Gate level simulation:
SIM_BUILD				= sim_build/gl
COMPILE_ARGS    += -DGL_TEST
COMPILE_ARGS    += -DFUNCTIONAL
COMPILE_ARGS    += -DSIM
VERILOG_SOURCES += $(PDK_ROOT)/ihp-sg13g2/libs.ref/sg13g2_io/verilog/sg13g2_io.v
VERILOG_SOURCES += $(PDK_ROOT)/ihp-sg13g2/libs.ref/sg13g2_stdcell/verilog/sg13g2_stdcell.v

# this gets copied in by the GDS action workflow
VERILOG_SOURCES += $(CURDIR)/gate_level_netlist.v

endif

# Allow sharing configuration between design and testbench via `include`:
COMPILE_ARGS 		+= -I$(SRC_DIR)

# Include the testbench sources:
VERILOG_SOURCES += $(CURDIR)/tb.v
TOPLEVEL = tb

# List test modules to run, separated by commas and without the .py suffix:
TEST_GRP01_GATES 	= test_01_basic_gates,test_02_boolean_identities
TEST_GRP02_SEL		= test_03_multiplexer,test_04_demultiplexer,test_05_binary_decoder,test_06_encoder,test_07_priority_encoder,test_08_dual_priority_encoder,test_09_bcd_decoder,test_10_hex_decoder,test_11_gray_code,test_12_parity,test_13_rom
TEST_GRP03_ARITH 	= test_14_half_adder,test_15_full_adder,test_16_adder_4bit,test_17_subtractor_4bit,test_18_unsigned_comparator,test_19_signed_comparator,test_20_shifts,test_21_rotation,test_22_alu
TEST_GRP04_STORE 	= test_23_sr_latch,test_24_d_latch,test_25_d_flipflop,test_26_t_flipflop,test_27_jk_flipflop,test_28_latch_flipflop,test_29_reset,test_30_register_enable,test_31_register_control,test_32_memory,test_33_accumulator
TEST_OTHER			= test_interface
TEST_GRP05_COUNT = test_34_shift_register,test_35_universal_shift_register,test_36_binary_counter,test_37_up_down_counter,test_38_modulo_counter,test_39_bcd_counter,test_40_ring_counter,test_41_johnson_counter,test_42_lfsr
TEST_GRP06_TIMING = test_43_edge_detection,test_44_synchronizer,test_45_debouncer,test_46_clock_enable,test_47_pwm
TEST_GRP07_FSM = test_48_moore_control,test_49_mealy_control,test_50_traffic_light,test_51_handshake,test_52_parking_counter
TEST_GRP08_DATAPATH = test_53_multiplier
COCOTB_TEST_MODULES = $(TEST_GRP01_GATES),$(TEST_GRP02_SEL),$(TEST_GRP03_ARITH),$(TEST_GRP04_STORE),$(TEST_GRP05_COUNT),$(TEST_GRP06_TIMING),$(TEST_GRP07_FSM),$(TEST_GRP08_DATAPATH),$(TEST_OTHER)

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
