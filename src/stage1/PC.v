// Module: PC.v
// Desc:   PC unit module
// Inputs: 
//    ALU_Out: 32-bit value from ALU_Out in stage2
//    clk: Clock line
//    reset: Reset line
//
//    stall: Stall counter
//    PC_Sel: Select next PC
// 						
// Outputs:
//    PC_Out: 32-bit PC value for current state

module PC (
    input [31:0] ALU_Out,
    input clk,
    input reset,
    input stall,
    input PC_Sel,

    output [31:0] PC_Out
);

wire [31:0] PC_4, PC_Mux_Out;
assign PC_4 = PC_Out + 4;

PC_Reg PCREG (
    .PC_In(PC_Mux_Out),
    .clk(clk),
    .reset(reset),
    .stall(stall),

    .PC_Out(PC_Out)
); 

PC_Mux PCMUX (
    .PC_4(PC_4), 
    .ALU_Out(ALU_Out),
    .PC_Sel(PC_Sel),

    .PC_Mux_Out(PC_Mux_Out)
);

endmodule