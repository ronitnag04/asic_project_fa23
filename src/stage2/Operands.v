// Module: Operands.v
// Desc:   Selects operands to send to ALU
// Inputs: 
//      opcode: 7-bit opcode from instruction
//      rs1: 5-bit register 1 index from instruction
//      rs2: 5-bit register 2 index from instruction
//      pc: 32-bit program counter
//      rs1d: 32-bit data from RegFile
//      rs2d: 32-bit data from RegFile
//      imm: 32-bit Immediate
//      rd_mw: 5-bit Destination register for Stage 3/MW
//      rwe_mw: Register Write enable for Stage 3/MW
//      wb_data_mw: 32-bit writeback data from Stage 3/MW
// 
// Outputs: 
//      A: 32-bit Operand A
//      B: 32-bit Operand B

`include "Opcode.vh"

module Operands (
    input [6:0] opcode,
    input [4:0] rs1,
    input [4:0] rs2,

    input [31:0] pc,
    input [31:0] rs1d,
    input [31:0] rs2d,
    input [31:0] imm,

    input [4:0] rd_mw,  
    input rwe_mw,
    input [31:0] wb_data_mw,
    
    output [31:0] A,
    output [31:0] B
);

wire [31:0] rs1d_clean, rs2d_clean;
assign rs1d_clean = ((rd_mw == rs1) && (rwe_mw == 1'b1) && (rd_mw != 5'b0)) ? wb_data_mw : rs1d;
assign rs2d_clean = ((rd_mw == rs2) && (rwe_mw == 1'b1) && (rd_mw != 5'b0)) ? wb_data_mw : rs2d;

reg A_Sel, B_Sel;
assign A = (A_Sel == 1'b1) ? pc  : rs1d_clean;
assign B = (B_Sel == 1'b1) ? imm : rs2d_clean;

always @(*) begin
  case (opcode)

    // rs1 op rs2
    `OPC_ARI_RTYPE: begin
        A_Sel <= 1'b0;
        B_Sel <= 1'b0;
    end
    
    // rs1 op imm
    `OPC_JALR,
    `OPC_LUI,               // A_Sel doesn't matter for LUI, since ALU op is COPY_B
    `OPC_STORE,
    `OPC_LOAD,
    `OPC_ARI_ITYPE: begin
        A_Sel <= 1'b0;
        B_Sel <= 1'b1;
    end

    // pc op imm
    `OPC_JAL,
    `OPC_BRANCH,
    `OPC_AUIPC: begin
        A_Sel <= 1'b1;     
        B_Sel <= 1'b1;
    end

    default : begin
        A_Sel <= 1'b0;
        B_Sel <= 1'b0;
    end
  endcase
end


endmodule