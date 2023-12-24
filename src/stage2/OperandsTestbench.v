//  Module: OperandsTestbench
//  Desc:   Testbench for Operands
//  Duts:
//      1)  Operands

`timescale 1ns / 1ps
`define PROP_DELAY (`CLOCK_PERIOD / 5.0)
`define NUM_TESTCASES 420
`define SIZE_TESTVECTOR 247

module OperandsTestbench();
    reg clk;

    // Clock Signal generation:
    initial clk = 1'b0; 
    always #(`CLOCK_PERIOD*0.5) clk = ~clk;

    // Wires to test the DUT
    // These are read from the input vector
    // Inputs
    wire [6:0] opcode;
    wire [4:0] rs1, rs2;

    wire [31:0] pc, rs1d, rs2d, imm;

    wire [4:0] rd_mw; 
    wire rwe_mw;
    wire [31:0] wb_data_mw;

    // REF Outputs
    wire [31:0] REF_A, REF_B;

    // DUT Outputs
    wire [31:0] DUT_A, DUT_B;

    // Task for checking output
    task displayValues;
        $display("\tpc: 0x%h, rs1d: 0x%h, rs2d: 0x%h, imm: 0x%h, wb_data_mw: 0x%h", 
                    pc, rs1d, rs2d, imm, wb_data_mw);
        $display("\trs1: %d, rs2: %d, rd_mw: %d, rwe_mw: %d", rs1, rs2, rd_mw, rwe_mw);
        $display("\tDUT_A: 0x%h, REF_A: 0x%h", DUT_A, REF_A);
        $display("\tDUT_B: 0x%h, REF_B: 0x%h", DUT_B, REF_B);
    endtask

    task checkOutput;
        input integer test_num;

        $display("Test %0d", test_num);
        if (  (REF_A != DUT_A) || (REF_B != DUT_B)  ) begin
            $display("FAIL: Incorrect result for opcode: %b", opcode);
            displayValues();
            $finish();
        end
        else begin
            $display("PASS:  opcode: %b", opcode);
            displayValues();
        end
    endtask

    // This is where the modules being tested are instantiated. 

    Operands DUT1(
        .opcode(opcode),
        .rs1(rs1),
        .rs2(rs2),
        .pc(pc),
        .rs1d(rs1d),
        .rs2d(rs2d),
        .imm(imm),

        .rd_mw(rd_mw),  
        .rwe_mw(rwe_mw),
        .wb_data_mw(wb_data_mw),
    
        .A(DUT_A),
        .B(DUT_B)
    );

    reg [`SIZE_TESTVECTOR-1:0] testvector [0:`NUM_TESTCASES-1];
    // [6:0] opcode, [11:7] rs1, [16:12] rs2
    // [48:17] pc, [80:49] rs1d, [112:81] rs2d, [144:113] imm, [176:145] wd_data_mw
    // [181:177] rd_mw, [182] rwe_mw
    // [214:183] REF_A, [246:215] REF_B

    reg [`SIZE_TESTVECTOR-1:0] cur_testvector;
    assign opcode =     cur_testvector[6:0];
    assign rs1 =        cur_testvector[11:7];
    assign rs2 =        cur_testvector[16:12];
    assign pc =         cur_testvector[48:17];
    assign rs1d =       cur_testvector[80:49];
    assign rs2d =       cur_testvector[112:81];
    assign imm =        cur_testvector[144:113];
    assign wb_data_mw = cur_testvector[176:145];
    assign rd_mw =      cur_testvector[181:177];
    assign rwe_mw =     cur_testvector[182];
    assign REF_A =      cur_testvector[214:183];
    assign REF_B =      cur_testvector[246:215];

    integer i; // integer used for looping in non-generate statement

    initial 
    begin
        $vcdpluson;
        $readmemb("../../tests/stage2/Operandstestvectors.input", testvector);
        for (i = 0; i < `NUM_TESTCASES; i = i + 1) begin
            if (^testvector[i] === 1'bx) begin
                $display("Invalid Test %b", testvector[i]);
                $vcdplusoff;
                $finish();
            end

            @(negedge clk);
            cur_testvector <= testvector[i];
            #(`PROP_DELAY);
            checkOutput(i);
        end

        // Manual Tests

        $display("\n\nALL TESTS PASSED!");
        $vcdplusoff;
        $finish();
    end

endmodule