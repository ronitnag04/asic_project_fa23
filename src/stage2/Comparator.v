// Module: Comparator.v
// Desc: Signed/Unsigned comparator for Branch Conditions
// Inputs: 
//      rs1d: 32-Bit data for rs1
//      rs2d: 32-Bit data for rs2
//      s: Perform signed comparison if 1 else unsigned comparison
// 
// Outputs: 
//      eq: Equal
//      lt: Less Than


module Comparator (
    input [31:0] rs1d,
    input [31:0] rs2d,
    input s,

    output eq,
    output lt
);

assign eq = (rs1d == rs2d) ? 1'b1 : 1'b0;
wire [31:0] comp_rs1d, comp_rs2d;
assign comp_rs1d = (s == 1'b1) ? $signed(rs1d) : $unsigned(rs1d);
assign comp_rs2d = (s == 1'b1) ? $signed(rs2d) : $unsigned(rs2d);
assign lt = (comp_rs1d < comp_rs2d) ? 1'b1 : 1'b0;

endmodule