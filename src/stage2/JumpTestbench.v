//  Module: JumpTestbench
//  Desc:   Testbench for Jump
//  Duts:
//      1)  Jump

`timescale 1ns / 1ps
`define PROP_DELAY (`CLOCK_PERIOD / 5.0)
`define NUM_TESTCASES 156
`define SIZE_TESTVECTOR 14

module JumpTestbench();
    reg clk;

    // Clock Signal generation:
    initial clk = 1'b0; 
    always #(`CLOCK_PERIOD*0.5) clk = ~clk;

    // TODO: Wires to test the DUT
    // These are read from the input vector
    // Inputs
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire lt, eq;
    // REF Outputs
    wire REF_s, REF_jump;
    // DUT Outputs
    wire DUT_s, DUT_jump;

    // Task for checking output
    task displayValues;
        $display("\topcode: 0b%b, funct3: 0b%b, lt: %d, eq: %d", opcode, funct3, lt, eq);
        $display("\tDUT_s: %b, REF_s: %b", DUT_s, REF_s);
        $display("\tDUT_jump: %b, REF_jump: %b", DUT_jump, REF_jump);
    endtask

    task checkOutput;
        input integer test_num;

        $display("Test %0d", test_num);
        if (  (REF_s != DUT_s) || (REF_jump != DUT_jump)  ) begin 
            $display("FAIL: Incorrect result");
            displayValues();
            $finish();
        end
        else begin
            $display("PASS:");
            displayValues();
        end
    endtask

    // This is where the modules being tested are instantiated. 

    // TODO: Update DUT Connections
    Jump DUT1(
        .opcode(opcode),
        .funct3(funct3),
        .s(DUT_s),
        .lt(lt),
        .eq(eq),
        .jump(DUT_jump)
    );

    reg [`SIZE_TESTVECTOR-1:0] testvector [0:`NUM_TESTCASES-1];
    // [6:0] opcode, [9:7] funct3, [10] REF_s
    // [11] lt, [12] eq, [13] REF_jump

    reg [`SIZE_TESTVECTOR-1:0] cur_testvector;
    assign opcode = cur_testvector[6:0];
    assign funct3 = cur_testvector[9:7];
    assign REF_s = cur_testvector[10];
    assign lt = cur_testvector[11];
    assign eq = cur_testvector[12];
    assign REF_jump = cur_testvector[13];

    integer i; // integer used for looping in non-generate statement

    initial 
    begin
        $vcdpluson;
        $readmemb("../../tests/stage2/Jumptestvectors.input", testvector);
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