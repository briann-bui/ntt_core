// =============================================================================
// Module: ntt_mod_sub
// Description: Modular subtraction: result = (a - b) mod q
//              If a >= b: result = a - b
//              If a <  b: result = a + q - b
//              Pure combinational.
// =============================================================================

module ntt_mod_sub #(
    parameter int P_COEFF_W = 16,
    parameter int P_Q       = 3329
) (
    input  logic [P_COEFF_W-1:0] i_ntt_a,
    input  logic [P_COEFF_W-1:0] i_ntt_b,
    output logic [P_COEFF_W-1:0] o_ntt_result
);

    // Constant for modular correction
    localparam logic [P_COEFF_W-1:0] LP_Q = P_COEFF_W'(P_Q);

    always_comb begin
        if (i_ntt_a >= i_ntt_b) begin
            o_ntt_result = i_ntt_a - i_ntt_b;
        end else begin
            o_ntt_result = i_ntt_a + LP_Q - i_ntt_b;
        end
    end

endmodule : ntt_mod_sub
