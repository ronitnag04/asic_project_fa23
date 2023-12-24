//  Module: OperandsTestbench
//  Desc:   Testbench for Operands
//  Duts:
//      1)  Operands

`timescale 1ns / 1ps
`define PROP_DELAY (`CLOCK_PERIOD / 5.0)
`define NUM_TESTCASES 420
`define SIZE_TESTVECTOR 27

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

    wire [4:0] rd_mw; 
    wire rwe_mw;

    // REF Outputs
    wire REF_sel_rs1d, REF_sel_rs2d, REF_sel_a, REF_sel_b;

    // DUT Outputs
    wire DUT_sel_rs1d, DUT_sel_rs2d, DUT_sel_a, DUT_sel_b;

    // Task for checking output
    task displayValues;
        $display("\trs1: %d, rs2: %d, rd_mw: %d, rwe_mw: %d", rs1, rs2, rd_mw, rwe_mw);
        $display("\tDUT_sel_rs1d: 0b%b, REF_sel_rs1d: 0b%b", DUT_sel_rs1d, REF_sel_rs1d);
        $display("\tDUT_sel_rs2d: 0b%b, REF_sel_rs2d: 0b%b", DUT_sel_rs2d, REF_sel_rs2d);
        $display("\tDUT_sel_a: 0b%b, REF_sel_a: 0b%b", DUT_sel_a, REF_sel_a);
        $display("\tDUT_sel_b: 0b%b, REF_sel_b: 0b%b", DUT_sel_b, REF_sel_b);
    endtask

    task checkOutput;
        input integer test_num;

        $display("Test %0d", test_num);
        if (  (REF_sel_rs1d != DUT_sel_rs1d) || (REF_sel_rs2d != DUT_sel_rs2d) || 
              (REF_sel_a != DUT_sel_a) || (REF_sel_b != DUT_sel_b) ) begin
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

        .rd_mw(rd_mw),  
        .rwe_mw(rwe_mw),
    
        .sel_rs1d(DUT_sel_rs1d),
        .sel_rs2d(DUT_sel_rs2d),
        .sel_a(DUT_sel_a),
        .sel_b(DUT_sel_b)
    );

    reg [`SIZE_TESTVECTOR-1:0] testvector [0:`NUM_TESTCASES-1];
    
    // [6:0] opcode, [11:7] rs1, [16:12] rs2
    // [21:17] rd_mw, [22] rwe_mw
    // [23] REF_sel_rs1d, [24] REF_sel_rs2d
    // [25] REF_sel_a, [26] REF_sel_b

    reg [`SIZE_TESTVECTOR-1:0] cur_testvector;
    assign opcode =       cur_testvector[6:0];
    assign rs1 =          cur_testvector[11:7];
    assign rs2 =          cur_testvector[16:12];
    assign rd_mw =        cur_testvector[21:17];
    assign rwe_mw =       cur_testvector[22];
    assign REF_sel_rs1d = cur_testvector[23];
    assign REF_sel_rs2d = cur_testvector[24];
    assign REF_sel_a    = cur_testvector[25];
    assign REF_sel_b    = cur_testvector[26];

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