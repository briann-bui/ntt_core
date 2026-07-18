`ifndef APB_NTT_COVERAGE_SEQ_SV
`define APB_NTT_COVERAGE_SEQ_SV

class apb_ntt_coverage_seq extends apb_ntt_base_seq;
  `uvm_object_utils(apb_ntt_coverage_seq)

  function new(string name = "apb_ntt_coverage_seq");
    super.new(name);
  endfunction

  task wait_for_status(bit [2:0] expected_status);
    bit [31:0] read_data;
    bit        matched = 1'b0;

    for (int unsigned poll = 0; poll < NTT_TIMEOUT_POLLS; poll++) begin
      read_reg(APB_ADDR_STATUS, read_data);
      if (read_data[2:0] == expected_status) begin
        matched = 1'b1;
        break;
      end
    end

    if (!matched) begin
      `uvm_error("STATUS_TIMEOUT",
                 $sformatf("Expected STATUS 0x%0h", expected_status))
    end
  endtask

  function bit [31:0] coefficient_value(int unsigned pattern,
                                        int unsigned index);
    case (pattern)
      0: return (3 * index + 1) % NTT_Q;
      1: return (index[0]) ? 32'd255 : 32'd0;
      2: begin
        case (index)
          0: return 0;
          1: return 16;
          2: return 17;
          3: return 33;
          4: return 64;
          5: return 127;
          6: return 254;
          default: return 255;
        endcase
      end
      default: return ((index * index * 29) + 11) & 8'hFF;
    endcase
  endfunction

  task run_forward_transform(int unsigned pattern, bit check_busy_errors);
    bit [31:0] read_data;

    for (int unsigned index = 0; index < NTT_N; index++) begin
      write_reg(APB_ADDR_COEFF_ADDR, index, 4'h1);
      write_reg(APB_ADDR_COEFF_DATA, coefficient_value(pattern, index), 4'h1);
    end

    write_reg(APB_ADDR_CTRL, 32'h0000_0003, 4'h1);

    if (check_busy_errors) begin
      read_reg_expect_error(APB_ADDR_COEFF_DATA);
      write_reg_expect_error(APB_ADDR_COEFF_DATA, 32'hFFFF_FFFF);
      write_reg_expect_error(APB_ADDR_CTRL, 32'h0000_0003);
    end

    wait_for_status(3'b010);

    for (int unsigned index = 0; index < NTT_N; index++) begin
      write_reg(APB_ADDR_COEFF_ADDR, index);
      read_reg(APB_ADDR_COEFF_DATA, read_data);
    end

    write_reg(APB_ADDR_CTRL, 32'h0000_0008);
    wait_for_status(3'b000);
  endtask

  task run_unsupported_mode(bit [1:0] mode);
    write_reg(APB_ADDR_CTRL, {28'd0, 1'b0, mode, 1'b1});
    wait_for_status(3'b100);
    write_reg(APB_ADDR_CTRL, 32'h0000_0008);
    wait_for_status(3'b000);
  endtask

  task body();
    bit [31:0] read_data;

    read_reg(APB_ADDR_CTRL, read_data);
    read_reg(APB_ADDR_STATUS, read_data);
    read_reg(APB_ADDR_COEFF_ADDR, read_data);
    write_reg(APB_ADDR_STATUS, 32'hFFFF_FFFF);

    read_reg_expect_error(8'h10);
    write_reg_expect_error(8'hFC, 32'hA5A5_5A5A);

    write_reg(APB_ADDR_COEFF_ADDR, 0, 4'h1);
    write_reg(APB_ADDR_COEFF_DATA, 32'h0000_000C, 4'h1);
    write_reg(APB_ADDR_COEFF_DATA, 32'hFFFF_FFFF, 4'h0);
    write_reg(APB_ADDR_COEFF_DATA, 32'hFFFF_FFFF, 4'h2);
    read_reg(APB_ADDR_COEFF_DATA, read_data);

    write_reg(APB_ADDR_COEFF_ADDR, 7, 4'h1);
    write_reg(APB_ADDR_COEFF_ADDR, 3, 4'h0);
    read_reg(APB_ADDR_COEFF_ADDR, read_data);

    write_reg(APB_ADDR_CTRL, 32'h0000_0001, 4'h0);
    write_reg(APB_ADDR_CTRL, 32'h0000_0001, 4'h1);
    wait_for_status(3'b000);

    run_unsupported_mode(2'b10);
    run_unsupported_mode(2'b11);

    for (int unsigned pattern = 0; pattern < 4; pattern++) begin
      run_forward_transform(pattern, pattern == 0);
    end
  endtask
endclass

`endif
