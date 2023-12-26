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

wire [31:0] alu_out_mw, wb_data_mw;
wire pc_sel_mw, rwe_mw, csr_we;
wire [31:0] inst_mw;
wire [31:0] pc_i, rs1d_i, rs2d_i, imm_i, inst_i;
wire [31:0] pc_x, rs1d_x, rs2d_x, imm_x, inst_x;
wire [31:0] alu_out_x, rs2d_clean_x;
wire jump_x; 
wire [31:0] pc_mw, rs2d_clean_mw;
wire jump_mw;

Stage1 Stage1(
    .clk(clk),
    .reset(reset),

    .alu_out_mw(alu_out_mw),
    .pc_sel_mw(pc_sel_mw),
    .wb_data_mw(wb_data_mw),
    .rwe_mw(rwe_mw),
    .rd_mw(inst_mw[11:7]),
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
    .csrd(csr)
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
    .pc(pc_x),
    .rs1d(rs1d_x),
    .rs2d(rs2d_x),
    .imm(imm_x),
    .inst(inst_x),

    .wb_data_mw(wb_data_mw),
    .rwe_mw(rwe_mw),
    .rd_mw(inst_mw[11:7]),

    .alu_out(alu_out_x),
    .rs2d_clean(rs2d_clean_x),
    .jump(jump_x) 
);

Transfer_2_3 Transfer_2_3(
    .clk(clk),
    .stall(stall),
    .reset(reset),

    .pc_in(pc_x),
    .alu_out_in(alu_out_x),
    .rs2d_in(rs2d_clean_x),
    .jump_in(jump_x),
    .inst_in(inst_x),

    .pc_out(pc_mw),
    .alu_out_out(alu_out_mw),
    .rs2d_out(rs2d_clean_mw),
    .jump_out(jump_mw),
    .inst_out(inst_mw)
);

Stage3 Stage3(
    .pc(pc_mw),            
    .alu_out(alu_out_mw),       
    .rs2d(rs2d_clean_mw),          
    .inst(inst_mw),          
    .jump(jump_mw),                 
    .clk(clk),
    .reset(reset),                  

    .stall(stall),                

    .dcache_addr(dcache_addr),  
    .dcache_we(dcache_we),     
    .dcache_re(dcache_re),           
    .dcache_din(dcache_din),       

    .dcache_dout(dcache_dout),   

    .wb_data(wb_data_mw),      
    .pc_sel(pc_sel_mw),              
    .rwe(rwe_mw),
    .csr_we(csr_we)  
);


endmodule
