//  Module: CSRTestbench
//  Desc:   Testbench for CSR
//  Duts:
//      1)  CSR

`timescale 1ns / 1ps
`define PROP_DELAY (`CLOCK_PERIOD / 5.0)
`define NUM_TESTCASES 101
`define SIZE_TESTVECTOR 79

module CSRTestbench();
    reg clk;

    // Clock Signal generation:
    initial clk = 1'b0; 
    always #(`CLOCK_PERIOD*0.5) clk = ~clk;

    // These are read from the input vector
    // Inputs
    wire reset;
    wire stall;
    wire [11:0] csr_i;
    wire csr_we;
    wire [31:0] wb_data;

    // REF Outputs
    wire [31:0] REF_csrd;

    // DUT Outputs
    wire [31:0] DUT_csrd_tohost;

    // Task for checking output
    task displayValues;
        $display("\treset: %b, stall: %d, csr_we: %d, csr_i: 0x%h", reset, stall, csr_we, csr_i);
        $display("\twb_data: 0x%h", wb_data);
        $display("\tDUT_csrd: 0x%h, REF_csrd: 0x%h", DUT_csrd_tohost, REF_csrd);
    endtask

    task checkOutput;
        input integer test_num;

        $display("Test %0d", test_num);
        if ( REF_csrd != DUT_csrd_tohost ) begin 
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
    CSR DUT1(
        .clk(clk),
        .reset(reset),
        .stall(stall),

        .csr_i(csr_i),
        .csr_we(csr_we),
        .wb_data(wb_data),

        .csrd_tohost(DUT_csrd_tohost)
    );

    reg [`SIZE_TESTVECTOR-1:0] testvector [0:`NUM_TESTCASES-1];
    // [0] reset, [1] stall, [13:2] csr_i, [14] csr_we, [46:15] wb_data
    // [78:47] REF_csrd

    reg [`SIZE_TESTVECTOR-1:0] cur_testvector;
    assign reset = cur_testvector[0];
    assign stall = cur_testvector[1];
    assign csr_i = cur_testvector[13:2];
    assign csr_we = cur_testvector[14];
    assign wb_data = cur_testvector[46:15];
    assign REF_csrd = cur_testvector[78:47];

    integer i; // integer used for looping in non-generate statement

    initial 
    begin
        $vcdpluson;
        $readmemb("../../tests/stage1/CSRtestvectors.input", testvector);
        for (i = 0; i < `NUM_TESTCASES; i = i + 1) begin
            if (^testvector[i] === 1'bx) begin
                $display("Invalid Test %b", testvector[i]);
                $vcdplusoff;
                $finish();
            end

            @(negedge clk);
            cur_testvector <= testvector[i];
            @(posedge clk);
            #(`PROP_DELAY);
            checkOutput(i);
        end

        // Manual Tests

        $display("\n\nALL TESTS PASSED!");
        $vcdplusoff;
        $finish();
    end

endmodule