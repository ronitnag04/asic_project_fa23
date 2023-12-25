// Module: Jump.v
// Desc:  Controls and Decodes Comparator for Branch conditions
//        Outputs Jump signal if opcode is jump or branch condition is met
// Inputs: 
//      opcode: 7-bit opcode from instruction
//      funct3: 3-bit function code from instruction
//      
//  Valid after opcode/funct3 have propogated + comparator delay
//      lt: Less Than signal from Comparator
//      eq: Equal signal from Comparator
// 
// Outputs: 
//  Valid after opcode/funct3 have propogated
//      s: signed operation of comparator
//
//  Valid after opcode/funct3 have propogated + comparator delay + jump delay
//      jump: Jump signal, PCSel in stage WB should be 1 if jump is 1

`include "Opcode.vh"

module Jump (
    input [6:0] opcode,
    input [2:0] funct3,
    
    output s,

    input lt,
    input eq,

    output reg jump 
);

assign s = (opcode == `OPC_BRANCH) 
            ? (((funct3 == `FNC_BGEU) || (funct3 == `FNC_BLTU)) ? 1'b0 : 1'b1) 
            : 1'b0; // default to 0 if op doesn't use comparator (or unsigned branch)

always @(*) begin
    case (opcode)
        
        `OPC_JAL,
        `OPC_JALR: jump <= 1'b1;

        `OPC_BRANCH: begin
            case (funct3) 

                `FNC_BEQ  : jump <= (eq == 1'b1) ? 1'b1 : 1'b0;

                `FNC_BGE,
                `FNC_BGEU : jump <= (lt == 1'b0) ? 1'b1 : 1'b0; 

                `FNC_BLT,
                `FNC_BLTU : jump <= (lt == 1'b1) ? 1'b1 : 1'b0; 

                `FNC_BNE  : jump <= (eq == 1'b0) ? 1'b1 : 1'b0;

                default: jump <= 1'b0;
            endcase
        end

        default: jump <= 1'b0;
    endcase
end

endmodule