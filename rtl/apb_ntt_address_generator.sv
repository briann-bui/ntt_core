module apb_ntt_address_generator
  import apb_ntt_pkg::*;
  #(
    parameter int N = 256,
    parameter int ADDR_WIDTH = 8,
    parameter int LOG2_N = 8
  ) (
    input  logic                   i_ntt_clk,
    input  logic                   i_ntt_rst_n,

    input  logic                   i_ntt_init,
    input  logic                   i_ntt_advance,

    output logic [ADDR_WIDTH-1:0] o_ntt_addr_a,
    output logic [ADDR_WIDTH-1:0] o_ntt_addr_b,

    output logic [LOG2_N-2:0]     o_ntt_tw_idx,

    output logic                  o_ntt_last_op
  );

  localparam int NUM_BUTTERFLIES    = N / 2;
  localparam int BUTTERFLY_COUNT_WIDTH  = LOG2_N - 1;
  localparam int STAGE_COUNT_WIDTH = $clog2(LOG2_N);

  localparam logic [BUTTERFLY_COUNT_WIDTH-1:0] BUTTERFLY_MAX  = BUTTERFLY_COUNT_WIDTH'(NUM_BUTTERFLIES - 1);
  localparam logic [STAGE_COUNT_WIDTH-1:0]     STAGE_MAX = STAGE_COUNT_WIDTH'(LOG2_N - 1);

  logic [BUTTERFLY_COUNT_WIDTH-1:0]            r_bf_cnt;
  logic [STAGE_COUNT_WIDTH-1:0]                r_stage;
  logic [BUTTERFLY_COUNT_WIDTH-1:0]            w_next_bf_cnt;
  logic [STAGE_COUNT_WIDTH-1:0]                w_next_stage;

  always_ff @(posedge i_ntt_clk or negedge i_ntt_rst_n) begin
    if (!i_ntt_rst_n) begin
      r_bf_cnt <= '0;
      r_stage  <= '0;
    end else begin
      r_bf_cnt <= w_next_bf_cnt;
      r_stage  <= w_next_stage;
    end
  end

  always_comb begin
    w_next_bf_cnt = r_bf_cnt;
    w_next_stage  = r_stage;

    if (i_ntt_init) begin
      w_next_bf_cnt = '0;
      w_next_stage  = '0;
    end else if (i_ntt_advance) begin
      if (r_bf_cnt == BUTTERFLY_MAX) begin
        w_next_bf_cnt = '0;
        w_next_stage  = r_stage + {{(STAGE_COUNT_WIDTH-1){1'b0}}, 1'b1};
      end else begin
        w_next_bf_cnt = r_bf_cnt + {{(BUTTERFLY_COUNT_WIDTH-1){1'b0}}, 1'b1};
      end
    end
  end

  logic [ADDR_WIDTH-1:0] w_half;
  logic [ADDR_WIDTH-1:0] w_group;
  logic [ADDR_WIDTH-1:0] w_offset;
  logic [ADDR_WIDTH-1:0] w_addr_a;

  always_comb begin
    w_half   = {{(ADDR_WIDTH-1){1'b0}}, 1'b1} << r_stage;
    w_group  = {{(ADDR_WIDTH-BUTTERFLY_COUNT_WIDTH){1'b0}}, r_bf_cnt} >> r_stage;
    w_offset = {{(ADDR_WIDTH-BUTTERFLY_COUNT_WIDTH){1'b0}}, r_bf_cnt} & (w_half - {{(ADDR_WIDTH-1){1'b0}}, 1'b1});

    w_addr_a = (w_group << (r_stage + {{(STAGE_COUNT_WIDTH-1){1'b0}}, 1'b1})) | w_offset;

    o_ntt_addr_a = w_addr_a;
    o_ntt_addr_b = w_addr_a + w_half;
  end

  always_comb begin
    o_ntt_tw_idx = w_offset[LOG2_N-2:0] << (LOG2_N - 1 - r_stage);
  end

  always_comb begin
    o_ntt_last_op = (r_stage == STAGE_MAX) &&
                    (r_bf_cnt == BUTTERFLY_MAX);
  end

endmodule
