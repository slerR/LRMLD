`timescale 1ns / 1ps

module tb_bitonic_merge_4_4_ir;

    parameter M_W = 10;
    parameter L_W = 16;

    logic clk;
    logic [M_W-1:0] i_m1 [0:3], i_m2 [0:3];
    logic [L_W-1:0] i_l1 [0:3], i_l2 [0:3];
    logic [M_W-1:0] o_m  [0:7];
    logic [L_W-1:0] o_l  [0:7];

    bitonic_merge_4_4_ir #(M_W, L_W) dut (.*);

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        
        @(posedge clk);
        for (int i = 0; i < 4; i++) begin
            i_m1[i] <= (i + 1) * 10;
            i_l1[i] <= i;
            i_m2[i] <= (i + 1) * 12;
            i_l2[i] <= i + 4;
        end

        @(posedge clk);
        
        for (int i = 0; i < 4; i++) begin
            i_m1[i] <= i_m1[i] + 5;
            i_m2[i] <= i_m2[i] + 5;
            
            i_l1[i] <= i+1;
            i_l2[i] <= i + 2;
        end

        repeat(5) @(posedge clk);
        
        $display("Sorted Metrics:");
        for (int i = 0; i < 8; i++) $write("%0d ", o_m[i]);
        $display("\nCorresponding Labels:");
        for (int i = 0; i < 8; i++) $write("%0d ", o_l[i]);
        $display("\n");
        
        $finish;
    end

endmodule