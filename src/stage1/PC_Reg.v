// Module: PC_Reg.v
// Desc:   32-bit Program Counter Register for the RISC-V Processor
// Inputs: 
//    PC_In: 32-bit PC value to latch
//    clk: Clock line
//    reset: Reset line
//    stall: Stall counter
// 						
// Outputs:
//    PC_Out: 32-bit PC value for current state


`include "const.vh"

module PC_Reg(
    input [31:0] PC_In,
    input clk,
    input reset,
    input stall,

    output reg [31:0] PC_Out
);

always @(posedge clk) begin
    if (reset == 1'b1) PC_Out <= `PC_RESET;
    else if (stall == 1'b0) PC_Out <= PC_In; 
end

endmodule