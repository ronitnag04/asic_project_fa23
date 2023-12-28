// Module: Operands.v
// Desc:   Selects operands to send to ALU
// Inputs: 
//      opcode: 7-bit opcode from instruction
//      rs1: 5-bit register 1 index from instruction
//      rs2: 5-bit register 2 index from instruction
//      rd_w: 5-bit Destination register for Stage 3/W
//      rwe_w: Register Write enable for Stage 3/W
// 
// Outputs:
//      sel_rs1d: 1(wb_data), 0(rs1d) 
//      sel_rs2d: 1(wb_data), 0(rs2d)
//      sel_a: 1(PC), 0(rs1d_clean)
//      sel_b: 1(imm), 0(rs2d_clean)

`include "Opcode.vh"

module Operands (
    input [6:0] opcode,
    input [4:0] rs1,
    input [4:0] rs2,

    input [4:0] rd_w,  
    input rwe_w,
    
    output sel_rs1d,
    output sel_rs2d,
    output reg sel_a,
    output reg sel_b
);

assign sel_rs1d = ((rd_w == rs1) && (rwe_w == 1'b1) && (rd_w != 5'b0)) ? 1'b1 : 1'b0;
assign sel_rs2d = ((rd_w == rs2) && (rwe_w == 1'b1) && (rd_w != 5'b0)) ? 1'b1 : 1'b0;


always @(*) begin
  case (opcode)

    // rs1 op rs2
    `OPC_ARI_RTYPE: begin
        sel_a <= 1'b0;
        sel_b <= 1'b0;
    end
    
    // rs1 op imm
    `OPC_JALR,
    `OPC_LUI,               // sel_a doesn't matter for LUI, since ALU op is COPY_B
    `OPC_STORE,
    `OPC_LOAD,
    `OPC_ARI_ITYPE: begin
        sel_a <= 1'b0;
        sel_b <= 1'b1;
    end

    // pc op imm
    `OPC_JAL,
    `OPC_BRANCH,
    `OPC_AUIPC: begin
        sel_a <= 1'b1;     
        sel_b <= 1'b1;
    end

    default : begin
        sel_a <= 1'b0;
        sel_b <= 1'b0;
    end
  endcase
end


endmodule