// =============================================================================
// Module: ntt_core
// Description: Top-level NTT Engine Core.
//              Integrates FSM controller, address generator, and datapath
//              to perform Number Theoretic Transform on polynomial coefficients
//              stored in external dual-port memory.
//
//              This is an architectural/synthesizable skeleton.
//              NOT production-correct for Kyber/Dilithium without:
//                - Verified twiddle factor table
//                - Correct coefficient ordering / bit-reversal
//                - Validated test vectors
//
//              No bus interface (APB/AHB/AXI) or CSR — pure NTT core only.
// =============================================================================

module ntt_core
    import ntt_pkg::*;
#(
    parameter int P_N       = 256,
    parameter int P_Q       = 3329,
    parameter int P_COEFF_W = 16,
    parameter int P_ADDR_W  = 8
) (
    input  logic                    i_ntt_clk,
    input  logic                    i_ntt_rst_n,

    // Control interface
    input  logic                    i_ntt_start,
    input  logic [1:0]              i_ntt_mode,
    output logic                    o_ntt_busy,
    output logic                    o_ntt_done,
    output logic                    o_ntt_error,

    // External memory interface
    output logic                    o_ntt_mem_rd_en,
    output logic                    o_ntt_mem_wr_en,
    output logic [P_ADDR_W-1:0]    o_ntt_mem_addr_a,
    output logic [P_ADDR_W-1:0]    o_ntt_mem_addr_b,
    output logic [P_COEFF_W-1:0]   o_ntt_mem_wdata_a,
    output logic [P_COEFF_W-1:0]   o_ntt_mem_wdata_b,
    input  logic [P_COEFF_W-1:0]   i_ntt_mem_rdata_a,
    input  logic [P_COEFF_W-1:0]   i_ntt_mem_rdata_b
);

    // =========================================================================
    // Derived Parameters
    // =========================================================================
    localparam int LP_LOG2N = $clog2(P_N);  // Number of NTT stages

    // =========================================================================
    // Internal Signals
    // =========================================================================

    // Controller -> Address Generator
    logic w_ag_init;
    logic w_ag_advance;

    // Address Generator -> Controller
    logic w_last_op;

    // Controller -> Datapath
    logic w_dp_capture;

    // Address Generator -> Memory / Datapath
    logic [P_ADDR_W-1:0]   w_addr_a;
    logic [P_ADDR_W-1:0]   w_addr_b;
    logic [LP_LOG2N-2:0]   w_tw_idx;

    // Datapath -> Memory
    logic [P_COEFF_W-1:0]  w_wdata_a;
    logic [P_COEFF_W-1:0]  w_wdata_b;

    // =========================================================================
    // FSM Controller
    // =========================================================================
    ntt_ctrl #(
        .P_N     (P_N),
        .P_LOG2N (LP_LOG2N)
    ) u_ctrl (
        .i_ntt_clk        (i_ntt_clk),
        .i_ntt_rst_n      (i_ntt_rst_n),

        // External control
        .i_ntt_start      (i_ntt_start),
        .i_ntt_mode       (i_ntt_mode),

        // Status
        .o_ntt_busy       (o_ntt_busy),
        .o_ntt_done       (o_ntt_done),
        .o_ntt_error      (o_ntt_error),

        // Memory control
        .o_ntt_mem_rd_en  (o_ntt_mem_rd_en),
        .o_ntt_mem_wr_en  (o_ntt_mem_wr_en),

        // Datapath control
        .o_ntt_dp_capture (w_dp_capture),

        // Address generator control
        .o_ntt_ag_init    (w_ag_init),
        .o_ntt_ag_advance (w_ag_advance),

        // Address generator status
        .i_ntt_last_op    (w_last_op)
    );

    // =========================================================================
    // Address Generator
    // =========================================================================
    ntt_addr_gen #(
        .P_N      (P_N),
        .P_ADDR_W (P_ADDR_W),
        .P_LOG2N  (LP_LOG2N)
    ) u_addr_gen (
        .i_ntt_clk      (i_ntt_clk),
        .i_ntt_rst_n    (i_ntt_rst_n),

        // Control
        .i_ntt_init     (w_ag_init),
        .i_ntt_advance  (w_ag_advance),

        // Outputs
        .o_ntt_addr_a   (w_addr_a),
        .o_ntt_addr_b   (w_addr_b),
        .o_ntt_tw_idx   (w_tw_idx),
        .o_ntt_last_op  (w_last_op)
    );

    // =========================================================================
    // Datapath (includes twiddle ROM + butterfly unit)
    // =========================================================================
    ntt_datapath #(
        .P_N       (P_N),
        .P_Q       (P_Q),
        .P_COEFF_W (P_COEFF_W),
        .P_LOG2N   (LP_LOG2N)
    ) u_datapath (
        .i_ntt_clk      (i_ntt_clk),
        .i_ntt_rst_n    (i_ntt_rst_n),

        // Control
        .i_ntt_capture  (w_dp_capture),

        // Memory read data
        .i_ntt_rdata_a  (i_ntt_mem_rdata_a),
        .i_ntt_rdata_b  (i_ntt_mem_rdata_b),

        // Twiddle index
        .i_ntt_tw_idx   (w_tw_idx),

        // Butterfly results
        .o_ntt_wdata_a  (w_wdata_a),
        .o_ntt_wdata_b  (w_wdata_b)
    );

    // =========================================================================
    // Memory Address and Write Data Routing
    // =========================================================================
    // Addresses come directly from the address generator
    assign o_ntt_mem_addr_a  = w_addr_a;
    assign o_ntt_mem_addr_b  = w_addr_b;

    // Write data comes from the datapath butterfly output
    assign o_ntt_mem_wdata_a = w_wdata_a;
    assign o_ntt_mem_wdata_b = w_wdata_b;

endmodule : ntt_core
