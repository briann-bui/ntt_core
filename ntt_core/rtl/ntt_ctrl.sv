// =============================================================================
// Module: ntt_ctrl
// Description: FSM controller for NTT Engine Core.
//              Manages the state machine that sequences memory reads,
//              butterfly computations, and memory writes across all stages.
//
//              State flow:
//                IDLE -> INIT -> READ -> COMPUTE -> WRITE -> NEXT
//                  ^                                          |
//                  |  (last_op)  DONE <-----------------------+
//                  +------------- DONE                  (more ops)
//                                                        -> READ
//
//              ERROR state is entered on unsupported mode.
// =============================================================================

module ntt_ctrl
    import ntt_pkg::*;
#(
    parameter int P_N      = 256,
    parameter int P_LOG2N  = 8
) (
    input  logic        i_ntt_clk,
    input  logic        i_ntt_rst_n,

    // External control
    input  logic        i_ntt_start,
    input  logic [1:0]  i_ntt_mode,

    // Status outputs
    output logic        o_ntt_busy,
    output logic        o_ntt_done,
    output logic        o_ntt_error,

    // Memory control outputs
    output logic        o_ntt_mem_rd_en,
    output logic        o_ntt_mem_wr_en,

    // Datapath control
    output logic        o_ntt_dp_capture,   // Latch memory read data

    // Address generator control
    output logic        o_ntt_ag_init,      // Reset addr gen counters
    output logic        o_ntt_ag_advance,   // Advance to next butterfly

    // Status from address generator
    input  logic        i_ntt_last_op       // Last butterfly of last stage
);

    // -------------------------------------------------------------------------
    // FSM State Register
    // -------------------------------------------------------------------------
    ntt_state_e r_state, w_next_state;

    // Registered mode capture
    logic [1:0] r_mode;

    // -------------------------------------------------------------------------
    // State Register
    // -------------------------------------------------------------------------
    always_ff @(posedge i_ntt_clk or negedge i_ntt_rst_n) begin
        if (!i_ntt_rst_n) begin
            r_state <= ST_IDLE;
        end else begin
            r_state <= w_next_state;
        end
    end

    // -------------------------------------------------------------------------
    // Mode Capture (latch mode on start)
    // -------------------------------------------------------------------------
    always_ff @(posedge i_ntt_clk or negedge i_ntt_rst_n) begin
        if (!i_ntt_rst_n) begin
            r_mode <= 2'b00;
        end else if ((r_state == ST_IDLE) && i_ntt_start) begin
            r_mode <= i_ntt_mode;
        end
    end

    // -------------------------------------------------------------------------
    // Next State Logic
    // -------------------------------------------------------------------------
    always_comb begin
        w_next_state = r_state; // Default: hold state

        case (r_state)
            ST_IDLE: begin
                if (i_ntt_start) begin
                    // Check mode validity
                    if (i_ntt_mode == MODE_FWD_NTT) begin
                        w_next_state = ST_INIT;
                    end else if ((i_ntt_mode == MODE_INV_NTT) ||
                                 (i_ntt_mode == MODE_POINTWISE)) begin
                        // Placeholder modes — not yet implemented
                        w_next_state = ST_ERROR;
                    end else begin
                        w_next_state = ST_IDLE;
                    end
                end
            end

            ST_INIT: begin
                // Counters initialized in this cycle, proceed to first read
                w_next_state = ST_READ;
            end

            ST_READ: begin
                // Memory read issued, wait one cycle for data
                w_next_state = ST_COMPUTE;
            end

            ST_COMPUTE: begin
                // Data captured, butterfly computes combinationally
                w_next_state = ST_WRITE;
            end

            ST_WRITE: begin
                // Results written to memory, advance counters
                w_next_state = ST_NEXT;
            end

            ST_NEXT: begin
                if (i_ntt_last_op) begin
                    // All butterflies across all stages completed
                    w_next_state = ST_DONE;
                end else begin
                    // More butterflies to process
                    w_next_state = ST_READ;
                end
            end

            ST_DONE: begin
                w_next_state = ST_IDLE;
            end

            ST_ERROR: begin
                // Stay in error until reset
                // Could add recovery logic here if needed
                w_next_state = ST_ERROR;
            end

            default: begin
                w_next_state = ST_ERROR;
            end
        endcase
    end

    // -------------------------------------------------------------------------
    // Output Logic (Combinational from current state)
    // -------------------------------------------------------------------------
    always_comb begin
        // Default all outputs deasserted
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
                // Not busy, waiting for start
            end

            ST_INIT: begin
                o_ntt_busy    = 1'b1;
                o_ntt_ag_init = 1'b1;  // Reset address generator counters
            end

            ST_READ: begin
                o_ntt_busy      = 1'b1;
                o_ntt_mem_rd_en = 1'b1;  // Issue memory read
            end

            ST_COMPUTE: begin
                o_ntt_busy       = 1'b1;
                o_ntt_dp_capture = 1'b1;  // Capture read data into datapath regs
            end

            ST_WRITE: begin
                o_ntt_busy      = 1'b1;
                o_ntt_mem_wr_en = 1'b1;  // Write butterfly results to memory
            end

            ST_NEXT: begin
                o_ntt_busy       = 1'b1;
                o_ntt_ag_advance = 1'b1;  // Advance butterfly/stage counters
            end

            ST_DONE: begin
                o_ntt_done = 1'b1;  // Pulse done for one cycle
            end

            ST_ERROR: begin
                o_ntt_error = 1'b1;
                o_ntt_busy  = 1'b1;  // Remain busy in error state
            end

            default: begin
                o_ntt_error = 1'b1;
            end
        endcase
    end

endmodule : ntt_ctrl
