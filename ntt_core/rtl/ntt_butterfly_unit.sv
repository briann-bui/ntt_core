// =============================================================================
// Module: ntt_butterfly_unit
// Description: Cooley-Tukey butterfly computation for NTT.
//              Computes:
//                t  = b * twiddle mod q
//                y0 = (a + t) mod q
//                y1 = (a - t) mod q
//              Pure combinational — instances mod_mul, mod_add, mod_sub.
// =============================================================================

module ntt_butterfly_unit #(
    parameter int P_COEFF_W = 16,
    parameter int P_Q       = 3329
) (
    input  logic [P_COEFF_W-1:0] i_ntt_a,       // Coefficient a
    input  logic [P_COEFF_W-1:0] i_ntt_b,       // Coefficient b
    input  logic [P_COEFF_W-1:0] i_ntt_twiddle,  // Twiddle factor
    output logic [P_COEFF_W-1:0] o_ntt_y0,      // Result a' = a + t
    output logic [P_COEFF_W-1:0] o_ntt_y1       // Result b' = a - t
);

    // Internal wire: t = b * twiddle mod q
    logic [P_COEFF_W-1:0] w_t;

    // -------------------------------------------------------------------------
    // Step 1: Modular multiply — t = b * twiddle mod q
    // -------------------------------------------------------------------------
    ntt_mod_mul #(
        .P_COEFF_W (P_COEFF_W),
        .P_Q       (P_Q)
    ) u_mod_mul (
        .i_ntt_a      (i_ntt_b),
        .i_ntt_b      (i_ntt_twiddle),
        .o_ntt_result (w_t)
    );

    // -------------------------------------------------------------------------
    // Step 2: Modular add — y0 = (a + t) mod q
    // -------------------------------------------------------------------------
    ntt_mod_add #(
        .P_COEFF_W (P_COEFF_W),
        .P_Q       (P_Q)
    ) u_mod_add (
        .i_ntt_a      (i_ntt_a),
        .i_ntt_b      (w_t),
        .o_ntt_result (o_ntt_y0)
    );

    // -------------------------------------------------------------------------
    // Step 3: Modular sub — y1 = (a - t) mod q
    // -------------------------------------------------------------------------
    ntt_mod_sub #(
        .P_COEFF_W (P_COEFF_W),
        .P_Q       (P_Q)
    ) u_mod_sub (
        .i_ntt_a      (i_ntt_a),
        .i_ntt_b      (w_t),
        .o_ntt_result (o_ntt_y1)
    );

endmodule : ntt_butterfly_unit
