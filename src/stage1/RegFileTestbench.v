//  Module: RegFileTestbench
//  Desc:   Testbench for RegFile (Register File)
//  Duts:
//      1)  RegFile

`timescale 1ns / 1ps

module RegFileTestbench();

    parameter Halfcycle = 5; //half period is 5ns

    localparam Cycle = 2*Halfcycle;

    reg Clock;

    // Clock Signal generation:
    initial Clock = 1'b0; 
    always #(Halfcycle) Clock = ~Clock;

    // Wires to test the ImmGen Dut
    // These are read from the input vector
    reg [4:0] rs1, rs2, rd;
    reg [31:0] wb_data;
    reg we, stall, reset;

    reg [31:0] REF_rs1d, REF_rs2d;

    wire [31:0] DUT_rs1d, DUT_rs2d;


    // Task for checking output
    task checkOutput;
        input integer test_num;

        $display("Test %0d", test_num);
        if ( (REF_rs1d !== DUT_rs1d) || (REF_rs2d !== DUT_rs2d) ) begin
            $display("FAIL: Incorrect result for rs1 %d, rs2 %d, rd %d, wb_data 0x%h, we %b, stall %b, reset %b", 
                     rs1, rs2, rd, wb_data, we, stall, reset);
            $display("\tDUT_rs1d: 0x%h, REF_rs1d: 0x%h", DUT_rs1d, REF_rs1d);
            $display("\tDUT_rs2d: 0x%h, REF_rs2d: 0x%h", DUT_rs2d, REF_rs2d);
        $finish();
        end
        else begin
            $display("PASS: rs1 %d, rs2 %d, rd %d, wb_data 0x%h, we %b, stall %b, reset %b", 
                     rs1, rs2, rd, wb_data, we, stall, reset);
            $display("\tDUT_rs1d: 0x%h, REF_rs1d: 0x%h", DUT_rs1d, REF_rs1d);
            $display("\tDUT_rs2d: 0x%h, REF_rs2d: 0x%h", DUT_rs2d, REF_rs2d);
        end
    endtask


    // This is where the modules being tested are instantiated. 

    RegFile DUT1(
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .wb_data(wb_data),
        .we(we),
        .stall(stall),
        .clk(Clock),
        .reset(reset),

        .rs1d(DUT_rs1d),
        .rs2d(DUT_rs2d)
    );

    /////////////////////////////////////////////////////////////////
    // Change this number to reflect the number of testcases in your
    // testvector input file, which you can find with the command:
    // % wc -l ../sim/tests/testvectors.input
    // //////////////////////////////////////////////////////////////
    localparam testcases = 679;

    reg [113:0] testvector [0:testcases-1]; // Each testcase has 114 bits:
    // [4:0] rs1, [9:5] rs2, [14:10] rd
    // [46:15] wb_data
    // [47] we, [48] stall, [49] reset
    // [81:50] REF_rs1d
    // [113:82] REF_rs2d

    integer i; // integer used for looping in non-generate statement

    initial 
    begin
        $vcdpluson;
        $readmemb("../../tests/stage1/RegFiletestvectors.input", testvector);
        for (i = 0; i < testcases; i = i + 1) begin
            @(negedge Clock);
            rs1      <= testvector[i][4:0];
            rs2      <= testvector[i][9:5];
            rd       <= testvector[i][14:10];
            wb_data  <= testvector[i][46:15];
            we       <= testvector[i][47];
            stall    <= testvector[i][48];
            reset    <= testvector[i][49]; 
            REF_rs1d <= testvector[i][81:50];
            REF_rs2d <= testvector[i][113:82];

            @(posedge Clock);
            #1;
            checkOutput(i);
        end
        $display("\n\nALL TESTS PASSED!");
        $vcdplusoff;
        $finish();
    end

endmodule
