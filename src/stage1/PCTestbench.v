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
    reg [31:0] ALU_Out, REF_PC_Out;
    reg reset, stall, PC_Sel;

    wire [31:0] DUT_PC_Out; 


    // Task for checking output
    task checkOutput;
        input [31:0] ALU_Out;
        input [31:0] REF_PC_Out;
        input PC_Sel;
        input reset;
        input stall;
        input integer test_num;
        if ( REF_PC_Out !== DUT_PC_Out ) begin
            $display("Test %0d", test_num);
            $display("FAIL: Incorrect result for PC_Sel %b, reset: %b, stall: %b, ALU_Out: 0x%h", PC_Sel, reset, stall, ALU_Out);
            $display("\tDUT_PC_Out: 0x%h, REF_PC_Out: 0x%h", DUT_PC_Out, REF_PC_Out);
        $finish();
        end
        else begin
            $display("Test %0d", test_num);
            $display("PASS: PC_Sel %b, reset: %b, stall: %b, ALU_Out: 0x%h", PC_Sel, reset, stall, ALU_Out);
            $display("\tDUT_PC_Out: 0x%h, REF_PC_Out: 0x%h", DUT_PC_Out, REF_PC_Out);
        end
    endtask


    // This is where the modules being tested are instantiated. 

    PC DUT1(
        .ALU_Out(ALU_Out),
        .clk(Clock),
        .reset(reset),
        .stall(stall),
        .PC_Sel(PC_Sel),

        .PC_Out(DUT_PC_Out)       
    );

    /////////////////////////////////////////////////////////////////
    // Change this number to reflect the number of testcases in your
    // testvector input file, which you can find with the command:
    // % wc -l ../sim/tests/testvectors.input
    // //////////////////////////////////////////////////////////////
    localparam testcases = 104;

    reg [66:0] testvector [0:testcases-1]; // Each testcase has 67 bits:
    // [31:0] ALU_Out, [63:32] REF_PC_Out
    // [64] PC_Sel, [65] reset, [66] stall, 

    integer i; // integer used for looping in non-generate statement

    initial 
    begin
        $vcdpluson;
        $readmemb("../../tests/stage1/PCtestvectors.input", testvector);
        for (i = 0; i < testcases; i = i + 1) begin
            @(negedge Clock);
            ALU_Out <= testvector[i][31:0];
            REF_PC_Out <= testvector[i][63:32];
            PC_Sel <= testvector[i][64];
            reset <= testvector[i][65];
            stall <= testvector[i][66];

            @(posedge Clock);
            #1;
            checkOutput(ALU_Out, REF_PC_Out, PC_Sel, reset, stall, i);
        end
        $display("\n\nALL TESTS PASSED!");
        $vcdplusoff;
        $finish();
    end

endmodule
