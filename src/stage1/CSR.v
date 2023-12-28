// Module: CSR.v
// Desc: Control Status Register. 
//       Only supports csr=CSR_TOHOST, one register (Stage 3 responsible for determining write enable)
// Inputs: 
//      clk: Clock line
//      reset: Reset line
//      stall: Stall line
//
//      csr_i: 12-bit CSR index
//      csr_we: Write enable to CSR Register from stage 3/MW
//      wb_data: 32-bit write back data
//      
// 
// Outputs: 
//      csrd_tohost: 32-bit csr data

`include "const.vh"

module CSR (
    input clk,
    input reset,
    input stall,

    input [11:0] csr_i,
    input csr_we,
    input [31:0] wb_data,

    output reg [31:0] csrd_tohost    
);

always @(posedge clk) begin
    if (reset == 1'b1) csrd_tohost <= 32'b0;
    else if ((stall == 1'b0) && (csr_we == 1'b1) && (csr_i == `CSR_TOHOST)) csrd_tohost <= wb_data;
end


endmodule