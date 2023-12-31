// Module: ImmGenC.v
// Desc:   Control for ImmGen
// Inputs: 
//    opcode: 7-bit opcode from inst[6:0]
//    funct3: 3-bit function code from inst[14:12]
// 						
// Outputs:
//    imm_type: 3-bit encoding for Immediate type
//             NOTE: encoding is in stage1/stage1_control.vh 

`include "stage1/ImmGen.vh"
`include "Opcode.vh"

module ImmGenC (
    input [6:0] opcode,
    input [2:0] funct3,

    output reg [2:0] imm_type
);

always @(*) begin
  case (opcode)

    `OPC_ARI_RTYPE: imm_type <= `R_TYPE;
    
    `OPC_ARI_ITYPE: begin
      case (funct3)
        `FNC_ADD_SUB,
        `FNC_AND,
        `FNC_OR,
        `FNC_XOR,
        `FNC_SLT,
        `FNC_SLTU    : imm_type <= `I_TYPE;

        `FNC_SLL,
        `FNC_SRL_SRA : imm_type <= `ISTAR_TYPE;

        default      : imm_type <= `X_TYPE;
      endcase
    end

    `OPC_JALR,
    `OPC_LOAD        : imm_type <= `I_TYPE;

    `OPC_STORE       : imm_type <= `S_TYPE;

    `OPC_BRANCH      : imm_type <= `B_TYPE;

    `OPC_AUIPC,
    `OPC_LUI         : imm_type <= `U_TYPE;

    `OPC_JAL         : imm_type <= `J_TYPE;

    default : imm_type <= `X_TYPE;
  endcase
end

endmodule