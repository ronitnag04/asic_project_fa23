// Module: ImmGenDP.v
// Desc:   Datapath for ImmGen
// Inputs: 
//    inst: 32-bit instruction
//    imm_type: 3-bit encoding for Immediate type
//             NOTE: encoding is in stage1/stage1_control.vh  
// 						
// Outputs:
//    imm: 32-bit Immediate value
//         NOTE: I, S, B, U, and J -type immediates are sign-extended
//               I*-type immediates are NOT sign-extended

`include "stage1/stage1_control.vh"

module ImmGenDP (
    input [31:0] inst,
    input  [2:0] imm_type,

    output [31:0] imm
);

wire [31:0] R_imm, I_imm, Istar_imm, S_imm, B_imm, U_imm, J_imm;

assign R_imm     = 32'b0;                           // Unused so value can be anything testbench expects 0
assign I_imm     = {{21{inst[31]}}, inst[30:20]};
assign Istar_imm = {{27{0}}, inst[24:20]};          // No sign-extension necessary 
                                                    // Shifter should sign extend rs1, but imm (i.e. shift amount) is [0-31]
assign S_imm     = {{21{inst[31]}}, inst[30:25], inst[11:7]};
assign B_imm     = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
assign U_imm     = {inst[31:12], 12'b0};
assign J_imm     = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:25], inst[24:21], 1'b0};

assign imm = (imm_type == `R_TYPE)     ? R_imm :
             (imm_type == `I_TYPE)     ? I_imm :
             (imm_type == `ISTAR_TYPE) ? Istar_imm :
             (imm_type == `S_TYPE)     ? S_imm :
             (imm_type == `B_TYPE)     ? B_imm :
             (imm_type == `U_TYPE)     ? U_imm :
             (imm_type == `J_TYPE)     ? J_imm :
             32'bx;


endmodule