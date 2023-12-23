//  Module: ComparatorTestbench
//  Desc:   Testbench for Comparator
//  Duts:
//      1)  Comparator

`timescale 1ns / 1ps
`define PROP_DELAY (`CLOCK_PERIOD / 5.0)

module ComparatorTestbench();
    reg clk;

    // Clock Signal generation:
    initial clk = 1'b0; 
    always #(`CLOCK_PERIOD*0.5) clk = ~clk;

    // Wires to test the DUT
    // These are read from the input vector
    // Inputs
    reg [31:0] rs1d, rs2d;
    reg s;

    // REF Outputs
    reg REF_lt, REF_eq; 

    // DUT Outputs
    wire DUT_lt, DUT_eq;

    // Task for checking output
    task checkOutput;
        input integer test_num;

        $display("Test %0d", test_num);
        if ( (REF_eq != DUT_eq) || (REF_lt != DUT_lt) ) begin
            $display("FAIL: Incorrect result for rs1d: 0x%h, rs2d: 0x%h, signed: %b", rs1d, rs2d, s);
            $display("\tDUT_eq: 0x%h, REF_eq: 0x%h", DUT_eq, REF_eq);
            $display("\tDUT_lt: 0x%h, REF_lt: 0x%h", DUT_lt, REF_lt);
        $finish();
        end
        else begin
            $display("PASS: rs1d: 0x%h, rs2d: 0x%h, signed: %b", rs1d, rs2d, s);
            $display("\tDUT_eq: 0x%h, REF_eq: 0x%h", DUT_eq, REF_eq);
            $display("\tDUT_lt: 0x%h, REF_lt: 0x%h", DUT_lt, REF_lt);
        end
    endtask

    // This is where the modules being tested are instantiated. 

    Comparator DUT1(
        .rs1d(rs1d),
        .rs2d(rs2d),
        .s(s),

        .eq(DUT_eq),
        .lt(DUT_lt)
    );

    localparam testcases = 112; // TODO: Update number of testcases

    reg [113:0] testvector [0:testcases-1]; // Each testcase has 67 bits
    // [31:0] rs1d, [63:32] rs2d, [64] s
    // [65] REF_lt, [66] REF_eq 

    integer i; // integer used for looping in non-generate statement

    initial 
    begin
        $vcdpluson;
        $readmemb("../../tests/stage2/Comparatortestvectors.input", testvector);
        for (i = 0; i < testcases; i = i + 1) begin
            if (^testvector[i]) $display("Invalid Test %b", testvector[i]);
            
            @(negedge clk);
                rs1d   <= testvector[i][31:0];
                rs2d   <= testvector[i][63:32];
                s      <= testvector[i][64];
                REF_lt <= testvector[i][65];
                REF_eq <= testvector[i][66];

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