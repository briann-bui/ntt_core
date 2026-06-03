// =============================================================================
// Module: ntt_mod_reduce
// Description: Modular reduction: result = operand mod q
//              Skeleton implementation using modulo operator with constant
//              divisor. Synthesis tools will infer a combinational divider
//              circuit for constant modulus.
//
// PRODUCTION NOTE: For production silicon targeting high frequency or low
// area, replace this with Barrett reduction or Montgomery reduction.
// The modulo operator with constant divisor is synthesizable but may
// produce suboptimal PPA (power/performance/area).
// =============================================================================

module ntt_mod_reduce #(
    parameter int P_INPUT_W  = 32,
    parameter int P_Q        = 3329,
    parameter int P_OUTPUT_W = 16
) (
    input  logic [P_INPUT_W-1:0]  i_ntt_operand,
    output logic [P_OUTPUT_W-1:0] o_ntt_result
);

    // -------------------------------------------------------------------------
    // Skeleton: Modulo operator with constant divisor.
    // This IS synthesizable — synthesis tools will elaborate it into a
    // combinational remainder circuit. However, the resulting logic may be
    // large and slow compared to Barrett/Montgomery approaches.
    //
    // For Kyber Q=3329:
    //   Max input = (Q-1)^2 = 3328^2 = 11,075,584 (fits in 24 bits)
    //   Output is guaranteed < Q, fits in 12 bits (P_COEFF_W provides margin)
    // -------------------------------------------------------------------------
    always_comb begin
        o_ntt_result = (i_ntt_operand % P_Q);
    end

endmodule : ntt_mod_reduce
