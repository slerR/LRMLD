`timescale 1ns / 1ps

module tb_sum_select_16;
    parameter M_W = 10;
    parameter L_W = 6;
    parameter L_W1 = 6;

    logic clk;
    logic i_valid;
    logic [16*M_W-1 : 0] i_metrics,  i_metrics1;
    logic [16*L_W-1 : 0] i_labels;
    logic [16*L_W1-1 : 0] i_labels1;
    
    logic [M_W-1 : 0] o_metrics [0 : 15];
    logic [(L_W+L_W1)-1 : 0] o_labels [0 : 15];
    logic o_valid;

    sum_select_16_bm_ir #(
        .METRIC_W(M_W),
        .LABEL_W(L_W),
        .LABEL_W1(L_W1)
    ) dut (.*);

    always #5 clk = (clk === 1'b0);

    initial begin
        // Инициализация
        clk = 0;
        i_valid = 0;
        repeat(2) @(posedge clk);
        i_valid <= 1;
        for (int i = 0; i < 16; i++) begin
            // Заполняем i_metrics значениями 10, 20, 30...
            i_metrics[16*M_W - 1 - i*M_W -: M_W]   <= (i + 1) * 10;
            // Заполняем i_metrics1 значениями 5, 15, 25...
            i_metrics1[16*M_W - 1 - i*M_W -: M_W]  <= i * 10 + 5;
            
           
            i_labels [   16*L_W - 1 - i*L_W -: L_W] <= i;
            i_labels1[16*L_W1 - 1 - i*L_W1 -: L_W1] <= i + 1;
        end

        @(posedge clk);
        i_valid <= 0; 
        repeat(20) @(posedge clk);
        $finish;
    end

endmodule