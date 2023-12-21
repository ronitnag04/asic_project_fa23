// Module: PC.v
// Desc:   Program Counter w/ synchronous reset, stall, and ALU load
// Inputs: 
//    ALU_Out: 32-bit value from ALU_Out in stage2
//    clk: Clock line
//    reset: Reset line
//
//    stall: Stall counter
//    PC_Sel: Select next PC (0: PC + 4, 1: ALU_Out)
// 						
// Outputs:
//    PC_Out: 32-bit PC value for current state

`include "stage1/stage1_control.vh"
`include "const.vh"

module PC (
    input [31:0] ALU_Out,
    input clk,
    input reset,
    input stall,
    input PC_Sel,

    output reg [31:0] PC_Out
);


always @(posedge clk) begin
    if (reset) PC_Out <= `PC_RESET;
    else if (stall) PC_Out <= PC_Out;
    else PC_Out <= (PC_Sel == `PC_SEL_PC_4) ? PC_Out + 4 : ALU_Out;
end


endmodule