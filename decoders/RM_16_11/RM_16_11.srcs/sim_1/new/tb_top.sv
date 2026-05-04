`timescale 1ns / 1ps

module tb_top;
    
    parameter LLR_W = 6;
    parameter MLABEL_W = 4;
    parameter METRIC_W = LLR_W + 2;
    parameter L = 2;
    parameter IS_FSM = 0;
    
    logic clk;
    logic i_v;
    logic signed [LLR_W-1:0] i_llr [0:15];
    logic [METRIC_W-1:0] o_m [0:L-1];
    logic [15:0] o_l [0:L-1];
    logic o_v;
    
    top #(
        .LLR_W(LLR_W),
        .L(L),
        .IS_FSM(IS_FSM)
    ) dut (
        .clk(clk),
        .i_v(i_v),
        .i_llr(i_llr),
        .o_m(o_m),
        .o_l(o_l),
        .o_v(o_v)
    );
    
    always #5 clk = ~clk;
    
    initial begin
        clk = 0;
        i_v = 0;
        for (int i = 0; i < 16; i++) i_llr[i] = 0;
    
        repeat(10) @(posedge clk);
    
        @(posedge clk);
        i_v = 1;
        i_llr[0]  = 12;  i_llr[1]  = -10; i_llr[2]  = 5;   i_llr[3]  = -15;
        i_llr[4]  = 8;   i_llr[5]  = -2;  i_llr[6]  = 0;   i_llr[7]  = -20;
        i_llr[8]  = 14;  i_llr[9]  = -7;  i_llr[10] = 3;   i_llr[11] = -11;
        i_llr[12] = 6;   i_llr[13] = -4;  i_llr[14] = 9;   i_llr[15] = -1;
        
        @(posedge clk);
        i_v = 0;
    
        fork
            begin
                wait(o_v);
                repeat(10) @(posedge clk);
                $finish;
            end
            begin
                repeat(1000) @(posedge clk);
                $display("Timeout");
                $finish;
            end
        join
    end
endmodule