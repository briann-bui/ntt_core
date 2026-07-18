module apb_ntt_modular_multiplier #(
  parameter int COEFF_WIDTH = 16,
  parameter int Q = 3329
) (
  input  logic [COEFF_WIDTH-1:0]  i_ntt_a,
  input  logic [COEFF_WIDTH-1:0]  i_ntt_b,
  output logic [COEFF_WIDTH-1:0] o_ntt_result
);

  localparam int PRODUCT_WIDTH = 2 * COEFF_WIDTH;

  logic [PRODUCT_WIDTH-1:0] w_product;

  always_comb begin
    w_product = {{COEFF_WIDTH{1'b0}}, i_ntt_a} * {{COEFF_WIDTH{1'b0}}, i_ntt_b};
  end

  apb_ntt_modular_reducer #(
    .INPUT_WIDTH  (PRODUCT_WIDTH),
    .Q        (Q),
    .OUTPUT_WIDTH (COEFF_WIDTH)
  ) u_ntt_modular_reducer (
    .i_ntt_operand (w_product),
    .o_ntt_result  (o_ntt_result)
  );

endmodule
