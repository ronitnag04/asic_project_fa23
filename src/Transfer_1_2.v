// Module: Transfer_1_2.v
// Desc: Pipeline Transfer Register for Stage 1/I to Stage 2/X
//       Inputs from Stage 1/I are latched on falling edge of clock if not stalled
// Inputs: 
//      clk: Clock line
//      stall: Stall line, new data will not be latched in stall is not 0
//      reset: Reset line, populates inst with NOP
//
//      pc_in: 32-Bit Program Counter
//      rs1d_in: 32-Bit rs1 data from RegFile
//      rs2d_in: 32-Bit rs2 data from RegFile
//      imm_in: 32-Bit Immediate generated from ImmGen
//      inst_in: 32-Bit Instruction (after flushing check)
// 
// Outputs: 
//      pc_out: 32-Bit Program Counter
//      rs1d_out: 32-Bit rs1 data from RegFile
//      rs2d_out: 32-Bit rs2 data from RegFile
//      imm_out: 32-Bit Immediate generated from ImmGen
//      inst_out: 32-Bit Instruction (after flushing check)   

`include "const.vh"

module Transfer_1_2 (
    input clk,
    input stall,
    input reset,

    input [31:0] pc_in,
    input [31:0] rs1d_in,
    input [31:0] rs2d_in,
    input [31:0] imm_in,
    input [31:0] inst_in,

    output reg [31:0] pc_out,
    output reg [31:0] rs1d_out,
    output reg [31:0] rs2d_out,
    output reg [31:0] imm_out,
    output reg [31:0] inst_out
);

always @(negedge clk) begin
    if (reset == 1'b1) begin
        pc_out <= 32'b0;
        rs1d_out <= 32'b0;
        rs2d_out <= 32'b0;
        imm_out <= 32'b0;
        inst_out <= { {25{1'b0}}, `INSTR_NOP};
    end else if (stall == 1'b0) begin
        pc_out <= pc_in;
        rs1d_out <= rs1d_in;
        rs2d_out <= rs2d_in;
        imm_out <= imm_in;
        inst_out <= inst_in;
    end
end

endmodule