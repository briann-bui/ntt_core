# APB NTT UVM Verification

This directory verifies `apb_ntt_wrapper` through its APB interface.

The regression uses a small `N=8`, `Q=17`, `ROOT=2` configuration. It performs
the following flow:

1. Checks reset status.
2. Loads all coefficients through `COEFF_ADDR` and `COEFF_DATA`.
3. Starts a forward NTT through `CTRL`.
4. Polls `STATUS` for completion and checks the error bit.
5. Reads every output coefficient.
6. Compares all results against an independent SystemVerilog golden model.
7. Clears DONE/IRQ status and verifies the cleared state.
8. Exercises unsupported modes, invalid addresses, busy-access errors, byte
   strobes, status values, multiple coefficient patterns, and all APB registers.

## Directory Tree

```text
uvm/
|-- agent/       # APB item, sequencer, and agent
|-- driver/      # APB master driver
|-- env/         # APB NTT environment
|-- monitor/     # APB transaction monitor
|-- scoreboard/  # Forward NTT reference model and checker
|-- sequences/   # Register access and smoke sequences
|-- tb/          # APB interface, UVM package, and DUT top
`-- tests/       # Base and smoke tests
```

Run from the repository root:

```sh
make uvm_compile
make uvm_run
make uvm UVM_TEST=apb_ntt_smoke_test
make coverage
```

The UVM log and summary are written to `reports/uvm.log` and
`reports/uvm_summary.rpt`. `make coverage` runs both UVM tests, measures VCS
line, condition, FSM, branch, and functional coverage, and fails below 90%.
