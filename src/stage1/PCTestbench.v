//  Module: PCTestbench
//  Desc:   Vector Testbench for PC (Program Counter)
//  Duts:
//      1)  PC

`timescale 1ns / 1ps
`include "stage1/stage1_control.vh"

module PCTestbench();

    parameter Halfcycle = 5; //half period is 5ns

    localparam Cycle = 2*Halfcycle;

    reg Clock;

    // Clock Signal generation:
    initial Clock = 0; 
    always #(Halfcycle) Clock = ~Clock;

    // Wires to test the PC Dut
    // These are read from the input vector
    reg [31:0] alu_out, REF_pc_out;
    reg reset, stall, pc_sel;

    wire [31:0] DUT_pc_out; 


    // Task for checking output
    task checkOutput;
        input [31:0] alu_out;
        input [31:0] REF_pc_out;
        input pc_sel;
        input reset;
        input stall;
        input integer test_num;
        if ( REF_pc_out !== DUT_pc_out ) begin
            $display("Test %0d", test_num);
            $display("FAIL: Incorrect result for pc_sel %b, reset: %b, stall: %b, alu_out: 0x%h", pc_sel, reset, stall, alu_out);
            $display("\tDUT_pc_out: 0x%h, REF_pc_out: 0x%h", DUT_pc_out, REF_pc_out);
        $finish();
        end
        else begin
            $display("Test %0d", test_num);
            $display("PASS: pc_sel %b, reset: %b, stall: %b, alu_out: 0x%h", pc_sel, reset, stall, alu_out);
            $display("\tDUT_pc_out: 0x%h, REF_pc_out: 0x%h", DUT_pc_out, REF_pc_out);
        end
    endtask


    // This is where the modules being tested are instantiated. 

    PC DUT1(
        .alu_out(alu_out),
        .clk(Clock),
        .reset(reset),
        .stall(stall),
        .pc_sel(pc_sel),

        .pc_out(DUT_pc_out)       
    );

    /////////////////////////////////////////////////////////////////
    // Change this number to reflect the number of testcases in your
    // testvector input file, which you can find with the command:
    // % wc -l ../sim/tests/testvectors.input
    // //////////////////////////////////////////////////////////////
    localparam testcases = 330;

    reg [66:0] testvector [0:testcases-1]; // Each testcase has 67 bits:
    // [31:0] alu_out, [63:32] REF_pc_out
    // [64] pc_sel, [65] reset, [66] stall, 

    integer i; // integer used for looping in non-generate statement

    initial 
    begin
        $vcdpluson;
        $readmemb("../../tests/stage1/PCtestvectors.input", testvector);
        for (i = 0; i < testcases; i = i + 1) begin
            @(negedge Clock);
            alu_out <= testvector[i][31:0];
            REF_pc_out <= testvector[i][63:32];
            pc_sel <= testvector[i][64];
            reset <= testvector[i][65];
            stall <= testvector[i][66];

            @(posedge Clock);
            #1;
            checkOutput(alu_out, REF_pc_out, pc_sel, reset, stall, i);
        end
        $display("\n\nALL TESTS PASSED!");
        $vcdplusoff;
        $finish();
    end

endmodule
