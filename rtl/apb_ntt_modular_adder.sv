module apb_ntt_modular_adder #(
  parameter int COEFF_WIDTH = 16,
  parameter int Q = 3329
) (
  input  logic [COEFF_WIDTH-1:0]  i_ntt_a,
  input  logic [COEFF_WIDTH-1:0]  i_ntt_b,
  output logic [COEFF_WIDTH-1:0] o_ntt_result
);

  localparam logic [COEFF_WIDTH-1:0] Q_VALUE = COEFF_WIDTH'(Q);

  logic [COEFF_WIDTH:0]              w_sum;

  always_comb begin
    w_sum = {1'b0, i_ntt_a} + {1'b0, i_ntt_b};

    if (w_sum >= {1'b0, Q_VALUE}) begin
      o_ntt_result = w_sum[COEFF_WIDTH-1:0] - Q_VALUE;
    end else begin
      o_ntt_result = w_sum[COEFF_WIDTH-1:0];
    end
  end

endmodule
