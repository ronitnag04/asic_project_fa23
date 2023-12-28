//  Module: MWControlTestbench
//  Desc:   Testbench for MWControl
//  Duts:
//      1)  MWControl

`timescale 1ns / 1ps
`define PROP_DELAY (`CLOCK_PERIOD / 5.0)
`define NUM_TESTCASES 197
`define SIZE_TESTVECTOR 26

module MWControlTestbench();
    reg clk;

    // Clock Signal generation:
    initial clk = 1'b0; 
    always #(`CLOCK_PERIOD*0.5) clk = ~clk;

    // These are read from the input vector
    // Inputs
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [11:0] csr;

    // REF Outputs
    wire [1:0] REF_wb_sel;
    wire REF_rwe;
    wire REF_csr_we;

    // DUT Outputs
    wire [1:0] DUT_wb_sel;
    wire DUT_rwe;
    wire DUT_csr_we;

    // Task for checking output
    task displayValues;
        $display("\topcode: 0b%b, funct3: 0b%b", opcode, funct3);
        $display("\tDUT_wb_sel: %b, REF_wb_sel: %b, DUT_rwe: %b, REF_rwe: %b", DUT_wb_sel, REF_wb_sel, DUT_rwe, REF_rwe);
        $display("\tDUT_csr_we: %b, REF_csr_we: %b", DUT_csr_we, REF_csr_we);
    endtask

    task checkOutput;
        input integer test_num;

        $display("Test %0d", test_num);
        if (  (REF_wb_sel !== DUT_wb_sel) || (REF_rwe != DUT_rwe) ||
              (REF_csr_we != DUT_csr_we)) begin 
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

    MWControl DUT1(
        .opcode(opcode),
        .funct3(funct3),
        .csr(csr),

        .wb_sel(DUT_wb_sel),
        .rwe(DUT_rwe),
        .csr_we(DUT_csr_we)
    );

    reg [`SIZE_TESTVECTOR-1:0] testvector [0:`NUM_TESTCASES-1];
    // [6:0] opcode, [9:7] funct3, [21:10] csr
    // [23:22] REF_wb_sel, [24] REF_rwe, [25] REF_csr_we

    reg [`SIZE_TESTVECTOR-1:0] cur_testvector;
    assign opcode = cur_testvector[6:0];
    assign funct3 = cur_testvector[9:7];
    assign csr = cur_testvector[21:10];
    assign REF_wb_sel = cur_testvector[23:22];
    assign REF_rwe = cur_testvector[24];
    assign REF_csr_we = cur_testvector[25];

    integer i; // integer used for looping in non-generate statement

    initial 
    begin
        $vcdpluson;
        $readmemb("../../tests/stage3/MWControltestvectors.input", testvector);
        for (i = 0; i < `NUM_TESTCASES; i = i + 1) begin
            if (testvector[i] == {`SIZE_TESTVECTOR{1'bx}}) begin      // 'x' allowed for wb_sel
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