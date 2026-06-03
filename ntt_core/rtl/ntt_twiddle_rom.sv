// =============================================================================
// Module: ntt_twiddle_rom
// Description: ROM storing twiddle factors (powers of primitive root of unity).
//              Placeholder implementation with partial values for skeleton.
//              Uses case statement for synthesis-friendly ROM inference.
//
// PRODUCTION NOTE: For production Kyber/Dilithium, this ROM must contain
// the correct twiddle factors computed as:
//   zeta = 17 (primitive 256th root of unity mod 3329)
//   twiddle[i] = zeta^(bit_reverse(i)) mod 3329
// The values below are PLACEHOLDERS — only the first few entries are
// illustrative. A verified twiddle table must be generated from the
// Kyber/Dilithium specification before tapeout.
// =============================================================================

module ntt_twiddle_rom #(
    parameter int P_COEFF_W = 16,
    parameter int P_ADDR_W  = 7     // log2(N/2) = 7 for N=256
) (
    input  logic [P_ADDR_W-1:0]  i_ntt_addr,
    output logic [P_COEFF_W-1:0] o_ntt_twiddle
);

    // -------------------------------------------------------------------------
    // Twiddle Factor Lookup Table
    // 128 entries for N=256 (N/2 twiddle factors)
    //
    // PLACEHOLDER VALUES: First 16 entries are illustrative powers of
    // zeta=17 mod 3329. Remaining entries default to 1 (identity).
    // Production must replace with verified Kyber/Dilithium twiddle table.
    // -------------------------------------------------------------------------
    always_comb begin
        case (i_ntt_addr)
            7'd0   : o_ntt_twiddle = 16'd1;      // zeta^0
            7'd1   : o_ntt_twiddle = 16'd17;     // zeta^1
            7'd2   : o_ntt_twiddle = 16'd289;    // zeta^2
            7'd3   : o_ntt_twiddle = 16'd1584;   // zeta^3
            7'd4   : o_ntt_twiddle = 16'd296;    // zeta^4
            7'd5   : o_ntt_twiddle = 16'd1703;   // zeta^5
            7'd6   : o_ntt_twiddle = 16'd2319;   // zeta^6
            7'd7   : o_ntt_twiddle = 16'd2804;   // zeta^7
            7'd8   : o_ntt_twiddle = 16'd2539;   // zeta^8  (placeholder)
            7'd9   : o_ntt_twiddle = 16'd2834;   // zeta^9  (placeholder)
            7'd10  : o_ntt_twiddle = 16'd2281;   // zeta^10 (placeholder)
            7'd11  : o_ntt_twiddle = 16'd449;    // zeta^11 (placeholder)
            7'd12  : o_ntt_twiddle = 16'd2304;   // zeta^12 (placeholder)
            7'd13  : o_ntt_twiddle = 16'd2798;   // zeta^13 (placeholder)
            7'd14  : o_ntt_twiddle = 16'd1578;   // zeta^14 (placeholder)
            7'd15  : o_ntt_twiddle = 16'd1380;   // zeta^15 (placeholder)
            default: o_ntt_twiddle = 16'd1;      // Identity (placeholder)
        endcase
    end

endmodule : ntt_twiddle_rom
