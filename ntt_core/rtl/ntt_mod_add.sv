// =============================================================================
// Module: ntt_mod_add
// Description: Modular addition: result = (a + b) mod q
//              If (a + b) >= q, subtract q. Pure combinational.
// =============================================================================

module ntt_mod_add #(
    parameter int P_COEFF_W = 16,
    parameter int P_Q       = 3329
) (
    input  logic [P_COEFF_W-1:0] i_ntt_a,
    input  logic [P_COEFF_W-1:0] i_ntt_b,
    output logic [P_COEFF_W-1:0] o_ntt_result
);

    // Constant for modular comparison/subtraction
    localparam logic [P_COEFF_W-1:0] LP_Q = P_COEFF_W'(P_Q);

    // Internal sum needs one extra bit to detect overflow past q
    logic [P_COEFF_W:0] w_sum;

    always_comb begin
        w_sum = {1'b0, i_ntt_a} + {1'b0, i_ntt_b};

        if (w_sum >= {1'b0, LP_Q}) begin
            o_ntt_result = w_sum[P_COEFF_W-1:0] - LP_Q;
        end else begin
            o_ntt_result = w_sum[P_COEFF_W-1:0];
        end
    end

endmodule : ntt_mod_add
