`include "util.vh"
`include "const.vh"

module cache #
(
  parameter LINES = 64,
  parameter CPU_WIDTH = `CPU_INST_BITS, // 32
  parameter WORD_ADDR_BITS = `CPU_ADDR_BITS-`ceilLog2(`CPU_INST_BITS/8) // 32 - 2 = 30
)
(
  input clk,
  input reset,

  input                       cpu_req_valid,
  output                      cpu_req_ready,      // *
  input [WORD_ADDR_BITS-1:0]  cpu_req_addr,       // 30 bits
  input [CPU_WIDTH-1:0]       cpu_req_data,       // 32 bits
  input [3:0]                 cpu_req_write,      

  output reg                  cpu_resp_valid,     // *
  output reg [CPU_WIDTH-1:0]  cpu_resp_data,      // 32 bits *

  output                      mem_req_valid,      // *
  input                       mem_req_ready,
  output [WORD_ADDR_BITS-1:`ceilLog2(`MEM_DATA_BITS/CPU_WIDTH)] mem_req_addr,   // 29 : 2, 28 bits   *
  output                           mem_req_rw,
  output                           mem_req_data_valid,
  input                            mem_req_data_ready,
  output [`MEM_DATA_BITS-1:0]      mem_req_data_bits,
  // byte level masking
  output [(`MEM_DATA_BITS/8)-1:0]  mem_req_data_mask,   // 15:0, 16 bits

  input                       mem_resp_valid,
  input [`MEM_DATA_BITS-1:0]  mem_resp_data             // 127:0 128 bits
);


// --------------------------------------------------
// State Machine Variables

reg [2:0] state;
localparam IDLE       = 3'b000;
localparam META       = 3'b001;
localparam WRITE      = 3'b010;

localparam FETCH_WAIT = 3'b100;
localparam FETCH      = 3'b101;
localparam WB_WAIT    = 3'b110;
localparam WB         = 3'b111;

reg [1:0] mem_step;


// --------------------------------------------------
// CPU Request Decoding

// CPU Req Addr
// Bit: 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2
// Idx: 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
//       T  T  T  T  T  T  T  T  T  T  T  T  T  T  T  T  T  T  T  T  I  I  I  I  I  I  O  O  O  O 

assign cpu_req_ready = (state == IDLE) ? 1'b1 : 1'b0;

reg [3:0] cpu_req_write_hold;
wire [3:0] cpu_req_write_true = (state == IDLE) ? cpu_req_write : cpu_req_write_hold;

reg [31:0] cpu_req_data_hold;
wire [31:0] cpu_req_data_true = (state == IDLE) ? cpu_req_data : cpu_req_data_hold;

reg [29:0] cpu_req_addr_hold;
wire [19:0] req_tag   = cpu_req_addr[29:10];
wire [5:0]  req_index = cpu_req_addr[9:4];
wire [1:0]  req_row   = cpu_req_addr[3:2];
wire [1:0]  req_cache = cpu_req_addr[1:0];
wire [19:0] req_tag_hold   = cpu_req_addr_hold[29:10];
wire [5:0]  req_index_hold = cpu_req_addr_hold[9:4];
wire [1:0]  req_row_hold   = cpu_req_addr_hold[3:2];
wire [1:0]  req_cache_hold = cpu_req_addr_hold[1:0];
wire [19:0] req_tag_true   = (state == IDLE) ? req_tag   : req_tag_hold;
wire [5:0]  req_index_true = (state == IDLE) ? req_index : req_index_hold;
wire [1:0]  req_row_true   = (state == IDLE) ? req_row   : req_row_hold;
wire [1:0]  req_cache_true = (state == IDLE) ? req_cache : req_cache_hold;

wire [7:0] req_index_cache = {req_index_true, req_row_true};
wire [7:0] mem_index_cache = {req_index_true, mem_step};


// --------------------------------------------------
// Metadata (Valid/Dirty/Cache Hit)

// Metadata Entry:
// 0-15: rows 0-63, 16-31: rows 64-127, 32-47: rows 128-191, 48-63: rows 192-255, 
// Bit: 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
// USE: | ------------------------- TAG ------------------------- |  V  D  | --------- UNUSED --------|

reg[5:0] meta_addr;
always @(*) begin
  if (reset == 1'b1) meta_addr <= 6'b0;
  else if (cpu_req_valid) meta_addr <= req_index_true;
end

reg [5:0] meta_cur_addr;
always @(posedge clk) begin
  if (reset) meta_cur_addr <= 6'b0;
  else meta_cur_addr <= meta_addr;
end

wire [31:0] meta_dout;
wire [19:0] meta_tag = meta_dout[31:12];
wire meta_valid = meta_dout[11];
wire meta_dirty = meta_dout[10];

wire cache_hit = ((req_index_true == meta_cur_addr) && 
                  (req_tag_true == meta_tag) && (meta_valid == 1'b1)) ? 1'b1 : 1'b0;

wire cache_write = ((state == META || state == IDLE) && 
                    (cache_hit == 1'b1) && (cpu_req_write_true != 4'b0000)) ? 1'b1 : 1'b0;
                    
wire mem_write = ((state == FETCH) && (mem_resp_valid == 1'b1)) ? 1'b1 : 1'b0;

wire meta_we = ((cache_write == 1'b1) || ((mem_write == 1'b1) && (mem_step != 2'b11))) ? 1'b1 : 1'b0;

wire meta_write_dirty = (cache_write == 1'b1) ? 1'b1 :
                        (mem_write == 1'b1)   ? 1'b0 : 1'bx;
wire [31:0] meta_din = {req_tag_true, 1'b1, meta_write_dirty, {10{1'b0}}};
// Optimize by encoding dirty sections with seperate dirty bits

sram22_64x32m4w8 metadata (
  .clk(clk),
  .we(meta_we),
  .wmask(4'b1111),
  .addr(meta_addr),
  .din(meta_din),
  .dout(meta_dout)
);


// --------------------------------------------------
// Cache SRAMs

wire [31:0] cache0_dout, cache1_dout, cache2_dout, cache3_dout;

assign cpu_resp_data = (req_cache_hold == 2'b00) ? cache0_dout :
                       (req_cache_hold == 2'b01) ? cache1_dout :
                       (req_cache_hold == 2'b10) ? cache2_dout :
                       (req_cache_hold == 2'b11) ? cache3_dout :
                       32'bx;

wire [31:0] cache0_din, cache1_din, cache2_din, cache3_din;
assign cache0_din = (state == FETCH) ? mem_resp_data[31:0]   : cpu_req_data_true;
assign cache1_din = (state == FETCH) ? mem_resp_data[63:32]  : cpu_req_data_true;
assign cache2_din = (state == FETCH) ? mem_resp_data[95:64]  : cpu_req_data_true;
assign cache3_din = (state == FETCH) ? mem_resp_data[127:96] : cpu_req_data_true;

wire cache0_we, cache1_we, cache2_we, cache3_we;
assign cache0_we = (((cache_write) && (req_cache_true == 2'b00)) || ((mem_write == 1'b1))) ? 1'b1 : 1'b0;
assign cache1_we = (((cache_write) && (req_cache_true == 2'b01)) || ((mem_write == 1'b1))) ? 1'b1 : 1'b0;
assign cache2_we = (((cache_write) && (req_cache_true == 2'b10)) || ((mem_write == 1'b1))) ? 1'b1 : 1'b0;
assign cache3_we = (((cache_write) && (req_cache_true == 2'b11)) || ((mem_write == 1'b1))) ? 1'b1 : 1'b0;

wire [3:0] cache_mask = (state == FETCH) ? 4'b1111: cpu_req_write_true;

reg [7:0] cache_addr;
always @(*) begin
  if (reset) cache_addr <= 8'b0;
  else if (cpu_req_valid) begin
    if ((state == IDLE) || (state == META) || (state == WRITE)) cache_addr <= req_index_cache;
    else cache_addr <= mem_index_cache;
  end
end

sram22_256x32m4w8 cache0 (
  .clk(clk),
  .we(cache0_we),
  .wmask(cache_mask),
  .addr(cache_addr),
  .din(cache0_din),
  .dout(cache0_dout)
);

sram22_256x32m4w8 cache1 (
  .clk(clk),
  .we(cache1_we),
  .wmask(cache_mask),
  .addr(cache_addr),
  .din(cache1_din),
  .dout(cache1_dout)
);

sram22_256x32m4w8 cache2 (
  .clk(clk),
  .we(cache2_we),
  .wmask(cache_mask),
  .addr(cache_addr),
  .din(cache2_din),
  .dout(cache2_dout)
);

sram22_256x32m4w8 cache3 (
  .clk(clk),
  .we(cache3_we),
  .wmask(cache_mask),
  .addr(cache_addr),
  .din(cache3_din),
  .dout(cache3_dout)
);


// --------------------------------------------------
// External Memory Interface

assign mem_req_data_bits = {cache3_dout, cache2_dout, cache1_dout, cache0_dout};
assign mem_req_data_mask = 16'b1111_1111_1111_1111;     // Optimize by only writing back dirty sections

assign mem_req_valid = ((state == WB) || (state == WB_WAIT) || (state == FETCH_WAIT) || 
                        ((state == FETCH) && (mem_step == 2'b00)) ||
                        ((state == META) && (cache_hit == 1'b0))) ? 1'b1 : 1'b0;

assign mem_req_rw = ((state == WB) || (state == WB_WAIT) ||
                     ((state == META) && (cache_hit == 1'b0) && (meta_dirty == 1'b1))) ? 1'b1 :
                    ((state == FETCH) || (state == FETCH_WAIT) || 
                     ((state == META) && (cache_hit == 1'b0) && (meta_dirty == 1'b0))) ? 1'b0: 1'b0;

assign mem_req_data_valid = ((state == WB) || (state == WB_WAIT)) ? 1'b1 : 1'b0;

wire [WORD_ADDR_BITS-1:`ceilLog2(`MEM_DATA_BITS/CPU_WIDTH)] mem_addr_fetch, mem_addr_wb;
assign mem_addr_fetch = {req_tag_true, req_index_true, mem_step};
assign mem_addr_wb = {meta_tag, req_index_true, mem_step};

assign mem_req_addr = ((state == FETCH) || (state == FETCH_WAIT) ||
                       ((state == META) && (cache_hit == 1'b0) && (meta_dirty == 1'b0))) ? mem_addr_fetch :
                      ((state == WB) || (state == WB_WAIT) ||
                       ((state == META) && (cache_hit == 1'b0) && (meta_dirty == 1'b1))) ? mem_addr_wb : 28'bx;


// --------------------------------------------------
// State Machine Transitions

always @(posedge clk) begin
  if (reset == 1'b1) begin
    state <= IDLE;
    mem_step <= 2'd0;

    cpu_req_addr_hold <= 30'b0;
    cpu_req_data_hold <= 32'b0;
    cpu_req_write_hold <= 4'b0;

    cpu_resp_valid <= 1'b0;
  end else begin
    if (state == IDLE) begin
      cpu_resp_valid <= 1'b0;

      if (cpu_req_valid == 1'b1) begin
        if (cache_hit == 1'b1) begin
          cpu_req_addr_hold <= cpu_req_addr;
          if (cpu_req_write == 4'b0000) begin
            cpu_resp_valid <= 1'b1;
          end else begin
            state <= WRITE;
          end
        end else begin
          cpu_req_addr_hold <= cpu_req_addr;
          cpu_req_data_hold <= cpu_req_data;
          cpu_req_write_hold <= cpu_req_write;
          state <= META;
        end
      end
    end else if (state == META) begin
      if (cache_hit == 1'b1) begin
        if (cpu_req_write_hold == 4'b0000) begin
          cpu_resp_valid <= 1'b1;
          state <= IDLE;
        end else begin
          state <= WRITE;
        end 
      end else begin
        if (meta_dirty == 1'b1) begin
          if (mem_req_ready == 1'b1) begin    // ****** SAME PATH 1
            state <= WB;
          end else begin
            state <= WB_WAIT;
          end
        end else begin
          if (mem_req_ready == 1'b1) begin    // ****** SAME PATH 2
            state <= FETCH;
          end else begin
            state <= FETCH_WAIT;
          end
        end
      end
    end else if (state == WRITE) begin
      state <= IDLE;
    end else if (state == WB_WAIT) begin
      if (mem_req_ready == 1'b1) begin   // ****** SAME PATH 1
        state <= WB;
      end
    end else if (state == FETCH_WAIT) begin  // ****** SAME PATH 2
      if (mem_req_ready == 1'b1) begin
        state <= FETCH;
      end
    end else if (state == WB) begin
      if (mem_req_data_ready == 1'b1) begin
        if (mem_step == 2'b11) begin
          mem_step <= 2'd0;
          state <= FETCH_WAIT;
        end else begin
          mem_step <= mem_step + 1'b1;
          state <= WB_WAIT;
        end
      end
    end else if (state == FETCH) begin
      if (mem_resp_valid == 1'b1) begin
        if (mem_step == 2'b11) begin
          mem_step <= 2'd0;
          state <= META;
        end else begin
          mem_step <= mem_step + 1'b1;
        end
      end
    end
  end
end

endmodule