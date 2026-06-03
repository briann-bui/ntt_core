// =============================================================================
// Module: ntt_datapath
// Description: NTT datapath — captures memory read data, computes butterfly
//              using twiddle factor from ROM, and presents write-back data.
//
//              Pipeline: Input capture (registered) -> Butterfly (combinational)
//              Results are available one cycle after capture enable.
//
//              Contains: ntt_twiddle_rom, ntt_butterfly_unit
// =============================================================================

module ntt_datapath
    import ntt_pkg::*;
#(
    parameter int P_N       = 256,
    parameter int P_Q       = 3329,
    parameter int P_COEFF_W = 16,
    parameter int P_LOG2N   = 8
) (
    input  logic                    i_ntt_clk,
    input  logic                    i_ntt_rst_n,

    // Control from FSM
    input  logic                    i_ntt_capture,    // Latch input data

    // Memory read data (from external memory)
    input  logic [P_COEFF_W-1:0]   i_ntt_rdata_a,
    input  logic [P_COEFF_W-1:0]   i_ntt_rdata_b,

    // Twiddle factor ROM address (from address generator)
    input  logic [P_LOG2N-2:0]     i_ntt_tw_idx,

    // Butterfly results (to external memory write)
    output logic [P_COEFF_W-1:0]   o_ntt_wdata_a,
    output logic [P_COEFF_W-1:0]   o_ntt_wdata_b
);

    // -------------------------------------------------------------------------
    // Registered Input Stage
    // -------------------------------------------------------------------------
    logic [P_COEFF_W-1:0] r_coeff_a;
    logic [P_COEFF_W-1:0] r_coeff_b;
    logic [P_LOG2N-2:0]   r_tw_idx;

    always_ff @(posedge i_ntt_clk or negedge i_ntt_rst_n) begin
        if (!i_ntt_rst_n) begin
            r_coeff_a <= '0;
            r_coeff_b <= '0;
            r_tw_idx  <= '0;
        end else if (i_ntt_capture) begin
            r_coeff_a <= i_ntt_rdata_a;
            r_coeff_b <= i_ntt_rdata_b;
            r_tw_idx  <= i_ntt_tw_idx;
        end
    end

    // -------------------------------------------------------------------------
    // Twiddle Factor ROM
    // -------------------------------------------------------------------------
    logic [P_COEFF_W-1:0] w_twiddle;

    ntt_twiddle_rom #(
        .P_COEFF_W (P_COEFF_W),
        .P_ADDR_W  (P_LOG2N - 1)
    ) u_twiddle_rom (
        .i_ntt_addr    (r_tw_idx),
        .o_ntt_twiddle (w_twiddle)
    );

    // -------------------------------------------------------------------------
    // Butterfly Unit (Combinational)
    //   y0 = (a + b*twiddle) mod q
    //   y1 = (a - b*twiddle) mod q
    // -------------------------------------------------------------------------
    ntt_butterfly_unit #(
        .P_COEFF_W (P_COEFF_W),
        .P_Q       (P_Q)
    ) u_butterfly (
        .i_ntt_a       (r_coeff_a),
        .i_ntt_b       (r_coeff_b),
        .i_ntt_twiddle (w_twiddle),
        .o_ntt_y0      (o_ntt_wdata_a),
        .o_ntt_y1      (o_ntt_wdata_b)
    );

endmodule : ntt_datapath
