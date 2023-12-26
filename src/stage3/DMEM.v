// Module: DMEM.v
// Desc: Interface from Data Memory. Handles data aligning
// Inputs: 
//      clk: Clock Line
//      stall: Stall line
//      reset: Reset Line
//
//      addr: 32-Bit address from ALU in Transfer_2_3
//      din: 32-Bit write data from rs2d in Transfer_2_3
//      re: Read enable
//      w_mask: 4-bit write mask from stage 3 control
//      funct3: 3-bit funct code (used for sign extension)
//
//      dcache_dout: 32-Bit data memory data
//   
// Outputs: 
//      dcache_addr: 32-Bit address to send to dcache
//      dcache_we: 4-Bit write enable mask
//      dcache_re: Read Enable
//      dcache_din: 32-Bit write data
//
//      dout: 32-bit data to pass to write back

`include "Opcode.vh"

module DMEM (
    input clk,
    input stall,
    input reset,

    input [31:0] addr,
    input [31:0] din,
    input re,
    input [3:0] w_mask,
    input [2:0] funct3,

    output [31:0] dcache_addr,
    output [31:0] dcache_din,
    output reg dcache_re,
    output reg [3:0] dcache_we,

    input [31:0] dcache_dout,  

    output [31:0] dout    
);

assign dcache_addr = addr;
wire [3:0] we;

always @(*) begin
    if (reset == 1'b1) begin
        dcache_re <= 1'b0;
        dcache_we <= 4'b0;
    end else if (stall == 1'b0) begin
        dcache_re <= re;
        dcache_we <= we;
    end
end

// Load Data Extending/Selecting

wire [7:0] load_byte;
assign load_byte = (addr[1:0] == 2'b11) ? dcache_dout[31:24] :
                   (addr[1:0] == 2'b10) ? dcache_dout[23:16] :
                   (addr[1:0] == 2'b01) ? dcache_dout[15:8]  :
                   (addr[1:0] == 2'b00) ? dcache_dout[7:0]   :
                   8'bx;
wire [15:0] load_half;
assign load_half = (addr[1] == 1'b1) ? dcache_dout[31:16]  :
                   (addr[1] == 1'b0) ? dcache_dout[15:0]   :
                   16'bx;

wire [31:0] dout_lb, dout_lbu, dout_lh, dout_lhu, dout_lw;
assign dout_lb = {{24{load_byte[7]}}, load_byte};
assign dout_lbu = {{24{1'b0}}, load_byte};
assign dout_lh = {{16{load_half[15]}}, load_half};
assign dout_lhu = {{16{1'b0}}, load_half};
assign dout_lw = dcache_dout;

assign dout = (funct3 == `FNC_LB)  ? dout_lb    :
              (funct3 == `FNC_LBU) ? dout_lbu   :
              (funct3 == `FNC_LH)  ? dout_lh    :
              (funct3 == `FNC_LHU) ? dout_lhu   :
              (funct3 == `FNC_LW)  ? dout_lw    :
              32'bx;

// Store data Selecting/Masking

wire [7:0] store_byte;
assign store_byte = din[7:0];
wire [15:0] store_half;
assign store_half = din[15:0];

wire [31:0] din_sb, din_sh, din_sw;
assign din_sb = (addr[1:0] == 2'b11) ? {store_byte, {24{1'b0}}}            :
                (addr[1:0] == 2'b10) ? {{8{1'b0}}, store_byte, {16{1'b0}}} :
                (addr[1:0] == 2'b01) ? {{16{1'b0}}, store_byte, {8{1'b0}}} :
                (addr[1:0] == 2'b00) ? {{24{1'b0}}, store_byte}            :
                32'bx;

assign din_sh = (addr[1] == 1'b1) ? {store_half, {16{1'b0}}}  :
                (addr[1] == 1'b0) ? {{16{1'b0}}, store_half}  :
                32'bx;

assign din_sw = din;

assign dcache_din = (funct3 == `FNC_SB)  ? din_sb    :
                    (funct3 == `FNC_SH)  ? din_sh    :
                    (funct3 == `FNC_SW)  ? din_sw    :
                    32'bx;

wire [3:0] we_byte, we_half, we_word;
assign we_byte = (addr[1:0] == 2'b11) ? {w_mask[0], 3'b0}       :
                 (addr[1:0] == 2'b10) ? {1'b0, w_mask[0], 2'b0} :
                 (addr[1:0] == 2'b01) ? {2'b0, w_mask[0], 1'b0} :
                 (addr[1:0] == 2'b00) ? {3'b0, w_mask[0]}       :
                 4'bx;
assign we_half = (addr[1] == 1'b1) ? {w_mask[1:0], 2'b0}  :
                 (addr[1] == 1'b0) ? {2'b0, w_mask[1:0]}  :
                 4'bx;
assign we_word = w_mask;

assign we = (funct3 == `FNC_SB)  ? we_byte :
            (funct3 == `FNC_SH)  ? we_half :
            (funct3 == `FNC_SW)  ? we_word :
            4'b0;

endmodule