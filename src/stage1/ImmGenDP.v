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
    input [24:0] inst_31_7,

    input  [2:0] imm_type,

    output [31:0] imm
);

// inst         31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10  9  8  7
// inst_31_7    24 23 22 21 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0

wire [31:0] I_imm, Istar_imm, S_imm, B_imm, U_imm, J_imm;

assign I_imm     = {{21{inst_31_7[24]}}, inst_31_7[23:13]};
assign Istar_imm = {{27{1'b0}}, inst_31_7[17:13]};          // No sign-extension necessary 
                                                            // Shifter should sign extend rs1, but imm (i.e. shift amount) is [0-31]
assign S_imm     = {{21{inst_31_7[24]}}, inst_31_7[23:18], inst_31_7[4:0]};
assign B_imm     = {{20{inst_31_7[24]}}, inst_31_7[0], inst_31_7[23:18], inst_31_7[4:1], 1'b0};
assign U_imm     = {inst_31_7[24:5], 12'b0};
assign J_imm     = {{12{inst_31_7[24]}}, inst_31_7[12:5], inst_31_7[13], inst_31_7[23:18], inst_31_7[17:14], 1'b0};

assign imm = (imm_type == `I_TYPE)     ? I_imm :
             (imm_type == `ISTAR_TYPE) ? Istar_imm :
             (imm_type == `S_TYPE)     ? S_imm :
             (imm_type == `B_TYPE)     ? B_imm :
             (imm_type == `U_TYPE)     ? U_imm :
             (imm_type == `J_TYPE)     ? J_imm :
             32'bx;                                         // R-Type testbench expects x


endmodule