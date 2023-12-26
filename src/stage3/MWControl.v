// Module: MWControl.v
// Desc: Control for Stage 3/MW
// Inputs: 
//      opcode: 7-Bit opcode from instruction
//      funct3: 3-Bit function code from instruction
// 
// Outputs: 
//      w_mask: 4-Bit write mask for data memory
//      re: Read Enable for data memory
//      wb_sel: 2-Bit Write Back select         
//              NOTE: Default is ALU for Branch/Store, but doesn't matter since rwe is 0
//      rwe: Register Write Enable

`include "Opcode.vh"
`include "stage3/MWControl.vh"

module MWControl (
    input [6:0] opcode,
    input [2:0] funct3,

    output reg [3:0] w_mask,
    output reg re,
    output reg [1:0] wb_sel,
    output reg rwe   
);


always @(*) begin
    case (opcode) 
        // w_mask
        `OPC_LUI,    
        `OPC_AUIPC,  
        `OPC_JAL,    
        `OPC_JALR,   
        `OPC_BRANCH,  
        `OPC_LOAD,  
        `OPC_ARI_ITYPE, 
        `OPC_ARI_RTYPE : w_mask < 4'b0;
        
        `OPC_STORE : begin
            case (funct3)
                `FNC_SB : w_mask <= 4'b0001;
                `FNC_SH : w_mask <= 4'b0011;
                `FNC_SW : w_mask <= 4'b1111;
                default : w_mask <= 4'b0000;
            endcase
        end

        default : w_mask <= 4'b0000;
    endcase
end

always @(*) begin
    case (opcode) 
        // re
        `OPC_LUI,    
        `OPC_AUIPC,  
        `OPC_JAL,    
        `OPC_JALR,   
        `OPC_BRANCH,
        `OPC_STORE,   
        `OPC_ARI_RTYPE,  
        `OPC_ARI_ITYPE : re <= 1'b0;
        
        `OPC_LOAD : re <= 1'b1;

        default : re <= 1'b0;
    endcase
end

always @(*) begin
    case (opcode)
        // wb_sel
        `OPC_AUIPC,
        `OPC_LUI,  
        `OPC_ARI_RTYPE, 
        `OPC_ARI_ITYPE  : wb_sel <= `SEL_ALU;

        `OPC_LOAD       : wb_sel <= `SEL_MEM;
 
        `OPC_JAL,  
        `OPC_JALR       : wb_sel <= `SEL_PC4; 

        default : wb_sel <= `SEL_ALU;
    endcase
end    

always @(*) begin
    case (opcode) 
        // rwe
        `OPC_AUIPC,
        `OPC_LUI,  
        `OPC_ARI_RTYPE, 
        `OPC_ARI_ITYPE,
        `OPC_LOAD,
        `OPC_JAL,  
        `OPC_JALR       : rwe <= 1'b1;

        `OPC_BRANCH,
        `OPC_STORE      : rwe <= 1'b0;

        default :  rwe <= 1'b0;
    endcase
end

endmodule