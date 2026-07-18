module apb_ntt_butterfly #(
  parameter int COEFF_WIDTH = 16,
  parameter int Q = 3329
) (
  input  logic [COEFF_WIDTH-1:0]  i_ntt_a,
  input  logic [COEFF_WIDTH-1:0]  i_ntt_b,
  input  logic [COEFF_WIDTH-1:0]  i_ntt_twiddle,
  output logic [COEFF_WIDTH-1:0] o_ntt_y0,
  output logic [COEFF_WIDTH-1:0] o_ntt_y1
);

  logic [COEFF_WIDTH-1:0] w_t;

  apb_ntt_modular_multiplier #(
    .COEFF_WIDTH (COEFF_WIDTH),
    .Q       (Q)
  ) u_ntt_modular_multiplier (
    .i_ntt_a      (i_ntt_b),
    .i_ntt_b      (i_ntt_twiddle),
    .o_ntt_result (w_t)
  );

  apb_ntt_modular_adder #(
    .COEFF_WIDTH (COEFF_WIDTH),
    .Q       (Q)
  ) u_ntt_modular_adder (
    .i_ntt_a      (i_ntt_a),
    .i_ntt_b      (w_t),
    .o_ntt_result (o_ntt_y0)
  );

  apb_ntt_modular_subtractor #(
    .COEFF_WIDTH (COEFF_WIDTH),
    .Q       (Q)
  ) u_ntt_modular_subtractor (
    .i_ntt_a      (i_ntt_a),
    .i_ntt_b      (w_t),
    .o_ntt_result (o_ntt_y1)
  );

endmodule
