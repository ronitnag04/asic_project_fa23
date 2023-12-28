// Module: WControl.v
// Desc: Control for Stage 3/W
// Inputs: 
//      opcode: 7-Bit opcode from instruction
//      funct3: 3-Bit function code from instruction
// 
// Outputs: 
//      w_mask: 4-Bit write mask for data memory
//      re: Read Enable for data memory
//      wb_sel: 2-Bit Write Back select         
//              NOTE: Default is 2'bxx for Branch/Store, but doesn't matter since rwe is 0
//      rwe: Register Write Enable
//      csr_we: CSR Write Enable

`include "Opcode.vh"
`include "stage3/WControl.vh"

module WControl (
    input [6:0] opcode,
    input [2:0] funct3,

    output reg [1:0] wb_sel,
    output reg rwe,
    output csr_we
);

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
                 ((funct3 == `FNC_RW) || (funct3 == `FNC_RWI))) ? 1'b1 : 1'b0;

endmodule