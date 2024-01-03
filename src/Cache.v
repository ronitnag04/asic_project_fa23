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

reg [2:0] state;
localparam IDLE   = 3'b000;
localparam META   = 3'b001;
localparam WB0    = 3'b010;
localparam WB1    = 3'b011;
localparam FETCH0 = 3'b100;
localparam FETCH1 = 3'b101;
localparam WRITE  = 3'b110;

assign cpu_req_ready = (state == IDLE) ? 1'b1 : 1'b0;

// CPU Req Addr
// Bit: 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2
// Idx: 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
//       T  T  T  T  T  T  T  T  T  T  T  T  T  T  T  T  T  T  T  T  I  I  I  I  I  I  O  O  O  O 

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
reg [1:0] write_step;
wire [7:0] write_index_cache = {req_index_true, write_step};
assign mem_req_addr = {req_tag_true, req_index_true, write_step};


// Metadata Entry:
// 0-15: rows 0-63, 16-31: rows 64-127, 32-47: rows 128-191, 48-63: rows 192-255, 
// Bit: 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
// USE: | ------------------------- TAG ------------------------- |  V  D  | --------- UNUSED --------|

wire [5:0] meta_addr = req_index_true;
wire [31:0] meta_dout;
wire [19:0] meta_tag = meta_dout[31:12];
wire meta_valid = meta_dout[11];
wire meta_dirty = meta_dout[10];

wire cache_hit = ((req_tag_true == meta_tag) && (meta_valid == 1'b1)) ? 1'b1 : 1'b0;

wire cache_write = ((state == META || state == IDLE) && 
                    (cache_hit == 1'b1) && (cpu_req_write_true != 4'b0000)) ? 1'b1 : 1'b0;
wire mem_write = ((state == FETCH1) && (mem_resp_valid == 1'b1)) ? 1'b1 : 1'b0;

wire meta_we = ((cache_write == 1'b1) || ((mem_write == 1'b1) && (write_step != 2'b11))) ? 1'b1 : 1'b0;
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


wire [31:0] cache0_dout, cache1_dout, cache2_dout, cache3_dout;

assign cpu_resp_data = (req_cache_hold == 2'b00) ? cache0_dout :
                       (req_cache_hold == 2'b01) ? cache1_dout :
                       (req_cache_hold == 2'b10) ? cache2_dout :
                       (req_cache_hold == 2'b11) ? cache3_dout :
                       32'bx;

assign mem_req_data_bits = {cache3_dout, cache2_dout, cache1_dout, cache0_dout};
assign mem_req_data_mask = 16'b1111_1111_1111_1111;     // Optimize by only writing back dirty sections

assign mem_req_valid = ((state == WB1) || ((state == FETCH1) && (write_step == 2'b00))) ? 1'b1 : 1'b0;
assign mem_req_rw = (state == WB1) ? 1'b1 :
                    (state == FETCH1) ? 1'b0: 1'bx;
assign mem_req_data_valid = (state == WB1) ? 1'b1 : 1'b0;

wire [31:0] cache0_din, cache1_din, cache2_din, cache3_din;

assign cache0_din = (state == FETCH1) ? mem_resp_data[31:0]   : cpu_req_data_true;
assign cache1_din = (state == FETCH1) ? mem_resp_data[63:32]  : cpu_req_data_true;
assign cache2_din = (state == FETCH1) ? mem_resp_data[95:64]  : cpu_req_data_true;
assign cache3_din = (state == FETCH1) ? mem_resp_data[127:96] : cpu_req_data_true;

wire cache0_we = ((cache_write) && (req_cache_true == 2'b00)) ? 1'b1 : 
                 (mem_write == 1'b1) ? 1'b1 : 1'b0;
wire cache1_we = ((cache_write) && (req_cache_true == 2'b01)) ? 1'b1 : 
                 (mem_write == 1'b1) ? 1'b1 : 1'b0;
wire cache2_we = ((cache_write) && (req_cache_true == 2'b10)) ? 1'b1 : 
                 (mem_write == 1'b1) ? 1'b1 : 1'b0;
wire cache3_we = ((cache_write) && (req_cache_true == 2'b11)) ? 1'b1 : 
                 (mem_write == 1'b1) ? 1'b1 : 1'b0;

wire [3:0] cache0_mask, cache1_mask, cache2_mask, cache3_mask;
assign cache0_mask = (state == FETCH1) ? 4'b1111: cpu_req_write_true;
assign cache1_mask = (state == FETCH1) ? 4'b1111: cpu_req_write_true;
assign cache2_mask = (state == FETCH1) ? 4'b1111: cpu_req_write_true;
assign cache3_mask = (state == FETCH1) ? 4'b1111: cpu_req_write_true;

wire [7:0] cache0_addr, cache1_addr, cache2_addr, cache3_addr;

assign cache0_addr = ((state == IDLE) || (state == META) || (state == WRITE)) ? req_index_cache : write_index_cache;
assign cache1_addr = ((state == IDLE) || (state == META) || (state == WRITE)) ? req_index_cache : write_index_cache;
assign cache2_addr = ((state == IDLE) || (state == META) || (state == WRITE)) ? req_index_cache : write_index_cache;
assign cache3_addr = ((state == IDLE) || (state == META) || (state == WRITE)) ? req_index_cache : write_index_cache;

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

    cpu_req_addr_hold <= 30'b0;
    cpu_req_data_hold <= 32'b0;
    cpu_req_write_hold <= 4'b0;

    cpu_resp_valid <= 1'b0;
  end else begin
    if (state == IDLE) begin
      cpu_resp_valid <= 1'b0;

      if (cpu_req_valid == 1'b1) begin
        if ((req_tag == req_tag_hold) && (req_index == req_index_hold) && (cache_hit == 1'b1)) begin
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
          if ((mem_req_ready == 1'b1) && (mem_req_data_ready == 1'b1)) begin    // ****** SAME PATH 1
            state <= WB1;
          end else begin
            state <= WB0;
          end
        end else begin
          if (mem_req_ready == 1'b1) begin    // ****** SAME PATH 2
            state <= FETCH1;
          end else begin
            state <= FETCH0;
          end
        end
      end
    end else if (state == WRITE) begin
      state <= IDLE;
    end else if (state == WB0) begin
      if ((mem_req_ready == 1'b1) && (mem_req_data_ready == 1'b1)) begin   // ****** SAME PATH 1
        state <= WB1;
      end
    end else if (state == FETCH0) begin  // ****** SAME PATH 2
      if (mem_req_ready == 1'b1) begin
        state <= FETCH1;
      end
    end else if (state == WB1) begin
      if (write_step == 2'b11) begin
        write_step <= 2'd0;
        state <= FETCH0;
      end else begin
        write_step <= write_step + 1'b1;
        state <= WB0;
      end
    end else if (state == FETCH1) begin
      if (mem_resp_valid == 1'b1) begin
        if (write_step == 2'b11) begin
          write_step <= 2'd0;
          state <= META;
        end else begin
          write_step <= write_step + 1'b1;
        end
      end
    end
  end
end

endmodule