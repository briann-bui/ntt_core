`ifndef APB_NTT_SMOKE_TEST_SV
`define APB_NTT_SMOKE_TEST_SV

class apb_ntt_smoke_test extends apb_ntt_base_test;
  `uvm_component_utils(apb_ntt_smoke_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    apb_ntt_smoke_seq smoke_sequence;

    phase.raise_objection(this);
    smoke_sequence = apb_ntt_smoke_seq::type_id::create("smoke_sequence");
    smoke_sequence.start(env.m_apb_agent.sequencer);
    phase.drop_objection(this);
  endtask
endclass

`endif
