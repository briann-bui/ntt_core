module apb_ntt_coefficient_memory #(
  parameter int N           = 256,
  parameter int COEFF_WIDTH = 16,
  parameter int ADDR_WIDTH  = 8
) (
  input  logic                   i_ntt_clk,
  input  logic                   i_ntt_rst_n,

  input  logic                   i_ntt_host_write,
  input  logic [ADDR_WIDTH-1:0]  i_ntt_host_addr,
  input  logic [COEFF_WIDTH-1:0] i_ntt_host_wdata,
  output logic [COEFF_WIDTH-1:0] o_ntt_host_rdata,

  input  logic                   i_ntt_core_rd_en,
  input  logic                   i_ntt_core_wr_en,
  input  logic [ADDR_WIDTH-1:0]  i_ntt_core_addr_a,
  input  logic [ADDR_WIDTH-1:0]  i_ntt_core_addr_b,
  input  logic [COEFF_WIDTH-1:0] i_ntt_core_wdata_a,
  input  logic [COEFF_WIDTH-1:0] i_ntt_core_wdata_b,
  output logic [COEFF_WIDTH-1:0] o_ntt_core_rdata_a,
  output logic [COEFF_WIDTH-1:0] o_ntt_core_rdata_b,
  output logic                   o_ntt_core_rd_valid,
  output logic                   o_ntt_core_wr_ready
);

  logic [COEFF_WIDTH-1:0] r_coefficient_memory [0:N-1];

  assign o_ntt_host_rdata    = r_coefficient_memory[i_ntt_host_addr];
  assign o_ntt_core_wr_ready = 1'b1;

  always_ff @(posedge i_ntt_clk or negedge i_ntt_rst_n) begin
    if (!i_ntt_rst_n) begin
      o_ntt_core_rdata_a  <= '0;
      o_ntt_core_rdata_b  <= '0;
      o_ntt_core_rd_valid <= 1'b0;
    end else begin
      o_ntt_core_rd_valid <= i_ntt_core_rd_en;

      if (i_ntt_core_rd_en) begin
        o_ntt_core_rdata_a <= r_coefficient_memory[i_ntt_core_addr_a];
        o_ntt_core_rdata_b <= r_coefficient_memory[i_ntt_core_addr_b];
      end

      if (i_ntt_core_wr_en) begin
        r_coefficient_memory[i_ntt_core_addr_a] <= i_ntt_core_wdata_a;
        r_coefficient_memory[i_ntt_core_addr_b] <= i_ntt_core_wdata_b;
      end else if (i_ntt_host_write) begin
        r_coefficient_memory[i_ntt_host_addr] <= i_ntt_host_wdata;
      end
    end
  end

endmodule
