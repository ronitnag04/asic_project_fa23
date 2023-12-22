// Module: ImmGen.v
// Desc:   Immediate Generator suppporting RV32I ISA
// Inputs: 
//    inst: 32-bit instruction from IMEM
// 						
// Outputs:
//    imm: 32-bit Immediate value
//         NOTE: I, S, B, U, and J -type immediates are sign-extended
//               I*-type immediates are NOT sign-extended

`include "const.vh"

module ImmGen (
    input [31:0] inst,

    output [31:0] imm
);

wire [2:0] imm_type;

ImmGenC control(
    .inst(inst),

    .imm_type(imm_type)
);

ImmGenDP datapath(
    .inst(inst),
    .imm_type(imm_type),

    .imm(imm)
);

endmodule