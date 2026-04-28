`timescale 1ns / 1ps

module tb_sum_select_16;
    parameter M_W = 10;
    parameter L_W = 6;
    parameter L_W1 = 6;

    logic                clk;
    logic                i_valid;
    logic [ 8*M_W-1 : 0] i_metrics,  i_metrics1;
    logic [ 8*L_W-1 : 0] i_labels;
    logic [8*L_W1-1 : 0] i_labels1;
    
    logic [       M_W-1 : 0] o_metrics [0 : 7];
    logic [(L_W+L_W1)-1 : 0] o_labels  [0 : 7];
    logic o_valid;

    sum_select8 #(
        .METRIC_W(M_W),
        .LABEL_W(L_W),
        .LABEL_W1(L_W1)
    ) dut (.*);

    always #5 clk = (clk === 1'b0);

    initial begin
        clk = 0;
        i_valid = 0;
        repeat(2) @(posedge clk);
        i_valid <= 1;
        for (int i = 0; i < 16; i++) begin
            i_metrics [8*M_W - 1 - i*M_W -: M_W]   <= (i + 1) * 10;
            i_metrics1[8*M_W - 1 - i*M_W -: M_W]  <= i * 10 + 5;
            
           
            i_labels [   8*L_W - 1 - i*L_W -: L_W] <= i;
            i_labels1[8*L_W1 - 1 - i*L_W1 -: L_W1] <= i + 1;
        end

        @(posedge clk);
         for (int i = 0; i < 16; i++) begin
            i_metrics [8*M_W - 1 - i*M_W -: M_W]   <= (i + 2) * 5;
            i_metrics1[8*M_W - 1 - i*M_W -: M_W]  <= i * 10 + 1;
            
           
            i_labels [   8*L_W - 1 - i*L_W -: L_W] <= i;
            i_labels1[8*L_W1 - 1 - i*L_W1 -: L_W1] <= i + 2;
        end
        
        @(posedge clk);
        i_valid <= 0; 
        repeat(20) @(posedge clk);
        $finish;
    end

endmodule