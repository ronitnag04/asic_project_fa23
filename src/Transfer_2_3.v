// Module: Transfer_2_3.v
// Desc: Pipeline Transfer Register for Stage 2/X to Stage 3/MW
//       Inputs from Stage 2/X are latched on falling edge of clock if not stalled
// Inputs: 
//      clk: Clock line
//      stall: Stall line, new data will not be latched in stall is not 0
//      reset: Reset line, populates inst with NOP
//      
//      pc_in: 32-Bit Program Counter
//      alu_out_in: 32-Bit calculation from ALU
//      rs2d_in: 32-Bit rs2 data cleaned for potential writeback data hazard
//      jump_in: jump signal from Jump and Comparator
//      inst_in: 32-Bit Instruction 
// 
// Outputs: 
//      pc_out: 32-Bit Program Counter
//      alu_out_out: 32-Bit calculation from ALU
//      rs2d_out: 32-Bit rs2 data cleaned for potential writeback data hazard
//      jump_out: jump signal from Jump and Comparator
//      inst_out: 32-Bit Instruction 


module Transfer_2_3 (
    input clk,
    input stall,
    input reset,

    input [31:0] pc_in,
    input [31:0] alu_out_in,
    input [31:0] rs2d_in,
    input jump_in,
    input [31:0] inst_in,

    output reg [31:0] pc_out,
    output reg [31:0] alu_out_out,
    output reg [31:0] rs2d_out,
    output reg jump_out,
    output reg [31:0] inst_out 
);

always @(negedge clk) begin
    if (reset == 1'b1) begin
        pc_out <= 32'b0;
        alu_out_out <= 32'b0;
        rs2d_out <= 32'b0;
        jump_out <= 1'b0;
        inst_out <= { {25{1'b0}}, `INSTR_NOP};
    end else if (stall == 1'b0) begin
        pc_out <= pc_in;
        alu_out_out <= alu_out_in;
        rs2d_out <= rs2d_in;
        jump_out <= jump_in;
        inst_out <= inst_in;
    end
end


endmodule