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
assign lt = (s == 1'b1) ?
                (($signed(rs1d) < $signed(rs2d)) ? 1'b1 : 1'b0) :
                ((rs1d < rs2d) ? 1'b1 : 1'b0);

endmodule