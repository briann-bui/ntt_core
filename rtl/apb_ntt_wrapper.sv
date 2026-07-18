module apb_ntt_wrapper #(
  parameter int C_APB_DATA_WIDTH = 32,
  parameter int C_APB_ADDR_WIDTH = 8,
  parameter int N                = 256,
  parameter int Q                = 3329,
  parameter int ROOT             = 17,
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
  output logic                            o_ntt_irq
);

  logic                   w_start;
  logic [1:0]             w_mode;
  logic                   w_busy;
  logic                   w_done;
  logic                   w_error;
  logic                   w_host_write;
  logic [ADDR_WIDTH-1:0]  w_host_addr;
  logic [COEFF_WIDTH-1:0] w_host_wdata;
  logic [COEFF_WIDTH-1:0] w_host_rdata;
  logic                   w_core_rd_en;
  logic                   w_core_wr_en;
  logic                   w_core_rd_valid;
  logic                   w_core_wr_ready;
  logic [ADDR_WIDTH-1:0]  w_core_addr_a;
  logic [ADDR_WIDTH-1:0]  w_core_addr_b;
  logic [COEFF_WIDTH-1:0] w_core_wdata_a;
  logic [COEFF_WIDTH-1:0] w_core_wdata_b;
  logic [COEFF_WIDTH-1:0] w_core_rdata_a;
  logic [COEFF_WIDTH-1:0] w_core_rdata_b;

  apb_ntt_core #(
    .N           (N),
    .Q           (Q),
    .ROOT        (ROOT),
    .COEFF_WIDTH (COEFF_WIDTH),
    .ADDR_WIDTH  (ADDR_WIDTH)
  ) u_apb_ntt_core (
    .i_ntt_clk          (i_ntt_pclk),
    .i_ntt_rst_n        (i_ntt_presetn),
    .i_ntt_start        (w_start),
    .i_ntt_mode         (w_mode),
    .o_ntt_busy         (w_busy),
    .o_ntt_done         (w_done),
    .o_ntt_error        (w_error),
    .o_ntt_mem_rd_en    (w_core_rd_en),
    .o_ntt_mem_wr_en    (w_core_wr_en),
    .i_ntt_mem_rd_valid (w_core_rd_valid),
    .i_ntt_mem_wr_ready (w_core_wr_ready),
    .o_ntt_mem_addr_a   (w_core_addr_a),
    .o_ntt_mem_addr_b   (w_core_addr_b),
    .o_ntt_mem_wdata_a  (w_core_wdata_a),
    .o_ntt_mem_wdata_b  (w_core_wdata_b),
    .i_ntt_mem_rdata_a  (w_core_rdata_a),
    .i_ntt_mem_rdata_b  (w_core_rdata_b)
  );

  apb_ntt_coefficient_memory #(
    .N           (N),
    .COEFF_WIDTH (COEFF_WIDTH),
    .ADDR_WIDTH  (ADDR_WIDTH)
  ) u_apb_ntt_coefficient_memory (
    .i_ntt_clk            (i_ntt_pclk),
    .i_ntt_rst_n          (i_ntt_presetn),
    .i_ntt_host_write     (w_host_write),
    .i_ntt_host_addr      (w_host_addr),
    .i_ntt_host_wdata     (w_host_wdata),
    .o_ntt_host_rdata     (w_host_rdata),
    .i_ntt_core_rd_en     (w_core_rd_en),
    .i_ntt_core_wr_en     (w_core_wr_en),
    .i_ntt_core_addr_a    (w_core_addr_a),
    .i_ntt_core_addr_b    (w_core_addr_b),
    .i_ntt_core_wdata_a   (w_core_wdata_a),
    .i_ntt_core_wdata_b   (w_core_wdata_b),
    .o_ntt_core_rdata_a   (w_core_rdata_a),
    .o_ntt_core_rdata_b   (w_core_rdata_b),
    .o_ntt_core_rd_valid  (w_core_rd_valid),
    .o_ntt_core_wr_ready  (w_core_wr_ready)
  );

  apb_ntt_apb_if #(
    .C_APB_DATA_WIDTH (C_APB_DATA_WIDTH),
    .C_APB_ADDR_WIDTH (C_APB_ADDR_WIDTH),
    .COEFF_WIDTH      (COEFF_WIDTH),
    .ADDR_WIDTH       (ADDR_WIDTH)
  ) u_apb_ntt_apb_if (
    .i_ntt_pclk        (i_ntt_pclk),
    .i_ntt_presetn     (i_ntt_presetn),
    .i_ntt_paddr       (i_ntt_paddr),
    .i_ntt_psel        (i_ntt_psel),
    .i_ntt_penable     (i_ntt_penable),
    .i_ntt_pwrite      (i_ntt_pwrite),
    .i_ntt_pwdata      (i_ntt_pwdata),
    .i_ntt_pstrb       (i_ntt_pstrb),
    .o_ntt_prdata      (o_ntt_prdata),
    .o_ntt_pready      (o_ntt_pready),
    .o_ntt_pslverr     (o_ntt_pslverr),
    .o_ntt_irq         (o_ntt_irq),
    .o_ntt_start       (w_start),
    .o_ntt_mode        (w_mode),
    .o_ntt_host_write  (w_host_write),
    .o_ntt_host_addr   (w_host_addr),
    .o_ntt_host_wdata  (w_host_wdata),
    .i_ntt_host_rdata  (w_host_rdata),
    .i_ntt_busy        (w_busy),
    .i_ntt_done        (w_done),
    .i_ntt_error       (w_error)
  );

endmodule
