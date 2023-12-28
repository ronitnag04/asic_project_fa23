// Module: Stage3.v
// Desc: Stage 3 High Level Module  
// Inputs: 
//    Must be valid before posedge clk
//      alu_out: 32-bit ALU calculation from Transfer_2_3
//      rs2d: 32-bit register data from rs2 from Transfer_2_3
//      inst: 32-bit sintruction from Transfer_2_3
//    
//    Must be valid before posedge clk
//      dcache_dout: 32-bit data memory data
//
//      pc: 32-bit Program Counter
//      jump: jump signal
//      stall: Stall line
//      clk: Clock Line
//      reset: Reset Line
//      
// Outputs:
//    Valid before posedge clk
//      dcache_addr: 32-Bit Data Memory Address
//      dcache_we: 4-bit Data Memroy write mask
//      dcache_re: Data Memory Read Enable
//      dcache_din: 32-Bit Write data to Data Memory
//
//    Valid before posedge clk + memory access
//      wb_data: 32-bit writeback data
//
//      pc_sel: Program Counter select input to Stage 1
//      rwe: Register Write Enable to Stage 1
//      csr_we: CSR Write Enable

`include "stage3/MWControl.vh"
`include "Opcode.vh"

module Stage3 (
    input [31:0] pc,            
    input [31:0] alu_out,       
    input [31:0] rs2d,          
    input [31:0] inst,          
    input jump,                 
    input clk,
    input reset,                  

    input stall,                

    output [31:0] dcache_addr,  
    output [3:0] dcache_we,     
    output dcache_re,           
    output [31:0] dcache_din,       

    input [31:0] dcache_dout,   

    output [31:0] wb_data,      
    output pc_sel,              
    output rwe,
    output csr_we                 
);

assign pc_sel = jump;       // Select next PC to by ALU if jump signal is 1

wire [31:0] dout, pc_4;
assign pc_4 = pc + 4;
wire [1:0] wb_sel;

assign wb_data = (wb_sel == `SEL_PC4) ? pc_4    :
                 (wb_sel == `SEL_ALU) ? alu_out :
                 (wb_sel == `SEL_MEM) ? dout    :         
                 32'bx;

DMEM DMEM(
    .clk(clk),
    .stall(stall),
    .reset(reset),

    .addr(alu_out),
    .din(rs2d),
    .opcode(inst[6:0]),
    .funct3(inst[14:12]),

    .dcache_addr(dcache_addr),
    .dcache_din(dcache_din),
    .dcache_re(dcache_re),
    .dcache_we(dcache_we),

    .dcache_dout(dcache_dout),  

    .dout(dout) 
);

MWControl MWControl(
    .opcode(inst[6:0]),
    .funct3(inst[14:12]),
    .csr(inst[31:20]),

    .wb_sel(wb_sel),
    .rwe(rwe),
    .csr_we(csr_we) 
);

endmodule