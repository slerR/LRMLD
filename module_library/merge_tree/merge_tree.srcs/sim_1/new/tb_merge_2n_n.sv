`timescale 1ns / 1ps

module tb_merge_2n_n;

    parameter N = 4;
    parameter MW = 8;
    parameter LW = 4;

    logic clk;
    logic i_valid;
    logic [MW-1:0] i_m0 [N];
    logic [LW-1:0] i_l0 [N];
    logic [MW-1:0] i_m1 [N];
    logic [LW-1:0] i_l1 [N];
    logic [MW-1:0] o_m  [N];
    logic [LW-1:0] o_l  [N];
    logic o_valid;

    // Тактовый сигнал
    initial clk = 0;
    always #5 clk = ~clk;

    // Экземпляр модуля
    merge_2n_n #(
        .N_INPUTS(N),
        .METRIC_W(MW),
        .LABEL_W(LW),
        .FF_P(3'b111) // Включаем регистры на всех слоях (их log2(2*N) = 3)
    ) dut (
        .clk(clk),
        .i_valid(i_valid),
        .i_m0(i_m0), .i_l0(i_l0),
        .i_m1(i_m1), .i_l1(i_l1),
        .o_m(o_m),   .o_l(o_l)
    );

    initial begin
        @(posedge clk);
        i_valid <= 1;
        i_m0    <= '{8'd10, 8'd20, 8'd30, 8'd40};
        i_l0    <= '{4'd1,  4'd2,  4'd3,  4'd4};
        
        i_m1 <= '{8'd15, 8'd25, 8'd35, 8'd45};
        i_l1 <= '{4'd5,  4'd6,  4'd7,  4'd8};
        
        @(posedge clk);
        i_valid <= 1;
        i_m0    <= '{8'd1, 8'd2, 8'd30, 8'd40};
        i_l0    <= '{4'd1,  4'd2,  4'd3,  4'd4};
        
        i_m1 <= '{8'd15, 8'd25, 8'd35, 8'd45};
        i_l1 <= '{4'd5,  4'd6,  4'd7,  4'd8};
        
        @(posedge clk);
        i_valid <= 0;

        repeat(20) @(posedge clk);
        $finish;
    end

endmodule