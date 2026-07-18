module apb_ntt_core
  import apb_ntt_pkg::*;
  #(
    parameter int N = 256,
    parameter int Q = 3329,
    parameter int ROOT = 17,
    parameter int COEFF_WIDTH = 16,
    parameter int ADDR_WIDTH = 8
  ) (
    input  logic                    i_ntt_clk,
    input  logic                    i_ntt_rst_n,

    input  logic                    i_ntt_start,
    input  logic [1:0]              i_ntt_mode,
    output logic                   o_ntt_busy,
    output logic                   o_ntt_done,
    output logic                   o_ntt_error,

    output logic                   o_ntt_mem_rd_en,
    output logic                   o_ntt_mem_wr_en,
    input  logic                    i_ntt_mem_rd_valid,
    input  logic                    i_ntt_mem_wr_ready,
    output logic [ADDR_WIDTH-1:0]  o_ntt_mem_addr_a,
    output logic [ADDR_WIDTH-1:0]  o_ntt_mem_addr_b,
    output logic [COEFF_WIDTH-1:0] o_ntt_mem_wdata_a,
    output logic [COEFF_WIDTH-1:0] o_ntt_mem_wdata_b,
    input  logic [COEFF_WIDTH-1:0]  i_ntt_mem_rdata_a,
    input  logic [COEFF_WIDTH-1:0]  i_ntt_mem_rdata_b
  );

  localparam int LOG2_N = $clog2(N);

  logic          w_ag_init;
  logic          w_ag_advance;

  logic          w_last_op;

  logic          w_dp_capture;

  logic [ADDR_WIDTH-1:0] w_addr_a;
  logic [ADDR_WIDTH-1:0] w_addr_b;
  logic [LOG2_N-2:0]     w_tw_idx;

  logic [COEFF_WIDTH-1:0] w_wdata_a;
  logic [COEFF_WIDTH-1:0] w_wdata_b;

  apb_ntt_controller u_ntt_controller (
    .i_ntt_clk        (i_ntt_clk),
    .i_ntt_rst_n      (i_ntt_rst_n),

    .i_ntt_start      (i_ntt_start),
    .i_ntt_mode       (i_ntt_mode),

    .o_ntt_busy       (o_ntt_busy),
    .o_ntt_done       (o_ntt_done),
    .o_ntt_error      (o_ntt_error),

    .o_ntt_mem_rd_en  (o_ntt_mem_rd_en),
    .o_ntt_mem_wr_en  (o_ntt_mem_wr_en),
    .i_ntt_mem_rd_valid(i_ntt_mem_rd_valid),
    .i_ntt_mem_wr_ready(i_ntt_mem_wr_ready),

    .o_ntt_dp_capture (w_dp_capture),

    .o_ntt_ag_init    (w_ag_init),
    .o_ntt_ag_advance (w_ag_advance),

    .i_ntt_last_op    (w_last_op)
  );

  apb_ntt_address_generator #(
    .N      (N),
    .ADDR_WIDTH (ADDR_WIDTH),
    .LOG2_N  (LOG2_N)
  ) u_ntt_address_generator (
    .i_ntt_clk      (i_ntt_clk),
    .i_ntt_rst_n    (i_ntt_rst_n),

    .i_ntt_init     (w_ag_init),
    .i_ntt_advance  (w_ag_advance),

    .o_ntt_addr_a   (w_addr_a),
    .o_ntt_addr_b   (w_addr_b),
    .o_ntt_tw_idx   (w_tw_idx),
    .o_ntt_last_op  (w_last_op)
  );

  apb_ntt_datapath #(
    .N       (N),
    .Q       (Q),
    .ROOT    (ROOT),
    .COEFF_WIDTH (COEFF_WIDTH),
    .LOG2_N   (LOG2_N)
  ) u_ntt_datapath (
    .i_ntt_clk      (i_ntt_clk),
    .i_ntt_rst_n    (i_ntt_rst_n),

    .i_ntt_capture  (w_dp_capture),

    .i_ntt_rdata_a  (i_ntt_mem_rdata_a),
    .i_ntt_rdata_b  (i_ntt_mem_rdata_b),

    .i_ntt_tw_idx   (w_tw_idx),

    .o_ntt_wdata_a  (w_wdata_a),
    .o_ntt_wdata_b  (w_wdata_b)
  );

  assign o_ntt_mem_addr_a  = w_addr_a;
  assign o_ntt_mem_addr_b  = w_addr_b;

  assign o_ntt_mem_wdata_a = w_wdata_a;
  assign o_ntt_mem_wdata_b = w_wdata_b;

endmodule
