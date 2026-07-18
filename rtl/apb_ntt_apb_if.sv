module apb_ntt_apb_if
  import apb_ntt_pkg::*;
#(
  parameter int C_APB_DATA_WIDTH = 32,
  parameter int C_APB_ADDR_WIDTH = 8,
  parameter int COEFF_WIDTH      = 16,
  parameter int ADDR_WIDTH       = 8
) (
  input  logic                            i_ntt_pclk,
  input  logic                            i_ntt_presetn,
  input  logic [C_APB_ADDR_WIDTH-1:0]     i_ntt_paddr,
  input  logic                            i_ntt_psel,
  input  logic                            i_ntt_penable,
  input  logic                            i_ntt_pwrite,
  input  logic [C_APB_DATA_WIDTH-1:0]     i_ntt_pwdata,
  input  logic [(C_APB_DATA_WIDTH/8)-1:0] i_ntt_pstrb,
  output logic [C_APB_DATA_WIDTH-1:0]     o_ntt_prdata,
  output logic                            o_ntt_pready,
  output logic                            o_ntt_pslverr,
  output logic                            o_ntt_irq,

  output logic                            o_ntt_start,
  output logic [1:0]                      o_ntt_mode,
  output logic                            o_ntt_host_write,
  output logic [ADDR_WIDTH-1:0]           o_ntt_host_addr,
  output logic [COEFF_WIDTH-1:0]          o_ntt_host_wdata,
  input  logic [COEFF_WIDTH-1:0]          i_ntt_host_rdata,
  input  logic                            i_ntt_busy,
  input  logic                            i_ntt_done,
  input  logic                            i_ntt_error
);

  logic w_apb_access;
  logic w_apb_write;
  logic w_valid_address;
  logic w_busy_access_error;
  logic r_done_status;
  logic r_error_status;
  logic w_done_status;
  logic w_error_status;
  logic [31:0] w_host_write_data;

  assign w_apb_access = i_ntt_psel && i_ntt_penable;
  assign w_apb_write  = w_apb_access && i_ntt_pwrite;

  always_comb begin
    unique case (i_ntt_paddr[7:0])
      APB_NTT_ADDR_CTRL,
      APB_NTT_ADDR_STATUS,
      APB_NTT_ADDR_COEFF_ADDR,
      APB_NTT_ADDR_COEFF_DATA: w_valid_address = 1'b1;
      default:                 w_valid_address = 1'b0;
    endcase
  end

  assign w_busy_access_error = w_apb_access && i_ntt_busy &&
                               ((i_ntt_paddr[7:0] == APB_NTT_ADDR_COEFF_DATA) ||
                                (w_apb_write && (i_ntt_paddr[7:0] == APB_NTT_ADDR_CTRL) &&
                                 i_ntt_pwdata[APB_NTT_CTRL_START_BIT]));

  assign o_ntt_pready  = 1'b1;
  assign o_ntt_pslverr = w_apb_access && (!w_valid_address || w_busy_access_error);
  assign o_ntt_irq     = r_done_status || r_error_status;

  always_comb begin
    w_host_write_data = {{(32-COEFF_WIDTH){1'b0}}, i_ntt_host_rdata};
    for (int byte_index = 0; byte_index < C_APB_DATA_WIDTH/8; byte_index++) begin
      if (i_ntt_pstrb[byte_index]) begin
        w_host_write_data[(8*byte_index) +: 8] = i_ntt_pwdata[(8*byte_index) +: 8];
      end
    end
  end

  always_comb begin
    w_done_status  = r_done_status | i_ntt_done;
    w_error_status = r_error_status | i_ntt_error;

    if (w_apb_write && !o_ntt_pslverr &&
        (i_ntt_paddr[7:0] == APB_NTT_ADDR_CTRL) && i_ntt_pstrb[0] &&
        i_ntt_pwdata[APB_NTT_CTRL_CLEAR_BIT]) begin
      w_done_status  = 1'b0;
      w_error_status = 1'b0;
    end
  end

  always_ff @(posedge i_ntt_pclk or negedge i_ntt_presetn) begin
    if (!i_ntt_presetn) begin
      o_ntt_start       <= 1'b0;
      o_ntt_mode        <= MODE_FWD_NTT;
      o_ntt_host_write  <= 1'b0;
      o_ntt_host_addr   <= '0;
      o_ntt_host_wdata  <= '0;
      r_done_status     <= 1'b0;
      r_error_status    <= 1'b0;
    end else begin
      o_ntt_start      <= 1'b0;
      o_ntt_host_write <= 1'b0;

      r_done_status  <= w_done_status;
      r_error_status <= w_error_status;

      if (w_apb_write && !o_ntt_pslverr) begin
        case (i_ntt_paddr[7:0])
          APB_NTT_ADDR_CTRL: begin
            if (i_ntt_pstrb[0]) begin
              if (!i_ntt_busy) begin
                o_ntt_mode  <= i_ntt_pwdata[APB_NTT_CTRL_MODE_LSB +: 2];
                o_ntt_start <= i_ntt_pwdata[APB_NTT_CTRL_START_BIT];
              end
            end
          end
          APB_NTT_ADDR_COEFF_ADDR: begin
            if (i_ntt_pstrb[0]) begin
              o_ntt_host_addr <= i_ntt_pwdata[ADDR_WIDTH-1:0];
            end
          end
          APB_NTT_ADDR_COEFF_DATA: begin
            o_ntt_host_wdata <= w_host_write_data[COEFF_WIDTH-1:0];
            o_ntt_host_write <= |i_ntt_pstrb[(COEFF_WIDTH/8)-1:0];
          end
        endcase
      end
    end
  end

  always_comb begin
    o_ntt_prdata = 32'd0;
    if (i_ntt_psel && !i_ntt_pwrite) begin
      unique case (i_ntt_paddr[7:0])
        APB_NTT_ADDR_CTRL: begin
          o_ntt_prdata[APB_NTT_CTRL_MODE_LSB +: 2] = o_ntt_mode;
        end
        APB_NTT_ADDR_STATUS: begin
          o_ntt_prdata[APB_NTT_STATUS_BUSY_BIT]  = i_ntt_busy;
          o_ntt_prdata[APB_NTT_STATUS_DONE_BIT]  = r_done_status;
          o_ntt_prdata[APB_NTT_STATUS_ERROR_BIT] = r_error_status;
        end
        APB_NTT_ADDR_COEFF_ADDR: o_ntt_prdata[ADDR_WIDTH-1:0] = o_ntt_host_addr;
        APB_NTT_ADDR_COEFF_DATA: begin
          if (!i_ntt_busy) begin
            o_ntt_prdata[COEFF_WIDTH-1:0] = i_ntt_host_rdata;
          end
        end
        default: o_ntt_prdata = 32'd0;
      endcase
    end
  end

endmodule
