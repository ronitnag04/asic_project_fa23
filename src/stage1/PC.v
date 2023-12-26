// Module: PC.v
// Desc:   Program Counter w/ synchronous reset, stall, and ALU load
// Inputs: 
//    alu_out: 32-bit value from alu_out in stage2
//    clk: Clock line
//    reset: Reset line
//
//    stall: Stall counter
//    pc_sel: Select next PC (0: PC + 4, 1: alu_out)
// 						
// Outputs:
//    pc_out: 32-bit PC value for current state

`include "const.vh"

module PC (
    input [31:0] alu_out,
    input clk,
    input reset,
    input stall,
    input pc_sel,

    output reg [31:0] pc_out
);


always @(posedge clk) begin
    if (reset) pc_out <= `PC_RESET;
    else if (stall) pc_out <= pc_out;
    else pc_out <= (pc_sel == 1'b0) ? pc_out + 4 : alu_out;
end

assert property (@(posedge clk) reset |-> (pc_out == `PC_RESET));

endmodule