// Module: ALU.v
// Desc:   32-bit ALU for the RISC-V Processor
// Inputs: 
//    A: 32-bit value
//    B: 32-bit value
//    ALUop: Selects the ALU's operation 
// 						
// Outputs:
//    Out: The chosen function mapped to A and B.

`include "Opcode.vh"
`include "stage2/ALUop.vh"

module ALU(
    input [31:0] A,B,
    input [3:0] ALUop,
    output reg [31:0] Out
);

always @(*) begin
    case (ALUop)
        `ALU_ADD    : Out <= A + B;  
        `ALU_SUB    : Out <= A - B;  
        `ALU_AND    : Out <= A & B;  
        `ALU_OR     : Out <= A | B;  
        `ALU_XOR    : Out <= A ^ B;  
        `ALU_SLT    : Out <= ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;  
        `ALU_SLTU   : Out <= (A < B) ? 32'd1 : 32'd0;  
        `ALU_SLL    : Out <= A << B;  
        `ALU_SRA    : Out <= $signed(A) >>> B;  
        `ALU_SRL    : Out <= A >> B;  
        `ALU_COPY_B : Out <= B;   
        `ALU_XXX    : Out <= 32'd0;   
    endcase
end

endmodule
