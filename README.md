# APB NTT Core

[![RTL Lint](https://github.com/briann-bui/apb-ntt-core/actions/workflows/lint.yml/badge.svg)](https://github.com/briann-bui/apb-ntt-core/actions/workflows/lint.yml)

## Overview

This repository contains a synthesizable SystemVerilog Number Theoretic
Transform (NTT) accelerator with an APB register interface and an internal
coefficient memory. The integration top is `apb_ntt_wrapper`.

The implemented operation is a radix-2 forward cyclic NTT. Inverse NTT and
pointwise multiplication mode values are reserved and currently report an
error.

> [!WARNING]
> This RTL is an integration and verification baseline. Validate the selected
> modulus, root, coefficient ordering, and known-answer vectors before using it
> in a cryptographic product.

## Architecture

```text
APB bus
  |
  v
apb_ntt_wrapper
  |-- apb_ntt_apb_if ------------ CTRL / STATUS / coefficient window / IRQ
  |-- apb_ntt_coefficient_memory - internal dual-port coefficient storage
  `-- apb_ntt_core
      |-- apb_ntt_controller
      |-- apb_ntt_address_generator
      `-- apb_ntt_datapath
          |-- apb_ntt_butterfly
          |-- apb_ntt_twiddle_rom
          `-- modular arithmetic units
```

The APB side loads or reads one coefficient through the indexed coefficient
window. After `START`, the APB interface blocks coefficient data access until
the core completes. The core reads a coefficient pair, computes one butterfly,
and writes the pair back to the internal memory.

## Directory Structure

```text
ntt_core/
|-- rtl/                 # Synthesizable SystemVerilog RTL
|-- lint/                # SpyGlass lint project
|-- cdc/                 # SpyGlass CDC project and constraints
|-- rdc/                 # SpyGlass RDC project and constraints
|-- reports/             # Logs and compact report summaries
|-- filelist.f           # Ordered RTL compile list
|-- Makefile             # Synopsys VCS and SpyGlass flow
`-- README.md
```

The RTL filenames follow the `apb_ntt_<block>.sv` naming rule:

```text
apb_ntt_pkg.sv
apb_ntt_modular_adder.sv
apb_ntt_modular_subtractor.sv
apb_ntt_modular_reducer.sv
apb_ntt_modular_multiplier.sv
apb_ntt_twiddle_rom.sv
apb_ntt_butterfly.sv
apb_ntt_address_generator.sv
apb_ntt_datapath.sv
apb_ntt_controller.sv
apb_ntt_core.sv
apb_ntt_coefficient_memory.sv
apb_ntt_apb_if.sv
apb_ntt_wrapper.sv             # Integration top
```

## APB Interface

`apb_ntt_wrapper` exposes a 32-bit APB interface:

| Port | Direction | Description |
| :--- | :--- | :--- |
| `i_ntt_pclk` | Input | APB and NTT clock |
| `i_ntt_presetn` | Input | Active-low asynchronous reset |
| `i_ntt_paddr` | Input | APB address |
| `i_ntt_psel` | Input | APB peripheral select |
| `i_ntt_penable` | Input | APB access phase |
| `i_ntt_pwrite` | Input | APB write control |
| `i_ntt_pwdata` | Input | APB write data |
| `i_ntt_pstrb` | Input | APB byte write strobes |
| `o_ntt_prdata` | Output | APB read data |
| `o_ntt_pready` | Output | APB ready, currently always high |
| `o_ntt_pslverr` | Output | Invalid or busy-access error |
| `o_ntt_irq` | Output | Sticky DONE or ERROR interrupt |

### Register Map

| Offset | Name | Access | Description |
| :--- | :--- | :--- | :--- |
| `0x00` | `CTRL` | R/W | Bit 0 START, bits 2:1 MODE, bit 3 CLEAR |
| `0x04` | `STATUS` | R | Bit 0 BUSY, bit 1 DONE, bit 2 ERROR |
| `0x08` | `COEFF_ADDR` | R/W | Coefficient memory index |
| `0x0C` | `COEFF_DATA` | R/W | Data at the selected coefficient index |

`START` is a write pulse. `DONE` and `ERROR` are sticky; writing `CTRL.CLEAR=1`
clears both and deasserts the interrupt. Reading or writing `COEFF_DATA`, or
issuing another `START`, while `BUSY=1` returns `PSLVERR=1`.

Mode encoding:

| Value | Mode | Current behavior |
| :--- | :--- | :--- |
| `2'b00` | Idle | No transform |
| `2'b01` | Forward NTT | Implemented |
| `2'b10` | Inverse NTT | Reserved, sets ERROR |
| `2'b11` | Pointwise | Reserved, sets ERROR |

## Parameters

| Parameter | Default | Description |
| :--- | :--- | :--- |
| `C_APB_DATA_WIDTH` | 32 | APB data width |
| `C_APB_ADDR_WIDTH` | 8 | APB address width |
| `N` | 256 | Number of coefficients |
| `Q` | 3329 | Prime modulus |
| `ROOT` | 17 | N-th root used by the cyclic NTT |
| `COEFF_WIDTH` | 16 | Coefficient width |
| `ADDR_WIDTH` | 8 | Coefficient memory address width |

## Synopsys Checks

```sh
make compile   # VCS compile; top is apb_ntt_wrapper
make lint      # SpyGlass RTL lint
make cdc       # SpyGlass CDC analysis
make rdc       # SpyGlass RDC analysis
make uvm       # VCS/UVM APB forward-NTT smoke test
make coverage  # Full UVM regression with a 90% coverage gate
make check     # compile + lint + CDC + RDC + coverage regression
make clean     # remove tool work data, preserve main reports
```

Logs and summaries are generated under `reports/`. `make clean` preserves the
top-level `*.log` and `*_summary.rpt` files.

The inferred coefficient SRAM is intentionally not reset; software must load
all coefficients before asserting `START`. The scoped lint and RDC waiver files
cover only the expected dual-port/unreset SRAM-model findings.

## Production Caveats

1. The forward transform is cyclic radix-2 NTT; algorithm-specific negacyclic
   mapping and coefficient ordering must be validated separately.
2. `ROOT` must have the required order for the chosen `N` and `Q`.
3. Barrett reduction assumes the datapath's bounded input contract.
4. Add standard-specific end-to-end known-answer tests before cryptographic use.

