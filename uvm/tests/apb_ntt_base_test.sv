`ifndef APB_NTT_BASE_TEST_SV
`define APB_NTT_BASE_TEST_SV

class apb_ntt_base_test extends uvm_test;
  apb_ntt_env env;

  `uvm_component_utils(apb_ntt_base_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = apb_ntt_env::type_id::create("env", this);
  endfunction

  function void report_phase(uvm_phase phase);
    uvm_report_server report_server;
    super.report_phase(phase);
    report_server = uvm_report_server::get_server();
    if ((report_server.get_severity_count(UVM_FATAL) == 0) &&
        (report_server.get_severity_count(UVM_ERROR) == 0)) begin
      `uvm_info("TEST", "APB NTT UVM TEST PASSED", UVM_NONE)
    end else begin
      `uvm_error("TEST", "APB NTT UVM TEST FAILED")
    end
  endfunction
endclass

`endif
