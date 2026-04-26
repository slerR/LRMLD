`timescale 1ns / 1ps

module tb_bitonic_merge_8_8;

    parameter M_W = 10;
    parameter L_W = 16;

    logic clk;
    logic [M_W-1:0] i_m1 [0:7], i_m2 [0:7];
    logic [L_W-1:0] i_l1 [0:7], i_l2 [0:7];
    logic [M_W-1:0] o_m  [0:15];
    logic [L_W-1:0] o_l  [0:15];

    bitonic_merge_8_8_comb #(M_W, L_W) dut (.*);

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        @(posedge clk);
        // Заполнение тестовыми данными (два отсортированных списка)
        for (int i = 0; i < 8; i++) begin
            i_m1[i] <= (i + 1) * 10;   // 10, 20, 30... 80
            i_l1[i] <= i;              // Метки 0-7
                    
            i_m2[i] <= (i + 1) * 12;   // 12, 24, 36... 96
            i_l2[i] <= i + 8;          // Метки 8-15
        end

        @(posedge clk);
        // Можно подать вторую пачку данных на следующем такте
        for (int i = 0; i < 8; i++) begin
            i_m1[i] <= i_m1[i] + 5;
            i_m2[i] <= i_m2[i] + 5;
        end

        repeat(5) @(posedge clk);
        
        $display("Sorted Metrics:");
        for (int i = 0; i < 16; i++) $write("%0d ", o_m[i]);
        $display("\nCorresponding Labels:");
        for (int i = 0; i < 16; i++) $write("%0d ", o_l[i]);
        $display("\n");
        
        $finish;
    end

endmodule