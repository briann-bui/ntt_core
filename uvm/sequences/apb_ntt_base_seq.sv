`ifndef APB_NTT_BASE_SEQ_SV
`define APB_NTT_BASE_SEQ_SV

class apb_ntt_base_seq extends uvm_sequence #(apb_item);
  `uvm_object_utils(apb_ntt_base_seq)

  function new(string name = "apb_ntt_base_seq");
    super.new(name);
  endfunction

  task write_reg(bit [7:0] address, bit [31:0] data,
                 bit [3:0] strobe = 4'hF);
    apb_item item = apb_item::type_id::create("write_item");
    start_item(item);
    item.addr     = address;
    item.data     = data;
    item.is_write = 1'b1;
    item.strb     = strobe;
    finish_item(item);
    if (item.error) begin
      `uvm_error("APB_WRITE", $sformatf("PSLVERR at address 0x%02h", address))
    end
  endtask

  task read_reg(bit [7:0] address, output bit [31:0] data);
    apb_item item = apb_item::type_id::create("read_item");
    start_item(item);
    item.addr     = address;
    item.data     = '0;
    item.is_write = 1'b0;
    item.strb     = '0;
    finish_item(item);
    data = item.data;
    if (item.error) begin
      `uvm_error("APB_READ", $sformatf("PSLVERR at address 0x%02h", address))
    end
  endtask

  task write_reg_expect_error(bit [7:0] address, bit [31:0] data,
                              bit [3:0] strobe = 4'hF);
    apb_item item = apb_item::type_id::create("write_error_item");
    start_item(item);
    item.addr     = address;
    item.data     = data;
    item.is_write = 1'b1;
    item.strb     = strobe;
    finish_item(item);
    if (!item.error) begin
      `uvm_error("APB_WRITE", $sformatf("Expected PSLVERR at address 0x%02h", address))
    end
  endtask

  task read_reg_expect_error(bit [7:0] address);
    apb_item item = apb_item::type_id::create("read_error_item");
    start_item(item);
    item.addr     = address;
    item.data     = '0;
    item.is_write = 1'b0;
    item.strb     = '0;
    finish_item(item);
    if (!item.error) begin
      `uvm_error("APB_READ", $sformatf("Expected PSLVERR at address 0x%02h", address))
    end
  endtask
endclass

`endif
