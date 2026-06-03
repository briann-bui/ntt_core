// =============================================================================
// Module: ntt_addr_gen
// Description: Address generator for NTT butterfly operations.
//              Manages stage counter (0..LOG2N-1) and butterfly counter
//              (0..N/2-1) to produce memory addresses and twiddle index.
//
//              Cooley-Tukey in-place address pattern:
//                For stage s, butterfly i (flattened 0..N/2-1):
//                  half    = 1 << s
//                  group   = i >> s
//                  offset  = i & (half - 1)
//                  addr_a  = (group << (s+1)) | offset
//                  addr_b  = addr_a + half
//                  tw_idx  = offset << (LOG2N - 1 - s)
//
// PRODUCTION NOTE: The exact address and twiddle index mapping must be
// verified against the target NTT variant (Cooley-Tukey / Gentleman-Sande)
// and any required bit-reversal / coefficient permutation for Kyber/Dilithium.
// =============================================================================

module ntt_addr_gen
    import ntt_pkg::*;
#(
    parameter int P_N       = 256,
    parameter int P_ADDR_W  = 8,
    parameter int P_LOG2N   = 8
) (
    input  logic                   i_ntt_clk,
    input  logic                   i_ntt_rst_n,

    // Control interface from FSM
    input  logic                   i_ntt_init,      // Reset counters
    input  logic                   i_ntt_advance,   // Advance to next butterfly

    // Address outputs
    output logic [P_ADDR_W-1:0]    o_ntt_addr_a,
    output logic [P_ADDR_W-1:0]    o_ntt_addr_b,

    // Twiddle ROM index
    output logic [P_LOG2N-2:0]     o_ntt_tw_idx,    // log2(N/2) = LOG2N-1 bits

    // Status
    output logic                   o_ntt_last_op    // Current op is the last one
);

    // -------------------------------------------------------------------------
    // Internal Counters
    // -------------------------------------------------------------------------
    localparam int LP_NUM_BF    = P_N / 2;            // Butterflies per stage
    localparam int LP_BF_CNT_W  = P_LOG2N - 1;       // Butterfly counter width (7 for N=256)
    localparam int LP_STG_CNT_W = $clog2(P_LOG2N);   // Stage counter width (3 for 8 stages)

    // Constants for comparisons and increments
    localparam logic [LP_BF_CNT_W-1:0]  LP_BF_MAX  = LP_BF_CNT_W'(LP_NUM_BF - 1);
    localparam logic [LP_STG_CNT_W-1:0] LP_STG_MAX = LP_STG_CNT_W'(P_LOG2N - 1);

    logic [LP_BF_CNT_W-1:0]  r_bf_cnt;    // Butterfly index within stage
    logic [LP_STG_CNT_W-1:0] r_stage;     // Current stage

    // -------------------------------------------------------------------------
    // Counter Logic
    // -------------------------------------------------------------------------
    always_ff @(posedge i_ntt_clk or negedge i_ntt_rst_n) begin
        if (!i_ntt_rst_n) begin
            r_bf_cnt <= '0;
            r_stage  <= '0;
        end else if (i_ntt_init) begin
            r_bf_cnt <= '0;
            r_stage  <= '0;
        end else if (i_ntt_advance) begin
            if (r_bf_cnt == LP_BF_MAX) begin
                // Last butterfly in stage — advance stage, reset butterfly
                r_bf_cnt <= '0;
                r_stage  <= r_stage + {{(LP_STG_CNT_W-1){1'b0}}, 1'b1};
            end else begin
                r_bf_cnt <= r_bf_cnt + {{(LP_BF_CNT_W-1){1'b0}}, 1'b1};
            end
        end
    end

    // -------------------------------------------------------------------------
    // Address Computation (Combinational)
    //
    // Cooley-Tukey in-place pattern:
    //   half   = 1 << stage
    //   group  = bf_cnt >> stage        (which group this butterfly belongs to)
    //   offset = bf_cnt & (half - 1)    (position within group)
    //   addr_a = (group << (stage+1)) | offset
    //   addr_b = addr_a + half
    // -------------------------------------------------------------------------
    logic [P_ADDR_W-1:0] w_half;
    logic [P_ADDR_W-1:0] w_group;
    logic [P_ADDR_W-1:0] w_offset;
    logic [P_ADDR_W-1:0] w_addr_a;

    always_comb begin
        w_half   = {{(P_ADDR_W-1){1'b0}}, 1'b1} << r_stage;
        w_group  = {{(P_ADDR_W-LP_BF_CNT_W){1'b0}}, r_bf_cnt} >> r_stage;
        w_offset = {{(P_ADDR_W-LP_BF_CNT_W){1'b0}}, r_bf_cnt} & (w_half - {{(P_ADDR_W-1){1'b0}}, 1'b1});

        w_addr_a = (w_group << (r_stage + {{(LP_STG_CNT_W-1){1'b0}}, 1'b1})) | w_offset;

        o_ntt_addr_a = w_addr_a;
        o_ntt_addr_b = w_addr_a + w_half;
    end

    // -------------------------------------------------------------------------
    // Twiddle Index Computation
    //
    // tw_idx = offset << (LOG2N - 1 - stage)
    //
    // PRODUCTION NOTE: This mapping assumes standard Cooley-Tukey ordering.
    // Verify against Kyber/Dilithium spec for correct twiddle indexing.
    // -------------------------------------------------------------------------
    always_comb begin
        o_ntt_tw_idx = w_offset[P_LOG2N-2:0] << (P_LOG2N - 1 - r_stage);
    end

    // -------------------------------------------------------------------------
    // Last Operation Flag
    // Asserted when processing the final butterfly of the final stage
    // -------------------------------------------------------------------------
    always_comb begin
        o_ntt_last_op = (r_stage == LP_STG_MAX) &&
                        (r_bf_cnt == LP_BF_MAX);
    end

endmodule : ntt_addr_gen
