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
  output [CPU_WIDTH-1:0]      cpu_resp_data,      // 32 bits *

  output reg                  mem_req_valid,      // *
  input                       mem_req_ready,
  output [WORD_ADDR_BITS-1:`ceilLog2(`MEM_DATA_BITS/CPU_WIDTH)] mem_req_addr,   // 29 : 2, 28 bits   *
  output reg                       mem_req_rw,
  output reg                       mem_req_data_valid,
  input                            mem_req_data_ready,
  output [`MEM_DATA_BITS-1:0]      mem_req_data_bits,
  // byte level masking
  output [(`MEM_DATA_BITS/8)-1:0]  mem_req_data_mask,   // 15:0, 16 bits

  input                       mem_resp_valid,
  input [`MEM_DATA_BITS-1:0]  mem_resp_data             // 127:0 128 bits
);

reg [2:0] state;
localparam IDLE   = 3'b000;
localparam META   = 3'b001;
localparam WB0    = 3'b010;
localparam WB1    = 3'b011;
localparam FETCH0 = 3'b100;
localparam FETCH1 = 3'b101;

assign cpu_req_ready = (state == IDLE) ? 1'b1 : 1'b0;

// CPU Req Addr
// Bit: 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2
// Idx: 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
//       T  T  T  T  T  T  T  T  T  T  T  T  T  T  T  T  T  T  T  T  I  I  I  I  I  I  O  O  O  O 

reg [29:0] cpu_req_addr_hold;
wire [19:0] req_tag   = cpu_req_addr_hold[29:10];
wire [5:0]  req_index = cpu_req_addr_hold[9:4];
wire [1:0]  req_row   = cpu_req_addr_hold[3:2];
wire [1:0]  req_cache = cpu_req_addr_hold[1:0];

wire [7:0] req_index_cache = {req_index, req_row};

reg [1:0] write_step;
wire [7:0] write_index_cache = {req_index, write_step};

assign mem_req_addr = {req_tag, req_index, write_step};


// Metadata Entry:
// 0-15: rows 0-63, 16-31: rows 64-127, 32-47: rows 128-191, 48-63: rows 192-255, 
// Bit: 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
// USE: | ------------------------- TAG ------------------------- |  V  D  | --------- UNUSED --------|

reg meta_we;
reg meta_write_dirty;
wire [31:0] meta_din = {req_tag, 1'b1, meta_write_dirty, {10{1'b0}}};

wire [5:0] meta_addr = (state == IDLE) ? cpu_req_addr[9:4] : req_index;
wire [31:0] meta_dout;
wire [19:0] meta_tag = meta_dout[31:12];
wire meta_valid = meta_dout[11];
wire meta_dirty = meta_dout[10];

sram22_64x32m4w8 metadata (
  .clk(clk),
  .we(meta_we),
  .wmask(4'b1111),
  .addr(meta_addr),
  .din(meta_din),
  .dout(meta_dout)
);


wire [31:0] cache0_dout, cache1_dout, cache2_dout, cache3_dout;

assign cpu_resp_data = (req_cache == 2'b00) ? cache0_dout :
                       (req_cache == 2'b01) ? cache1_dout :
                       (req_cache == 2'b10) ? cache2_dout :
                       (req_cache == 2'b11) ? cache3_dout :
                       32'bx;

assign mem_req_data_bits = {cache0_dout, cache1_dout, cache2_dout, cache3_dout};

reg cache_din_sel;
wire [31:0] cache0_din, cache1_din, cache2_din, cache3_din;
reg [31:0] cpu_req_data_hold;

assign cache0_din = (cache_din_sel == 1'b1) ? mem_resp_data[31:0]   : cpu_req_data_hold;
assign cache1_din = (cache_din_sel == 1'b1) ? mem_resp_data[63:32]  : cpu_req_data_hold;
assign cache2_din = (cache_din_sel == 1'b1) ? mem_resp_data[95:64]  : cpu_req_data_hold;
assign cache3_din = (cache_din_sel == 1'b1) ? mem_resp_data[127:96] : cpu_req_data_hold;

reg [3:0] cache_we;
wire cache0_we = (cache_din_sel == 1'b0) ? cache_we[0] : 
                 (mem_resp_valid == 1'b1) ? 1'b1 : 1'b0;
wire cache1_we = (cache_din_sel == 1'b0) ? cache_we[1] : 
                 (mem_resp_valid == 1'b1) ? 1'b1 : 1'b0;
wire cache2_we = (cache_din_sel == 1'b0) ? cache_we[2] : 
                 (mem_resp_valid == 1'b1) ? 1'b1 : 1'b0;
wire cache3_we = (cache_din_sel == 1'b0) ? cache_we[3] : 
                 (mem_resp_valid == 1'b1) ? 1'b1 : 1'b0;

reg [3:0] cpu_req_write_hold;
wire [3:0] cache0_mask, cache1_mask, cache2_mask, cache3_mask;
assign cache0_mask = (cache_din_sel == 1'b1) ? 4'b1111: cpu_req_write_hold;
assign cache1_mask = (cache_din_sel == 1'b1) ? 4'b1111: cpu_req_write_hold;
assign cache2_mask = (cache_din_sel == 1'b1) ? 4'b1111: cpu_req_write_hold;
assign cache3_mask = (cache_din_sel == 1'b1) ? 4'b1111: cpu_req_write_hold;


reg cache_addr_sel;
wire [7:0] cache0_addr, cache1_addr, cache2_addr, cache3_addr;

assign cache0_addr = (cache_addr_sel == 1'b1) ? write_index_cache: req_index_cache;
assign cache1_addr = (cache_addr_sel == 1'b1) ? write_index_cache: req_index_cache;
assign cache2_addr = (cache_addr_sel == 1'b1) ? write_index_cache: req_index_cache;
assign cache3_addr = (cache_addr_sel == 1'b1) ? write_index_cache: req_index_cache;

sram22_256x32m4w8 cache0 (
  .clk(clk),
  .we(cache0_we),
  .wmask(cache0_mask),
  .addr(cache0_addr),
  .din(cache0_din),
  .dout(cache0_dout)
);

sram22_256x32m4w8 cache1 (
  .clk(clk),
  .we(cache1_we),
  .wmask(cache1_mask),
  .addr(cache1_addr),
  .din(cache1_din),
  .dout(cache1_dout)
);

sram22_256x32m4w8 cache2 (
  .clk(clk),
  .we(cache2_we),
  .wmask(cache2_mask),
  .addr(cache2_addr),
  .din(cache2_din),
  .dout(cache2_dout)
);

sram22_256x32m4w8 cache3 (
  .clk(clk),
  .we(cache3_we),
  .wmask(cache3_mask),
  .addr(cache3_addr),
  .din(cache3_din),
  .dout(cache3_dout)
);


always @(posedge clk) begin
  if (reset == 1'b1) begin
    state <= IDLE;
    write_step <= 2'd0;
    meta_we <= 1'b0;
    meta_write_dirty <= 1'b0;
    cache_din_sel <= 1'b0;
    cache_we <= 4'b0000;
    cache_addr_sel <= 1'b0;

    cpu_req_addr_hold <= 30'b0;
    cpu_req_data_hold <= 32'b0;
    cpu_req_write_hold <= 4'b0;

    cpu_resp_valid <= 1'b0;
    mem_req_valid <= 1'b0;
    mem_req_rw <= 1'b0;
    mem_req_data_valid <= 1'b0;
  end else begin
    if (state == IDLE) begin
      cache_we <= 4'b0000;
      meta_we <= 1'b0;

      cpu_resp_valid <= 1'b0;
      mem_req_valid <= 1'b0;
      mem_req_rw <= 1'b0;
      mem_req_data_valid <= 1'b0;

      if (cpu_req_valid == 1'b1) begin    
        cache_addr_sel <= 1'b0;
        cache_din_sel <= 1'b0;
        cpu_req_addr_hold <= cpu_req_addr;
        cpu_req_data_hold <= cpu_req_data;
        cpu_req_write_hold <= cpu_req_write;
        state <= META;
      end
    end else if (state == META) begin
      if ((req_tag == meta_tag) && (meta_valid == 1'b1)) begin
        if (cpu_req_write == 4'b0000) begin
          cpu_resp_valid <= 1'b1;
        end else begin
          if (req_cache == 2'd0) cache_we <= 4'b0001;
          else if (req_cache == 2'd1) cache_we <= 4'b0010;
          else if (req_cache == 2'd2) cache_we <= 4'b0100;
          else if (req_cache == 2'd3) cache_we <= 4'b1000;

          meta_write_dirty <= 1'b1;
          meta_we <= 1'b1;
        end
        state <= IDLE;
      end else begin
        if (meta_dirty == 1'b1) begin
          mem_req_rw <= 1'b0;               // ****** SAME PATH 1
          mem_req_valid <= 1'b0;
          mem_req_data_valid <= 1'b0;
          if ((mem_req_ready == 1'b1) && (mem_req_data_ready == 1'b1)) begin
            cache_addr_sel <= 1'b1;
            state <= WB1;
          end
        end else begin
          mem_req_data_valid <= 1'b0;    // ****** SAME PATH 2
          if (mem_req_ready == 1'b1) begin
            mem_req_rw <= 1'b0;
            mem_req_valid <= 1'b1;
            cache_addr_sel <= 1'b1;
            cache_din_sel <= 1'b1;
            meta_we <= 1'b1;
            meta_write_dirty <= 1'b0;
            state <= FETCH1;
          end else begin
            mem_req_valid <= 1'b0;
          end
        end
      end 
    end else if (state == WB0) begin
      mem_req_rw <= 1'b0;               // ****** SAME PATH 1
      mem_req_valid <= 1'b0;
      mem_req_data_valid <= 1'b0;
      if ((mem_req_ready == 1'b1) && (mem_req_data_ready == 1'b1)) begin
        cache_addr_sel <= 1'b1;
        state <= WB1;
      end
    end else if (state == WB1) begin
      mem_req_rw <= 1'b1;
      mem_req_valid <= 1'b1;
      mem_req_data_valid <= 1'b1;
      if (write_step + 1 == 4) begin
        write_step <= 2'd0;
        state <= FETCH0;
      end else begin
        write_step <= write_step + 1'b1;
        state <= WB0;
      end
    end else if (state == FETCH0) begin
      mem_req_data_valid <= 1'b0;        // ****** SAME PATH 2
      if (mem_req_ready == 1'b1) begin
        mem_req_rw <= 1'b0;
        mem_req_valid <= 1'b1;
        cache_addr_sel <= 1'b1;
        cache_din_sel <= 1'b1;
        meta_we <= 1'b1;
        meta_write_dirty <= 1'b0;
        state <= FETCH1;
      end else begin
        mem_req_valid <= 1'b0;
      end
    end else if (state == FETCH1) begin
      if (mem_resp_valid == 1'b1) begin
        if (write_step + 1 == 4) begin
          write_step <= 2'd0;
          cache_din_sel <= 1'b0;
          state <= META;
        end else begin
          write_step <= write_step + 1'b1;
          meta_we <= 1'b0;
          mem_req_valid <= 1'b0;
          state <= FETCH1;
        end
      end
    end
  end
end

endmodule
