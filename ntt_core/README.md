# NTT Engine Core (Number Theoretic Transform)

## Overview
This repository contains a **SystemVerilog RTL skeleton** for a Number Theoretic Transform (NTT) Engine Core, targeted at post-quantum cryptography applications such as Kyber and Dilithium. 

The design implements a fully digital, synthesizable datapath and controller for computing the NTT using the Cooley-Tukey decimation-in-time algorithm. It operates on polynomial coefficients stored in an external dual-port memory.

> [!WARNING]  
> **Production Silicon Caveat:** This is an architectural skeleton meant for synthesis, timing, and integration analysis. It is **NOT** a production-ready Kyber/Dilithium NTT implementation yet. See the [Production Caveats](#production-caveats) section below.

## Key Features
*   **Pure SystemVerilog:** Written in IEEE 1800-2017 standard SystemVerilog.
*   **Synthesizable:** Free of latches, `initial` blocks, and non-synthesizable constructs. Designed for ASIC/FPGA toolchains.
*   **Modular Architecture:** Clean separation of Datapath, FSM Controller, Address Generator, and Arithmetic Units.
*   **Configurable:** Parameterized for Number of Coefficients ($N$), Prime Modulus ($Q$), and bit-widths.
*   **Memory Interface:** Simple dual-port SRAM interface for reading/writing coefficients.

## Directory Structure
```text
ntt_core/
└── rtl/
    ├── ntt_pkg.sv             # Shared parameters, enums, typedefs
    ├── ntt_core.sv            # Top-level integration
    ├── ntt_ctrl.sv            # Main FSM controller
    ├── ntt_datapath.sv        # Pipeline and butterfly integration
    ├── ntt_addr_gen.sv        # Cooley-Tukey memory address generation
    ├── ntt_butterfly_unit.sv  # Core NTT arithmetic computation
    ├── ntt_mod_add.sv         # Modular addition
    ├── ntt_mod_sub.sv         # Modular subtraction
    ├── ntt_mod_mul.sv         # Modular multiplication
    ├── ntt_mod_reduce.sv      # Modular reduction (modulo Q)
    └── ntt_twiddle_rom.sv     # Twiddle factor ROM
```

## Parameters
Defined in `ntt_pkg.sv` and propagated to `ntt_core.sv`:

| Parameter | Default | Description |
| :--- | :--- | :--- |
| `P_N` | 256 | Number of polynomial coefficients (Kyber default) |
| `P_Q` | 3329 | Prime modulus (Kyber default) |
| `P_COEFF_W` | 16 | Bit-width of the polynomial coefficients |
| `P_ADDR_W` | 8 | Memory address width ($\log_2(P\_N)$) |

## Interface

### Control & Status
| Port | Direction | Description |
| :--- | :--- | :--- |
| `i_ntt_clk` | Input | Core clock |
| `i_ntt_rst_n` | Input | Active-low asynchronous reset |
| `i_ntt_start` | Input | Start pulse to begin NTT operation |
| `i_ntt_mode[1:0]` | Input | Operation mode (see below) |
| `o_ntt_busy` | Output | High while the core is processing |
| `o_ntt_done` | Output | 1-cycle pulse upon successful completion |
| `o_ntt_error` | Output | High if an unsupported mode is requested |

### External Dual-Port Memory Interface
The core expects an external dual-port memory to fetch and store coefficients.

| Port | Direction | Description |
| :--- | :--- | :--- |
| `o_ntt_mem_rd_en` | Output | Memory read enable |
| `o_ntt_mem_wr_en` | Output | Memory write enable |
| `o_ntt_mem_addr_a` | Output | Address for Port A (Read/Write) |
| `o_ntt_mem_addr_b` | Output | Address for Port B (Read/Write) |
| `i_ntt_mem_rdata_a` | Input | Read data from Port A |
| `i_ntt_mem_rdata_b` | Input | Read data from Port B |
| `o_ntt_mem_wdata_a` | Output | Write data for Port A |
| `o_ntt_mem_wdata_b` | Output | Write data for Port B |

## Operation Modes
Modes are passed via the `i_ntt_mode` signal:

*   `2'b00` (`MODE_IDLE`): Idle / No operation.
*   `2'b01` (`MODE_FWD_NTT`): Forward NTT.
*   `2'b10` (`MODE_INV_NTT`): Inverse NTT *(Placeholder, triggers Error)*
*   `2'b11` (`MODE_POINTWISE`): Pointwise Multiplication *(Placeholder, triggers Error)*

## Architecture & FSM

The `ntt_ctrl` module manages an 8-state FSM that pipelines reads, computes, and writes to the external memory. 

**State Flow:**
`IDLE` $\rightarrow$ `INIT` $\rightarrow$ `READ` $\rightarrow$ `COMPUTE` $\rightarrow$ `WRITE` $\rightarrow$ `NEXT` (loops back to `READ` until all stages are complete) $\rightarrow$ `DONE` $\rightarrow$ `IDLE`

**Datapath:**
The datapath registers incoming `rdata`, fetches the corresponding Twiddle factor from the ROM, and computes the Butterfly operations entirely combinationally via instances of modular add/sub/mul modules.

## Production Caveats
To upgrade this IP for production silicon (ASIC/FPGA tapeout), the following changes **must** be implemented:

1.  **Twiddle Factor ROM (`ntt_twiddle_rom.sv`):** Currently a placeholder with limited illustrative values. You must generate and populate the full lookup table with the correct powers of $\zeta$ (primitive 256th root of unity modulo $Q$, e.g., $\zeta = 17$ for Kyber).
2.  **Modular Reduction (`ntt_mod_reduce.sv`):** Currently uses the generic `%` modulo operator. While synthesizable, it infers large generic dividers. Replace this with a **Barrett Reduction** or **Montgomery Reduction** logic for required clock speeds and PPA (Power, Performance, Area).
3.  **Coefficient Ordering:** The address generator implements standard Cooley-Tukey. You must verify if bit-reversal input/output permutations are required by your specific algorithm specification.
4.  **Verification:** Implement a rigorous UVM/SystemVerilog testbench utilizing known-answer-tests (KATs) from the NIST PQC reference implementations.
