module apb_ntt_modular_reducer #(
  parameter int INPUT_WIDTH = 32,
  parameter int Q = 3329,
  parameter int OUTPUT_WIDTH = 16
) (
  input  logic [INPUT_WIDTH-1:0]   i_ntt_operand,
  output logic [OUTPUT_WIDTH-1:0] o_ntt_result
);

  localparam int Q_WIDTH = $clog2(Q);
  localparam int BARRETT_SHIFT = 2 * Q_WIDTH;
  localparam longint unsigned BARRETT_MU =
                              (64'd1 << BARRETT_SHIFT) / Q;
  localparam logic [63:0]     Q_VALUE = Q;

  logic [63:0]                w_operand;
  logic [63:0]                w_scaled;
  logic [63:0]                w_quotient;
  logic [63:0]                w_q_product;
  logic [63:0]                w_remainder;

  always_comb begin
    w_operand   = 64'(i_ntt_operand);
    w_scaled    = w_operand * BARRETT_MU;
    w_quotient  = w_scaled >> BARRETT_SHIFT;
    w_q_product = w_quotient * Q_VALUE;
    w_remainder = w_operand - w_q_product;

    if (w_remainder >= Q_VALUE) begin
      w_remainder = w_remainder - Q_VALUE;
    end

    o_ntt_result = OUTPUT_WIDTH'(w_remainder);
  end

endmodule
