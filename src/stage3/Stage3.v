// Module: Stage3.v
// Desc: Stage 3 High Level Module  
// Inputs: 
//    Must be valid before posedge clk
//      alu_out: 32-bit ALU calculation from Transfer_2_3
//      dout: 32-bit memory load data Transfer_2_3
//      inst: 32-bit sintruction from Transfer_2_3
//      pc: 32-bit Program Counter
//      jump: jump signal
//      
// Outputs:
//    Valid before posedge clk
//      wb_data: 32-bit writeback data
//      pc_sel: Program Counter select input to Stage 1
//      rwe: Register Write Enable to Stage 1
//      csr_we: CSR Write Enable

`include "stage3/WControl.vh"
`include "Opcode.vh"

module Stage3 (
    input [31:0] pc,            
    input [31:0] alu_out,       
    input [31:0] dout,          
    input [31:0] inst,          
    input jump,          

    output [31:0] wb_data,      
    output pc_sel,              
    output rwe,
    output csr_we                 
);

assign pc_sel = jump;       // Select next PC to by ALU if jump signal is 1

wire [31:0] pc_4;
assign pc_4 = pc + 4;
wire [1:0] wb_sel;

assign wb_data = (wb_sel == `SEL_PC4) ? pc_4    :
                 (wb_sel == `SEL_ALU) ? alu_out :
                 (wb_sel == `SEL_MEM) ? dout    :         
                 32'bx;


WControl WControl(
    .opcode(inst[6:0]),
    .funct3(inst[14:12]),
    .csr(inst[31:20]),

    .wb_sel(wb_sel),
    .rwe(rwe),
    .csr_we(csr_we) 
);

endmodule