// =============================================================================
// Module: ntt_mod_mul
// Description: Modular multiplication: result = (a * b) mod q
//              Computes full product, then reduces modulo q.
//              Instances ntt_mod_reduce for the reduction step.
//
// PRODUCTION NOTE: For production silicon, replace the simple multiply +
// reduce with Montgomery multiplication or Barrett multiplication to
// achieve better timing closure and area efficiency.
// =============================================================================

module ntt_mod_mul #(
    parameter int P_COEFF_W = 16,
    parameter int P_Q       = 3329
) (
    input  logic [P_COEFF_W-1:0] i_ntt_a,
    input  logic [P_COEFF_W-1:0] i_ntt_b,
    output logic [P_COEFF_W-1:0] o_ntt_result
);

    // Full product width
    localparam int LP_PROD_W = 2 * P_COEFF_W;

    // Internal full-width product
    logic [LP_PROD_W-1:0] w_product;

    // Compute full product (combinational multiplier)
    always_comb begin
        w_product = {{P_COEFF_W{1'b0}}, i_ntt_a} * {{P_COEFF_W{1'b0}}, i_ntt_b};
    end

    // Reduce product modulo q
    ntt_mod_reduce #(
        .P_INPUT_W  (LP_PROD_W),
        .P_Q        (P_Q),
        .P_OUTPUT_W (P_COEFF_W)
    ) u_mod_reduce (
        .i_ntt_operand (w_product),
        .o_ntt_result  (o_ntt_result)
    );

endmodule : ntt_mod_mul
