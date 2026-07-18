package apb_ntt_pkg;

  localparam logic [7:0] APB_NTT_ADDR_CTRL       = 8'h00;
  localparam logic [7:0] APB_NTT_ADDR_STATUS     = 8'h04;
  localparam logic [7:0] APB_NTT_ADDR_COEFF_ADDR = 8'h08;
  localparam logic [7:0] APB_NTT_ADDR_COEFF_DATA = 8'h0C;

  localparam int APB_NTT_CTRL_START_BIT       = 0;
  localparam int APB_NTT_CTRL_MODE_LSB        = 1;
  localparam int APB_NTT_CTRL_CLEAR_BIT       = 3;
  localparam int APB_NTT_STATUS_BUSY_BIT      = 0;
  localparam int APB_NTT_STATUS_DONE_BIT      = 1;
  localparam int APB_NTT_STATUS_ERROR_BIT     = 2;

  parameter int N       = 256;
  parameter int Q       = 3329;
  parameter int ROOT    = 17;
  parameter int COEFF_WIDTH = 16;
  parameter int ADDR_WIDTH  = 8;
  parameter int LOG2_N   = 8;

  parameter int PRODUCT_WIDTH  = 2 * COEFF_WIDTH;

  parameter int NUM_BUTTERFLIES  = N / 2;

  typedef enum logic [1:0] {
    MODE_IDLE      = 2'b00,
    MODE_FWD_NTT   = 2'b01,
    MODE_INV_NTT   = 2'b10,
    MODE_POINTWISE = 2'b11
  } ntt_mode_e;

  typedef enum logic [3:0] {
    ST_IDLE    = 4'd0,
    ST_INIT    = 4'd1,
    ST_READ    = 4'd2,
    ST_COMPUTE = 4'd3,
    ST_WRITE   = 4'd4,
    ST_NEXT    = 4'd5,
    ST_DONE    = 4'd6,
    ST_ERROR   = 4'd7
  } ntt_state_e;

endpackage
