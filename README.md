# Systolic Array Accelerator

Parametric 2D systolic array implemented in SystemVerilog for matrix multiplication and CNN convolution workloads.

---

## Directory Layout

```text
systolic-array/
├── rtl/
│   ├── pkg.sv            # Global parameters, types, and data definitions
│   ├── pe.sv             # Processing Element (MAC unit)
│   ├── feeder.sv         # Skewed input data feeder logic
│   ├── ctrl.sv           # Global control state machine
│   └── systolic_array.sv # Top-level PE grid and interface assembly
├── tb/
│   ├── pe_tb.sv          # Individual PE testbench
│   └── sys_tb.sv         # System-level matrix multiply testbench
└── sim/
    └── sys_tb_behav.wcfg # Vivado waveform configuration
```

---

## Module Descriptions

- **`pkg.sv`**: Defines global parameters (data bit-widths, array dimensions) and control signal enumerations.
- **`pe.sv`**: Core Processing Element implementing multiply-accumulate (MAC) logic with registered inputs and outputs for pipelined data movement.
- **`feeder.sv`**: Manages cycle-skewed data alignment to feed matrix inputs into the boundary rows and columns of the array.
- **`ctrl.sv`**: Controls cycle timing across weight-loading, compute execution, and result-draining phases.
- **`systolic_array.sv`**: Top-level module instantiating an N × N grid of PEs linked with feeder and control logic.

---

## Simulation & Waveforms

### Running with Vivado (XSim)

To compile and simulate via command line:

```bash
xvlog -sv rtl/pkg.sv rtl/pe.sv rtl/feeder.sv rtl/ctrl.sv rtl/systolic_array.sv tb/sys_tb.sv
xelab sys_tb -s sys_tb_sim
xsim sys_tb_sim -gui -wcfg sim/sys_tb_behav.wcfg
```

### Waveforms

A pre-configured waveform layout is included at `sim/sys_tb_behav.wcfg`. Open this file inside Vivado Simulator to inspect PE array data propagation, feeder timing, and control state transitions.
