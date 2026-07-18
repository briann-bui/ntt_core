module apb_ntt_datapath
  import apb_ntt_pkg::*;
  #(
    parameter int N = 256,
    parameter int Q = 3329,
    parameter int ROOT = 17,
    parameter int COEFF_WIDTH = 16,
    parameter int LOG2_N = 8
  ) (
    input  logic                    i_ntt_clk,
    input  logic                    i_ntt_rst_n,

    input  logic                    i_ntt_capture,

    input  logic [COEFF_WIDTH-1:0]  i_ntt_rdata_a,
    input  logic [COEFF_WIDTH-1:0]  i_ntt_rdata_b,

    input  logic [LOG2_N-2:0]       i_ntt_tw_idx,

    output logic [COEFF_WIDTH-1:0] o_ntt_wdata_a,
    output logic [COEFF_WIDTH-1:0] o_ntt_wdata_b
  );

  logic [COEFF_WIDTH-1:0] r_coeff_a;
  logic [COEFF_WIDTH-1:0] r_coeff_b;
  logic [LOG2_N-2:0]      r_tw_idx;
  logic [COEFF_WIDTH-1:0] w_canonical_a;
  logic [COEFF_WIDTH-1:0] w_canonical_b;

  apb_ntt_modular_reducer #(
    .INPUT_WIDTH  (COEFF_WIDTH),
    .Q        (Q),
    .OUTPUT_WIDTH (COEFF_WIDTH)
  ) u_ntt_input_reducer_a (
    .i_ntt_operand (i_ntt_rdata_a),
    .o_ntt_result  (w_canonical_a)
  );

  apb_ntt_modular_reducer #(
    .INPUT_WIDTH  (COEFF_WIDTH),
    .Q        (Q),
    .OUTPUT_WIDTH (COEFF_WIDTH)
  ) u_ntt_input_reducer_b (
    .i_ntt_operand (i_ntt_rdata_b),
    .o_ntt_result  (w_canonical_b)
  );

  always_ff @(posedge i_ntt_clk or negedge i_ntt_rst_n) begin
    if (!i_ntt_rst_n) begin
      r_coeff_a <= '0;
      r_coeff_b <= '0;
      r_tw_idx  <= '0;
    end else if (i_ntt_capture) begin
      r_coeff_a <= w_canonical_a;
      r_coeff_b <= w_canonical_b;
      r_tw_idx  <= i_ntt_tw_idx;
    end
  end

  logic [COEFF_WIDTH-1:0] w_twiddle;

  apb_ntt_twiddle_rom #(
    .COEFF_WIDTH (COEFF_WIDTH),
    .ADDR_WIDTH  (LOG2_N - 1),
    .Q       (Q),
    .ROOT    (ROOT)
  ) u_ntt_twiddle_rom (
    .i_ntt_addr    (r_tw_idx),
    .o_ntt_twiddle (w_twiddle)
  );

  apb_ntt_butterfly #(
    .COEFF_WIDTH (COEFF_WIDTH),
    .Q       (Q)
  ) u_ntt_butterfly (
    .i_ntt_a       (r_coeff_a),
    .i_ntt_b       (r_coeff_b),
    .i_ntt_twiddle (w_twiddle),
    .o_ntt_y0      (o_ntt_wdata_a),
    .o_ntt_y1      (o_ntt_wdata_b)
  );

endmodule
