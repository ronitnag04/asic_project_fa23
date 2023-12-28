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

wire [31:0] next_pc;
assign next_pc = (reset == 1'b1)  ? `PC_RESET  :
                 (stall == 1'b1)  ? pc_out     :
                 (pc_sel == 1'b0) ? pc_out + 4 :
                 (pc_sel == 1'b1) ? alu_out    :
                 32'bx; 

always @(posedge clk) begin
    pc_out <= next_pc;
end

pc_reset: assert property (@(posedge clk) reset |=> (pc_out == `PC_RESET));

endmodule