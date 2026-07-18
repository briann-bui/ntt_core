module apb_ntt_controller
  import apb_ntt_pkg::*;
  (
   input  logic       i_ntt_clk,
   input  logic       i_ntt_rst_n,

   input  logic       i_ntt_start,
   input  logic [1:0] i_ntt_mode,

   output logic      o_ntt_busy,
   output logic      o_ntt_done,
   output logic      o_ntt_error,

   output logic      o_ntt_mem_rd_en,
   output logic      o_ntt_mem_wr_en,
   input  logic       i_ntt_mem_rd_valid,
   input  logic       i_ntt_mem_wr_ready,

   output logic      o_ntt_dp_capture,

   output logic      o_ntt_ag_init,
   output logic      o_ntt_ag_advance,

   input  logic       i_ntt_last_op
  );

  ntt_state_e r_state, w_next_state;

  always_ff @(posedge i_ntt_clk or negedge i_ntt_rst_n) begin
    if (!i_ntt_rst_n) begin
      r_state <= ST_IDLE;
    end else begin
      r_state <= w_next_state;
    end
  end

  always_comb begin
    w_next_state = r_state;

    case (r_state)
      ST_IDLE: begin
        if (i_ntt_start) begin
          if (i_ntt_mode == MODE_FWD_NTT) begin
            w_next_state = ST_INIT;
          end else if ((i_ntt_mode == MODE_INV_NTT) ||
                       (i_ntt_mode == MODE_POINTWISE)) begin
            w_next_state = ST_ERROR;
          end else begin
            w_next_state = ST_IDLE;
          end
        end
      end

      ST_INIT: begin
        w_next_state = ST_READ;
      end

      ST_READ: begin
        if (i_ntt_mem_rd_valid) begin
          w_next_state = ST_COMPUTE;
        end
      end

      ST_COMPUTE: begin
        w_next_state = ST_WRITE;
      end

      ST_WRITE: begin
        if (i_ntt_mem_wr_ready) begin
          w_next_state = ST_NEXT;
        end
      end

      ST_NEXT: begin
        if (i_ntt_last_op) begin
          w_next_state = ST_DONE;
        end else begin
          w_next_state = ST_READ;
        end
      end

      ST_DONE: begin
        w_next_state = ST_IDLE;
      end

      ST_ERROR: begin
        w_next_state = ST_IDLE;
      end

      default: begin
        w_next_state = ST_ERROR;
      end
    endcase
  end

  always_comb begin
    o_ntt_busy       = 1'b0;
    o_ntt_done       = 1'b0;
    o_ntt_error      = 1'b0;
    o_ntt_mem_rd_en  = 1'b0;
    o_ntt_mem_wr_en  = 1'b0;
    o_ntt_dp_capture = 1'b0;
    o_ntt_ag_init    = 1'b0;
    o_ntt_ag_advance = 1'b0;

    case (r_state)
      ST_IDLE: begin
      end

      ST_INIT: begin
        o_ntt_busy    = 1'b1;
        o_ntt_ag_init = 1'b1;
      end

      ST_READ: begin
        o_ntt_busy      = 1'b1;
        o_ntt_mem_rd_en = 1'b1;
        o_ntt_dp_capture = i_ntt_mem_rd_valid;
      end

      ST_COMPUTE: begin
        o_ntt_busy = 1'b1;
      end

      ST_WRITE: begin
        o_ntt_busy      = 1'b1;
        o_ntt_mem_wr_en = 1'b1;
      end

      ST_NEXT: begin
        o_ntt_busy       = 1'b1;
        o_ntt_ag_advance = !i_ntt_last_op;
      end

      ST_DONE: begin
        o_ntt_done = 1'b1;
      end

      ST_ERROR: begin
        o_ntt_error = 1'b1;
      end

      default: begin
        o_ntt_error = 1'b1;
      end
    endcase
  end

endmodule
