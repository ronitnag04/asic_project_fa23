// Module: MWControl.v
// Desc: Control for Stage 3/MW
// Inputs: 
//      opcode: 7-Bit opcode from instruction
//      funct3: 3-Bit function code from instruction
//      csr: 12-Bit CSR index from instruction
// 
// Outputs: 
//      w_mask: 4-Bit write mask for data memory
//      re: Read Enable for data memory
//      wb_sel: 2-Bit Write Back select         
//              NOTE: Default is 2'bxx for Branch/Store, but doesn't matter since rwe is 0
//      rwe: Register Write Enable
//      csr_we: CSR 0x51E Write Enable

`include "Opcode.vh"
`include "const.vh"
`include "stage3/MWControl.vh"

module MWControl (
    input [6:0] opcode,
    input [2:0] funct3,
    input [11:0] csr,

    output reg [3:0] w_mask,
    output reg re,
    output reg [1:0] wb_sel,
    output reg rwe,
    output csr_we
);

always @(*) begin
    case (opcode) 
        // w_mask
        `OPC_NOOP,
        `OPC_CSR,
        `OPC_LUI,    
        `OPC_AUIPC,  
        `OPC_JAL,    
        `OPC_JALR,   
        `OPC_BRANCH,  
        `OPC_LOAD,  
        `OPC_ARI_ITYPE, 
        `OPC_ARI_RTYPE : w_mask <= 4'b0;
        
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
        `OPC_NOOP,
        `OPC_CSR,
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
        `OPC_CSR,
        `OPC_AUIPC,
        `OPC_LUI,  
        `OPC_ARI_RTYPE, 
        `OPC_ARI_ITYPE  : wb_sel <= `SEL_ALU;

        `OPC_LOAD       : wb_sel <= `SEL_MEM;
 
        `OPC_JAL,  
        `OPC_JALR       : wb_sel <= `SEL_PC4; 

        default : wb_sel <= 2'bxx;
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


        `OPC_NOOP,
        `OPC_CSR,
        `OPC_BRANCH,
        `OPC_STORE      : rwe <= 1'b0;

        default :  rwe <= 1'b0;
    endcase
end

assign csr_we = ((opcode == `OPC_CSR) && 
                 ((funct3 == `FNC_RW) || (funct3 == `FNC_RWI)) &&
                 (csr == `CSR_TOHOST)) ? 1'b1 : 1'b0;

endmodule