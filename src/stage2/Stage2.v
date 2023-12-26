// Module: Stage2.v
// Desc: Stage 2 High Level Module
// Inputs: 
//      pc: 32-Bit Program Counter from Transfer_1_2
//      rs1d: 32-Bit rs1 regfile data from Transfer_1_2
//      rs2d: 32-Bit rs2 regfile data from Transfer_1_2
//      imm: 32-Bit immediate from Transfer_1_2
//      inst: 32-Bit instruction from Transfer_1_2
// 
//      wb_data_mw: 32-Bit Writeback data from Stage 3/MW
//      rwe_mw: Register Write Enable from Stage 3/MW
//      rd_mw: Register Destination index from Stage 3/MW 
// 
// Outputs: 
//      alu_out: 32-Bit ALU output
//      rs2d_clean: 32-Bit rs2d data after forwarding
//      jump: jump signal

module Stage2 (
    input [31:0] pc,
    input [31:0] rs1d,
    input [31:0] rs2d,
    input [31:0] imm,
    input [31:0] inst,

    input [31:0] wb_data_mw,
    input rwe_mw,
    input [4:0] rd_mw,

    output [31:0] alu_out,
    output [31:0] rs2d_clean,
    output jump,    
);

wire sel_rs1d, sel_rs2d, sel_a, sel_b;

Operands Operands(
    .opcode(inst[6:0]),
    .rs1(inst[19:15]),
    .rs2(inst[24:20]),

    .rd_mw(rd_mw),  
    .rwe_mw(rwe_mw),
    
    .sel_rs1d(sel_rs1d),
    .sel_rs2d(sel_rs2d),
    .sel_a(sel_a),
    .sel_b(sel_b)
);

wire [31:0] rs1d_clean, A, B;
assign rs1d_clean = (sel_rs1d == 1'b1) ? wb_data_mw : rs1d;
assign rs2d_clean = (sel_rs2d == 1'b1) ? wb_data_mw : rs2d;
assign A = (sel_a == 1'b1) ? pc : rs1d_clean;
assign B = (sel_b == 1'b1) ? imm : rs2d_clean;

wire [3:0] ALUop;

ALU ALU(
    .A(A),
    .B(B),
    .ALUop(ALUop),
    .Out(alu_out)
);

ALUdec ALUdec(
  .opcode(inst[6:0]),
  .funct(inst[14:12]),
  .add_rshift_type(inst[30]),
  .ALUop(ALUop)
);

wire s, eq, lt;

Jump Jump(
    .opcode(inst[6:0]),
    .funct3(inst[14:12]),
    
    .s(s),

    .lt(lt),
    .eq(eq),

    .jump(jump) 
);

Comparator Comparator(
    .rs1d(rs1d_clean),
    .rs2d(rs2d_clean),
    .s(s),

    .eq(eq),
    .lt(lt)
);

endmodule