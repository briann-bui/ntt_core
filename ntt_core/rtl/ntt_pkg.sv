// =============================================================================
// Module: ntt_pkg
// Description: Shared package for NTT Engine Core.
//              Contains default parameters, mode/state enumerations,
//              and common typedefs used across all NTT submodules.
// =============================================================================

package ntt_pkg;

    // -------------------------------------------------------------------------
    // Default NTT Parameters
    // -------------------------------------------------------------------------
    parameter int P_N       = 256;   // Number of coefficients (Kyber default)
    parameter int P_Q       = 3329;  // Modulus (Kyber prime)
    parameter int P_COEFF_W = 16;    // Coefficient bit-width
    parameter int P_ADDR_W  = 8;     // Address width = log2(P_N)
    parameter int P_LOG2N   = 8;     // log2(P_N), number of NTT stages

    // Product width for modular multiplication (a * b can be up to 2*P_COEFF_W)
    parameter int P_PROD_W  = 2 * P_COEFF_W;

    // Number of butterflies per stage
    parameter int P_NUM_BF  = P_N / 2; // 128 for N=256

    // -------------------------------------------------------------------------
    // Operation Mode Encoding
    // -------------------------------------------------------------------------
    typedef enum logic [1:0] {
        MODE_IDLE      = 2'b00,  // No operation
        MODE_FWD_NTT   = 2'b01,  // Forward NTT
        MODE_INV_NTT   = 2'b10,  // Inverse NTT (placeholder)
        MODE_POINTWISE = 2'b11   // Pointwise multiplication (placeholder)
    } ntt_mode_e;

    // -------------------------------------------------------------------------
    // FSM State Encoding
    // -------------------------------------------------------------------------
    typedef enum logic [3:0] {
        ST_IDLE    = 4'd0,  // Wait for start
        ST_INIT    = 4'd1,  // Initialize counters and control
        ST_READ    = 4'd2,  // Issue memory read for coefficient pair
        ST_COMPUTE = 4'd3,  // Capture read data, butterfly computes
        ST_WRITE   = 4'd4,  // Write butterfly results back to memory
        ST_NEXT    = 4'd5,  // Advance butterfly/stage counters
        ST_DONE    = 4'd6,  // Signal completion
        ST_ERROR   = 4'd7   // Error state
    } ntt_state_e;

endpackage : ntt_pkg
