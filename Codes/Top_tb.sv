`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.08.2025 12:06:40
// Design Name: 
// Module Name: Top_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Top_tb;

    // Clock and reset
    logic clk, rst;

    // Floor selection
    logic [3:0] floor_sel_in;

    // Floor buttons/outputs
    logic up_gnd_in, out_gnd;
    logic up_one_in, down_one_in, out_one;
    logic up_two_in, down_two_in, out_two;
    logic down_three_in, out_three;

    // Instantiate the DUT
    Top uut (
        .clk(clk),
        .rst(rst),
        .floor_sel_in(floor_sel_in),
        .up_gnd_in(up_gnd_in),
        .out_gnd(out_gnd),
        .up_one_in(up_one_in),
        .down_one_in(down_one_in),
        .out_one(out_one),
        .up_two_in(up_two_in),
        .down_two_in(down_two_in),
        .out_two(out_two),
        .down_three_in(down_three_in),
        .out_three(out_three)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 10 ns period

    // Test sequence
    initial begin
        // Reset
        rst = 1;
        floor_sel_in = 4'b0;
        up_gnd_in = 0; up_one_in = 0; down_one_in = 0;
        up_two_in = 0; down_two_in = 0; down_three_in = 0;
        #12;
        rst = 0;

        // Test 1: Request ground ? second floor
        $display("Test 1: Ground ? Second Floor");
        up_gnd_in = 1;
        floor_sel_in = 4'b0100; // Floor 2 requested
        #20;
        up_gnd_in = 0;
        floor_sel_in = 4'b0;
        #50;

        // Test 2: Request first ? ground floor
        $display("Test 2: First ? Ground Floor");
        up_one_in = 0; down_one_in = 1;  // Down button pressed on first
        floor_sel_in = 4'b0001;           // Ground requested
        #20;
        up_one_in = 0; down_one_in = 0;
        floor_sel_in = 4'b0;
        #50;

        // Test 3: Multiple requests
        $display("Test 3: Multiple requests");
        up_two_in = 1;                    // Up button on second floor
        down_three_in = 1;                // Down button on third floor
        #10;
        floor_sel_in = 4'b1000;           // Floors 1 and 3 requested
        #10
        up_two_in = 0; down_three_in = 0;
        floor_sel_in = 4'b0;
        #100;

        $display("Simulation finished.");
        $stop;
    end

    // Monitor outputs
    initial begin
        $monitor("Time=%0t | out_gnd=%b out_one=%b out_two=%b out_three=%b", 
                 $time, out_gnd, out_one, out_two, out_three);
    end

endmodule

