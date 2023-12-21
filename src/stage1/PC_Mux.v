// Module: PC_Mux.v
// Desc:   Mux for next PC value
// Inputs: 
//    PC_4: 32-bit Previous PC + 4;
//    ALU_Out: 32-bit Value from ALU in Stage 2
//    PC_Sel: Select line
// 						
// Outputs:
//    PC_Mux_Out: 32-bit PC value for next state to connect to PC_In

`include "stage1/stage1_control.vh"

module PC_Mux(
    input [31:0] PC_4, ALU_Out,
    input PC_Sel,

    output reg [31:0] PC_Mux_Out
);

always @(*) begin
    PC_Mux_Out <= (PC_Sel == `PC_SEL_PC_4) ? PC_4 : ALU_Out;
end

endmodule
