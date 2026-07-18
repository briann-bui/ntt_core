module apb_ntt_tb_top;
  import uvm_pkg::*;
  import apb_ntt_uvm_pkg::*;

  logic pclk = 1'b0;
  logic presetn = 1'b0;
  logic irq;

  always #5 pclk = ~pclk;

  initial begin
    repeat (4) @(posedge pclk);
    presetn <= 1'b1;
  end

  apb_if apb_vif (pclk, presetn);

  apb_ntt_wrapper #(
    .C_APB_DATA_WIDTH (32),
    .C_APB_ADDR_WIDTH (8),
    .N                (NTT_N),
    .Q                (NTT_Q),
    .ROOT             (NTT_ROOT),
    .COEFF_WIDTH      (NTT_COEFF_WIDTH),
    .ADDR_WIDTH       (NTT_ADDR_WIDTH)
  ) u_dut (
    .i_ntt_pclk    (pclk),
    .i_ntt_presetn (presetn),
    .i_ntt_paddr   (apb_vif.paddr),
    .i_ntt_psel    (apb_vif.psel),
    .i_ntt_penable (apb_vif.penable),
    .i_ntt_pwrite  (apb_vif.pwrite),
    .i_ntt_pwdata  (apb_vif.pwdata),
    .i_ntt_pstrb   (apb_vif.pstrb),
    .o_ntt_prdata  (apb_vif.prdata),
    .o_ntt_pready  (apb_vif.pready),
    .o_ntt_pslverr (apb_vif.pslverr),
    .o_ntt_irq     (irq)
  );

  initial begin
    uvm_config_db#(virtual apb_if)::set(
      null, "uvm_test_top.env.m_apb_agent.*", "apb_vif", apb_vif
    );
    run_test();
  end
endmodule
