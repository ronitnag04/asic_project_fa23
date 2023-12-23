// Module: Stage1.v
// Desc: Stage 1 High Level Module 
// Inputs: 
//    Must be valid before posedge clk
//      alu_out_mw:  32-Bit ALU Out data from Stage 3/MW
//      pc_sel_mw:   PC Select line from Stage 3/MW
//      wb_data_mw:  32-Bit Write Back data from Stage 3/MW
//      rwe_mw:   Register Write Enable from Stage 3/MW
//      rd_mw:    5-Bit Write Back register from Stage 3/MW
//
//    Must be valid after posedge clk
//      icache_dout: 32-Bit read data from IMEM (Memory151)
//      jump_x   : Jump Active signal from Stage 2/X
//
//      clk: Clock
//      stall: Stall line
//      reset: Synchronous Reset line      
//
// Outputs:  
//    Valid after posedge clk
//      pc: 32-Bit Program Counter
//      icache_addr: 32-Bit Instruction Memory Address
//      icache_re:   Read Enable signal for Instruction Memory  
//  
//    Valid after posedge clk
//      rs1d: 32-Bit data for rs1
//      rs2d: 32-Bit data for rs2
//      imm:  32-Bit immediate 
//      inst: 32-Bit instruction, filtered by flush conditions
//      

`include "const.vh"

module Stage1 (
    input clk,
    input reset,

    input [31:0] alu_out_mw,
    input pc_sel_mw,
    input [31:0] wb_data_mw,
    input rwe_mw,
    input [4:0] rd_mw,

    output [31:0] icache_addr,
    output icache_re,

    input stall,

    input [31:0] icache_dout,
    input jump_x,
    
    output [31:0] pc,
    output [31:0] rs1d,
    output [31:0] rs2d,
    output [31:0] imm,
    output [31:0] inst
);

wire [31:0] inst_in;
assign inst = ((jump_x == 1'b1) || (pc_sel_mw == 1'b1)) ? `INSTR_NOP : inst_in;
//Flush Conditions:
//     If previous instruction is a successful branch, or jump
//     If 2-previous instruction is causing PCSel to be ALU and not PC+4 

PC PC(
    .alu_out(alu_out_mw),
    .clk(clk),
    .reset(reset),
    .stall(stall),
    .pc_sel(pc_sel_mw),

    .pc_out(pc)
);

IMEM IMEM(
    .pc(pc),
    .clk(clk),

    .addr(icache_addr),
    .re(icache_re),

    .dout(icache_dout),
    
    .inst(inst_in)
);

RegFile RegFile(
    .rs1(inst_in[19:15]),
    .rs2(inst_in[24:20]),
    .rd(inst),
    .wb_data(rd_mw),
    .we(rwe_mw),
    .stall(stall),
    .clk(clk),
    .reset(reset),

    .rs1d(rs1d),
    .rs2d(rs2d)
);

ImmGen ImmGen(
    .inst(inst_in),

    .imm(imm)
);

endmodule