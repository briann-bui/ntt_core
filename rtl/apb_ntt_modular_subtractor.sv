module apb_ntt_modular_subtractor #(
  parameter int COEFF_WIDTH = 16,
  parameter int Q = 3329
) (
  input  logic [COEFF_WIDTH-1:0]  i_ntt_a,
  input  logic [COEFF_WIDTH-1:0]  i_ntt_b,
  output logic [COEFF_WIDTH-1:0] o_ntt_result
);

  localparam logic [COEFF_WIDTH-1:0] Q_VALUE = COEFF_WIDTH'(Q);

  always_comb begin
    if (i_ntt_a >= i_ntt_b) begin
      o_ntt_result = i_ntt_a - i_ntt_b;
    end else begin
      o_ntt_result = i_ntt_a + Q_VALUE - i_ntt_b;
    end
  end

endmodule
