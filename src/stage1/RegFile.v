// Module: RegFile.v
// Desc:   Register File with 32 32-bit registers
// Inputs: 
//    rs1: 5-bit index for rs1d (rs1 data)
//    rs2: 5-bit index for rs2d (rs2 data)
//    rd:  5-bit index for wb_data (Writeback data), from Stage 3
//    wb_data: 32-bit data to write to rd
//    we: Write Enable (1 is write, 0 is no write)
//        NOTE: Write occurs on rising edge of clock
//    stall: Stall operation (1 is stall, 0 is continue)
// 
//    clk: Clock line
//    rst: Synchronous Reset line, sets all registers to 0
// 						
// Outputs:
//    rs1d: 32-bit rs1 data
//    rs2d: 32-bit rs2 data
//          NOTE: Read Data is invalid until falling edge of clock


module RegFile (
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,
    input [31:0] wb_data,
    input we,
    input stall,
    input clk,
    input reset,

    output [31:0] rs1d,
    output [31:0] rs2d
);

reg [31:0] regfile [31:1];
wire [31:0] reg0;
assign reg0 = 32'b0;

assign rs1d = (rd == 5'b0) ? reg0 : regfile[rs1];
assign rs2d = (rd == 5'b0) ? reg0 : regfile[rs2];

always @(posedge clk) begin
    if (reset == 1'b1) begin
        foreach (regfile[i])
            regfile[i] <= 32'b0;
    end else if (stall != 1'b1) begin
        if ((we == 1'b1) && (rd != 5'b0)) begin
            regfile[rd] <= wb_data;
        end
    end
end

reg0_always_0 : assert property (@(posedge clk) (reg0 == 32'b0));

endmodule