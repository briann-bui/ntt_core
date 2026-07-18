package apb_ntt_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  localparam int NTT_N             = 8;
  localparam int NTT_Q             = 17;
  localparam int NTT_ROOT          = 2;
  localparam int NTT_COEFF_WIDTH   = 8;
  localparam int NTT_ADDR_WIDTH    = 3;
  localparam int NTT_TIMEOUT_POLLS = 128;

  localparam bit [7:0] APB_ADDR_CTRL       = 8'h00;
  localparam bit [7:0] APB_ADDR_STATUS     = 8'h04;
  localparam bit [7:0] APB_ADDR_COEFF_ADDR = 8'h08;
  localparam bit [7:0] APB_ADDR_COEFF_DATA = 8'h0C;

  localparam int APB_CTRL_START_BIT   = 0;
  localparam int APB_CTRL_MODE_LSB    = 1;
  localparam int APB_STATUS_BUSY_BIT  = 0;
  localparam int APB_STATUS_DONE_BIT  = 1;
  localparam int APB_STATUS_ERROR_BIT = 2;

  `include "apb_item.sv"
  `include "apb_sequencer.sv"
  `include "apb_driver.sv"
  `include "apb_monitor.sv"
  `include "apb_agent.sv"

  `include "apb_ntt_scoreboard.sv"
  `include "apb_ntt_env.sv"

  `include "apb_ntt_base_seq.sv"
  `include "apb_ntt_smoke_seq.sv"
  `include "apb_ntt_coverage_seq.sv"

  `include "apb_ntt_base_test.sv"
  `include "apb_ntt_smoke_test.sv"
  `include "apb_ntt_coverage_test.sv"
endpackage
