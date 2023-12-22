`ifndef STAGE1_CONTROL
`define STAGE1_CONTROL

// PC 
`define PC_SEL_PC_4      1'b0
`define PC_SEL_ALU_OUT   1'b1

// ImmGen
`define R_TYPE           3'b000
`define I_TYPE           3'b001
`define ISTAR_TYPE       3'b010
`define S_TYPE           3'b011
`define B_TYPE           3'b100
`define U_TYPE           3'b101
`define J_TYPE           3'b110
`define X_TYPE           3'b111

`endif //STAGE1_CONTROL