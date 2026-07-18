`ifndef APB_NTT_SMOKE_SEQ_SV
`define APB_NTT_SMOKE_SEQ_SV

class apb_ntt_smoke_seq extends apb_ntt_base_seq;
  `uvm_object_utils(apb_ntt_smoke_seq)

  function new(string name = "apb_ntt_smoke_seq");
    super.new(name);
  endfunction

  task body();
    bit [31:0] read_data;
    bit        completed = 1'b0;

    read_reg(APB_ADDR_STATUS, read_data);
    if (read_data[2:0] != 3'b000) begin
      `uvm_error("RESET_STATUS", $sformatf("STATUS after reset is 0x%08h", read_data))
    end

    for (int unsigned index = 0; index < NTT_N; index++) begin
      write_reg(APB_ADDR_COEFF_ADDR, index);
      write_reg(APB_ADDR_COEFF_DATA, (3 * index + 1) % NTT_Q);
    end

    write_reg(APB_ADDR_CTRL, 32'h0000_0003);

    for (int unsigned poll = 0; poll < NTT_TIMEOUT_POLLS; poll++) begin
      read_reg(APB_ADDR_STATUS, read_data);
      if (read_data[APB_STATUS_ERROR_BIT]) begin
        `uvm_error("NTT_ERROR", $sformatf("NTT reported STATUS=0x%08h", read_data))
        break;
      end
      if (read_data[APB_STATUS_DONE_BIT]) begin
        completed = 1'b1;
        break;
      end
    end

    if (!completed) begin
      `uvm_error("NTT_TIMEOUT", "Timeout waiting for forward NTT completion")
      return;
    end

    for (int unsigned index = 0; index < NTT_N; index++) begin
      write_reg(APB_ADDR_COEFF_ADDR, index);
      read_reg(APB_ADDR_COEFF_DATA, read_data);
    end

    write_reg(APB_ADDR_CTRL, 32'h0000_0008);
    read_reg(APB_ADDR_STATUS, read_data);
    if (read_data[2:0] != 3'b000) begin
      `uvm_error("CLEAR_STATUS", $sformatf("STATUS after CLEAR is 0x%08h", read_data))
    end
  endtask
endclass

`endif
