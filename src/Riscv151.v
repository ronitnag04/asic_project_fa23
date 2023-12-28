`include "const.vh"

module Riscv151(
    input clk,
    input reset,

    // Memory system ports
    output [31:0] dcache_addr,
    output [31:0] icache_addr,
    output [3:0] dcache_we,
    output dcache_re,
    output icache_re,
    output [31:0] dcache_din,
    input [31:0] dcache_dout,
    input [31:0] icache_dout,
    input stall,
    output [31:0] csr

);

wire [31:0] alu_out_w, wb_data_w;
wire pc_sel_w, rwe_w, csr_we;
wire [31:0] inst_w;
wire [31:0] pc_i, rs1d_i, rs2d_i, imm_i, inst_i;
wire [31:0] pc_x, rs1d_x, rs2d_x, imm_x, inst_x;
wire [31:0] alu_out_x, dout_x;
wire jump_x; 
wire [31:0] pc_w, dout_w;
wire jump_w;

Stage1 Stage1(
    .clk(clk),
    .reset(reset),

    .alu_out_w(alu_out_w),
    .pc_sel_w(pc_sel_w),
    .wb_data_w(wb_data_w),
    .rwe_w(rwe_w),
    .rd_w(inst_w[11:7]),
    .csr_i_w(inst_w[31:20]),
    .csr_we(csr_we),

    .icache_addr(icache_addr),
    .icache_re(icache_re),

    .stall(stall),

    .icache_dout(icache_dout),
    .jump_x(jump_x),
    
    .pc(pc_i),
    .rs1d(rs1d_i),
    .rs2d(rs2d_i),
    .imm(imm_i),
    .inst(inst_i),
    .csrd_tohost(csr)
);

Transfer_1_2 Transfer_1_2(
    .clk(clk),
    .stall(stall),
    .reset(reset),

    .pc_in(pc_i),
    .rs1d_in(rs1d_i),
    .rs2d_in(rs2d_i),
    .imm_in(imm_i),
    .inst_in(inst_i),

    .pc_out(pc_x),
    .rs1d_out(rs1d_x),
    .rs2d_out(rs2d_x),
    .imm_out(imm_x),
    .inst_out(inst_x)
);

Stage2 Stage2(
    .clk(clk),
    .reset(reset),
    .stall(stall),

    .pc(pc_x),
    .rs1d(rs1d_x),
    .rs2d(rs2d_x),
    .imm(imm_x),
    .inst(inst_x),

    .wb_data_w(wb_data_w),
    .rwe_w(rwe_w),
    .rd_w(inst_w[11:7]),

    .alu_out(alu_out_x),
    .jump(jump_x),                

    .dcache_addr(dcache_addr),  
    .dcache_we(dcache_we),     
    .dcache_re(dcache_re),           
    .dcache_din(dcache_din),       

    .dcache_dout(dcache_dout),   

    .dout(dout_x)
);

Transfer_2_3 Transfer_2_3(
    .clk(clk),
    .stall(stall),
    .reset(reset),

    .pc_in(pc_x),
    .alu_out_in(alu_out_x),
    .dout_in(dout_x),
    .jump_in(jump_x),
    .inst_in(inst_x),

    .pc_out(pc_w),
    .alu_out_out(alu_out_w),
    .dout_out(dout_w),
    .jump_out(jump_w),
    .inst_out(inst_w)
);

Stage3 Stage3(
    .pc(pc_w),            
    .alu_out(alu_out_w),       
    .dout(dout_w),          
    .inst(inst_w),          
    .jump(jump_w), 

    .wb_data(wb_data_w),      
    .pc_sel(pc_sel_w),              
    .rwe(rwe_w),
    .csr_we(csr_we)  
);


endmodule
