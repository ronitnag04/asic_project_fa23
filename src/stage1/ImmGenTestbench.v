//  Module: ImmGenTestbench
//  Desc:   Vector Testbench for ImmGen (Immediate Generator)
//  Duts:
//      1)  ImmGen

`timescale 1ns / 1ps

module ImmGenTestbench();

    parameter Halfcycle = 5; //half period is 5ns

    localparam Cycle = 2*Halfcycle;

    reg Clock;

    // Clock Signal generation:
    initial Clock = 1'b0; 
    always #(Halfcycle) Clock = ~Clock;

    // Wires to test the ImmGen Dut
    // These are read from the input vector
    reg [31:0] inst, REF_Imm;

    wire [31:0] DUT_Imm; 


    // Task for checking output
    task checkOutput;
        input [31:0] inst;
        input [31:0] REF_Imm;
        input integer test_num;
        $display("Test %0d", test_num);
        if ( REF_Imm !== DUT_Imm ) begin
            $display("FAIL: Incorrect result for Instruction: %b", inst);
            $display("\tDUT_Imm: 0x%h, REF_Imm: 0x%h", DUT_Imm, REF_Imm);
        $finish();
        end
        else begin
            $display("PASS: Instruction: %b", inst);
            $display("\tDUT_Imm: 0x%h, REF_Imm: 0x%h", DUT_Imm, REF_Imm);
        end
    endtask


    // This is where the modules being tested are instantiated. 

    ImmGen DUT1(
        .inst(inst),

        .imm(DUT_Imm)       
    );

    /////////////////////////////////////////////////////////////////
    // Change this number to reflect the number of testcases in your
    // testvector input file, which you can find with the command:
    // % wc -l ../sim/tests/testvectors.input
    // //////////////////////////////////////////////////////////////
    localparam testcases = 712;

    reg [63:0] testvector [0:testcases-1]; // Each testcase has 64 bits:
    // [31:0] inst, [63:32] REF_Imm

    integer i; // integer used for looping in non-generate statement

    initial 
    begin
        $vcdpluson;
        $readmemb("../../tests/stage1/ImmGentestvectors.input", testvector);
        for (i = 0; i < testcases; i = i + 1) begin
            @(negedge Clock);
            inst <= testvector[i][31:0];
            REF_Imm <= testvector[i][63:32];

            @(posedge Clock);
            #1;
            checkOutput(inst, REF_Imm, i);
        end
        $display("\n\nALL TESTS PASSED!");
        $vcdplusoff;
        $finish();
    end

endmodule
