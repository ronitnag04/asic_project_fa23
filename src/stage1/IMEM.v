// Module: IMEM.v
// Desc: Interface for Instruction Memory
// Inputs: 
//    Must be valid after posedge clk
//      pc: 32-bit Program Counter
//      
//    Must be valid after posedge clk + memory access
//      dout: 32-bit Read Data from Memory151 IMEM
//
//      clk: Clock line
//      stall: Stall line
//      reset: Reset line
// 
// Outputs: 
//    Valid after posedge clk
//      addr: 32-bit Memory151 IMEM address
//      re  : Read Enable for IMEM
//
//    Valid after posedge clk + memory access
//      inst: 32-bit instruction to be used for 


module IMEM (
    input [31:0] pc,
    input clk,
    input stall,
    input reset,

    output [31:0] addr,
    output reg re,

    input [31:0] dout,
    
    output [31:0] inst
);

assign addr = pc;
assign inst = dout;

always @(*) begin
    if (reset == 1'b1) begin
        re <= 1'b0;
    end else if (stall == 1'b0) begin
        if (clk == 1'b1) re <= 1'b1;
        else re <= 1'b0;
    end
end

endmodule