module apb_ntt_twiddle_rom #(
  parameter int COEFF_WIDTH = 16,
  parameter int ADDR_WIDTH = 7,
  parameter int Q = 3329,
  parameter int ROOT = 17
) (
  input  logic [ADDR_WIDTH-1:0]   i_ntt_addr,
  output logic [COEFF_WIDTH-1:0] o_ntt_twiddle
);

  localparam int ROM_DEPTH = 1 << ADDR_WIDTH;

  function automatic logic [COEFF_WIDTH-1:0] f_mod_pow(
    input int unsigned exponent
  );
    longint unsigned value;
    begin
      value = 64'd1;
      for (int unsigned index = 0; index < exponent; index++) begin
        value = (value * ROOT) % Q;
      end
      f_mod_pow = COEFF_WIDTH'(value);
    end
  endfunction

  logic [COEFF_WIDTH-1:0] w_twiddle_rom [0:ROM_DEPTH-1];

  for (genvar g_twiddle = 0; g_twiddle < ROM_DEPTH; g_twiddle++) begin : g_twiddle_rom
    assign w_twiddle_rom[g_twiddle] = f_mod_pow(g_twiddle);
  end

  always_comb begin
    o_ntt_twiddle = w_twiddle_rom[i_ntt_addr];
  end

endmodule
