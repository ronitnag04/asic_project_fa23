// Module: Control_MW.v
// Desc: Control for Stage 3/MW
// Inputs: 
//      opcode: 7-Bit opcode from instruction
//      funct3: 3-Bit function code from instruction
// 
// Outputs: 
//      w_mask: 4-Bit write mask for data memory
//      re: Read Enable for data memory
//      wb_sel: 2-Bit Write Back select         
//              NOTE: Not defined for Branch/Store since rwe is 0
//      rwe: Register Write Enable

`include "Opcode.vh"
`include "stage3/Control_MW.vh"

module Control_MW (
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
            endcase
        end

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

        // wb_sel
        `OPC_AUIPC,
        `OPC_LUI,  
        `OPC_ARI_RTYPE, 
        `OPC_ARI_ITYPE  : wb_sel <= `SEL_ALU;

        `OPC_LOAD       : wb_sel <= `SEL_MEM;
 
        `OPC_JAL,  
        `OPC_JALR       : wb_sel <= `SEL_PC4;     
   
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

        default : begin
            w_mask <= 4'b0;
            re <= 1'b0;
            rwe <= 1'b0;
        end
    endcase
end

endmodule