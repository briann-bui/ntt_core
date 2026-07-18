`ifndef APB_NTT_SCOREBOARD_SV
`define APB_NTT_SCOREBOARD_SV

class apb_ntt_scoreboard extends uvm_scoreboard;
  uvm_analysis_imp #(apb_item, apb_ntt_scoreboard) apb_export;

  int unsigned r_model [0:NTT_N-1];
  int unsigned r_coefficient_address;
  int unsigned r_checked_coefficients;
  bit          r_model_valid;

  covergroup apb_ntt_coverage with function sample(
    bit [7:0] address,
    bit       is_write,
    bit       error,
    bit [3:0] strobe,
    bit [1:0] mode,
    bit [2:0] status,
    int unsigned coefficient_index
  );
    option.per_instance = 1;
    cp_address: coverpoint address {
      bins ctrl       = {APB_ADDR_CTRL};
      bins status     = {APB_ADDR_STATUS};
      bins coeff_addr = {APB_ADDR_COEFF_ADDR};
      bins coeff_data = {APB_ADDR_COEFF_DATA};
      bins invalid    = default;
    }
    cp_direction: coverpoint is_write;
    cp_response: coverpoint error;
    cp_strobe: coverpoint strobe iff (is_write) {
      bins zero  = {4'h0};
      bins byte0 = {4'h1};
      bins full  = {4'hF};
      bins other = default;
    }
    cp_mode: coverpoint mode iff (is_write &&
                                  (address == APB_ADDR_CTRL) && strobe[0]) {
      bins modes[] = {[0:3]};
    }
    cp_status: coverpoint status iff (!is_write &&
                                      (address == APB_ADDR_STATUS)) {
      bins idle  = {3'b000};
      bins busy  = {3'b001};
      bins done  = {3'b010};
      bins error = {3'b100};
    }
    cp_coefficient_index: coverpoint coefficient_index iff (
      address inside {APB_ADDR_COEFF_ADDR, APB_ADDR_COEFF_DATA}
    ) {
      bins indices[] = {[0:NTT_N-1]};
    }
    cx_address_direction: cross cp_address, cp_direction;
    cx_response_direction: cross cp_response, cp_direction;
  endgroup

  `uvm_component_utils(apb_ntt_scoreboard)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    apb_export = new("apb_export", this);
    apb_ntt_coverage = new();
  endfunction

  function int unsigned mod_pow(int unsigned base, int unsigned exponent);
    int unsigned value = 1;
    for (int unsigned index = 0; index < exponent; index++) begin
      value = (value * base) % NTT_Q;
    end
    return value;
  endfunction

  function void calculate_forward_ntt();
    int unsigned half;
    int unsigned group_index;
    int unsigned offset;
    int unsigned address_a;
    int unsigned address_b;
    int unsigned twiddle_index;
    int unsigned value_a;
    int unsigned value_b;
    int unsigned product;

    for (int unsigned stage = 0; stage < $clog2(NTT_N); stage++) begin
      half = 1 << stage;
      for (int unsigned butterfly = 0; butterfly < NTT_N/2; butterfly++) begin
        group_index  = butterfly >> stage;
        offset       = butterfly & (half - 1);
        address_a    = (group_index << (stage + 1)) | offset;
        address_b    = address_a + half;
        twiddle_index = offset << ($clog2(NTT_N) - 1 - stage);
        value_a      = r_model[address_a];
        value_b      = r_model[address_b];
        product      = (value_b * mod_pow(NTT_ROOT, twiddle_index)) % NTT_Q;
        r_model[address_a] = (value_a + product) % NTT_Q;
        r_model[address_b] = (value_a + NTT_Q - product) % NTT_Q;
      end
    end

    r_model_valid = 1'b1;
  endfunction

  virtual function void write(apb_item item);
    int unsigned sampled_index;

    sampled_index = (item.addr == APB_ADDR_COEFF_ADDR) ?
                    item.data[NTT_ADDR_WIDTH-1:0] : r_coefficient_address;
    apb_ntt_coverage.sample(
      item.addr,
      item.is_write,
      item.error,
      item.strb,
      item.data[APB_CTRL_MODE_LSB +: 2],
      item.data[2:0],
      sampled_index
    );

    if (item.error) begin
      return;
    end

    if (item.is_write) begin
      case (item.addr)
        APB_ADDR_COEFF_ADDR: r_coefficient_address = item.data[NTT_ADDR_WIDTH-1:0];
        APB_ADDR_COEFF_DATA: begin
          if (item.strb[0] && (r_coefficient_address < NTT_N)) begin
            r_model[r_coefficient_address] = item.data[NTT_COEFF_WIDTH-1:0] % NTT_Q;
          end
        end
        APB_ADDR_CTRL: begin
          if (item.strb[0] && item.data[APB_CTRL_START_BIT] &&
              (item.data[APB_CTRL_MODE_LSB +: 2] == 2'b01)) begin
            calculate_forward_ntt();
          end
        end
        default: begin
        end
      endcase
    end else if ((item.addr == APB_ADDR_COEFF_DATA) && r_model_valid) begin
      if (item.data[NTT_COEFF_WIDTH-1:0] !==
          r_model[r_coefficient_address][NTT_COEFF_WIDTH-1:0]) begin
        `uvm_error("NTT_MISMATCH",
                   $sformatf("Coefficient[%0d] got %0d, expected %0d",
                             r_coefficient_address,
                             item.data[NTT_COEFF_WIDTH-1:0],
                             r_model[r_coefficient_address]))
      end else begin
        `uvm_info("NTT_MATCH",
                  $sformatf("Coefficient[%0d] = %0d",
                            r_coefficient_address, r_model[r_coefficient_address]),
                  UVM_LOW)
      end
      r_checked_coefficients++;
    end
  endfunction

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (!r_model_valid) begin
      `uvm_error("NO_NTT", "Forward NTT was not observed")
    end
    if (r_checked_coefficients < NTT_N) begin
      `uvm_error("SHORT_CHECK",
                 $sformatf("Checked %0d of %0d output coefficients",
                           r_checked_coefficients, NTT_N))
    end
  endfunction
endclass

`endif
