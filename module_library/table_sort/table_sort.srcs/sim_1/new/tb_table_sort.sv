`timescale 1ns / 1ps

module tb_table_sort;

    parameter METRIC_W = 10;
    parameter LABEL_W  = 8;
    parameter N_COS    = 8;
    parameter N        = 8;

    logic clk;
    logic i_valid;

    logic [METRIC_W - 1 : 0] i_metrics [0 : N_COS - 1][0 : N - 1];
    logic [ LABEL_W - 1 : 0] i_labels  [0 : N_COS - 1][0 : N - 1];

    logic [METRIC_W - 1 : 0] o_metrics [0 : N_COS - 1][0 : N - 1];
    logic [ LABEL_W - 1 : 0] o_labels  [0 : N_COS - 1][0 : N - 1];

    logic o_valid;

    table_sort #(
        .METRIC_W(METRIC_W),
        .LABEL_W (LABEL_W ),
        .N_COS   (N_COS   ),
        .N       (N       )
    ) dut (
        .clk     (clk     ),
        .i_valid (i_valid ),
        .i_metrics(i_metrics),
        .i_labels (i_labels),
        .o_metrics(o_metrics),
        .o_labels (o_labels),
        .o_valid (o_valid )
    );

    initial begin
        clk = 1'b0;
    end

    always #5 clk = ~clk;

    initial begin
        i_valid = 1'b0;

        for (int i = 0; i < N_COS; i++) begin
            for (int j = 0; j < N; j++) begin
                i_metrics[i][j] = '0;
                i_labels[i][j]  = '0;
            end
        end

        repeat (2) @(posedge clk);

        i_valid <= 1'b1;

        i_metrics[0][0] <= 10'd17; i_labels[0][0] <= 8'd1;
        i_metrics[0][1] <= 10'd4;  i_labels[0][1] <= 8'd2;
        i_metrics[0][2] <= 10'd29; i_labels[0][2] <= 8'd3;
        i_metrics[0][3] <= 10'd11; i_labels[0][3] <= 8'd4;
        i_metrics[0][4] <= 10'd6;  i_labels[0][4] <= 8'd5;
        i_metrics[0][5] <= 10'd23; i_labels[0][5] <= 8'd6;
        i_metrics[0][6] <= 10'd8;  i_labels[0][6] <= 8'd7;
        i_metrics[0][7] <= 10'd15; i_labels[0][7] <= 8'd8;

        i_metrics[1][0] <= 10'd31; i_labels[1][0] <= 8'd9;
        i_metrics[1][1] <= 10'd12; i_labels[1][1] <= 8'd10;
        i_metrics[1][2] <= 10'd7;  i_labels[1][2] <= 8'd11;
        i_metrics[1][3] <= 10'd19; i_labels[1][3] <= 8'd12;
        i_metrics[1][4] <= 10'd2;  i_labels[1][4] <= 8'd13;
        i_metrics[1][5] <= 10'd25; i_labels[1][5] <= 8'd14;
        i_metrics[1][6] <= 10'd14; i_labels[1][6] <= 8'd15;
        i_metrics[1][7] <= 10'd9;  i_labels[1][7] <= 8'd16;

        i_metrics[2][0] <= 10'd3;  i_labels[2][0] <= 8'd17;
        i_metrics[2][1] <= 10'd27; i_labels[2][1] <= 8'd18;
        i_metrics[2][2] <= 10'd10; i_labels[2][2] <= 8'd19;
        i_metrics[2][3] <= 10'd21; i_labels[2][3] <= 8'd20;
        i_metrics[2][4] <= 10'd5;  i_labels[2][4] <= 8'd21;
        i_metrics[2][5] <= 10'd18; i_labels[2][5] <= 8'd22;
        i_metrics[2][6] <= 10'd13; i_labels[2][6] <= 8'd23;
        i_metrics[2][7] <= 10'd1;  i_labels[2][7] <= 8'd24;

        i_metrics[3][0] <= 10'd22; i_labels[3][0] <= 8'd25;
        i_metrics[3][1] <= 10'd8;  i_labels[3][1] <= 8'd26;
        i_metrics[3][2] <= 10'd16; i_labels[3][2] <= 8'd27;
        i_metrics[3][3] <= 10'd6;  i_labels[3][3] <= 8'd28;
        i_metrics[3][4] <= 10'd30; i_labels[3][4] <= 8'd29;
        i_metrics[3][5] <= 10'd24; i_labels[3][5] <= 8'd30;
        i_metrics[3][6] <= 10'd28; i_labels[3][6] <= 8'd31;
        i_metrics[3][7] <= 10'd20; i_labels[3][7] <= 8'd32;

        i_metrics[4][0] <= 10'd41; i_labels[4][0] <= 8'd33;
        i_metrics[4][1] <= 10'd44; i_labels[4][1] <= 8'd34;
        i_metrics[4][2] <= 10'd39; i_labels[4][2] <= 8'd35;
        i_metrics[4][3] <= 10'd36; i_labels[4][3] <= 8'd36;
        i_metrics[4][4] <= 10'd45; i_labels[4][4] <= 8'd37;
        i_metrics[4][5] <= 10'd40; i_labels[4][5] <= 8'd38;
        i_metrics[4][6] <= 10'd42; i_labels[4][6] <= 8'd39;
        i_metrics[4][7] <= 10'd38; i_labels[4][7] <= 8'd40;

        i_metrics[5][0] <= 10'd50; i_labels[5][0] <= 8'd41;
        i_metrics[5][1] <= 10'd47; i_labels[5][1] <= 8'd42;
        i_metrics[5][2] <= 10'd49; i_labels[5][2] <= 8'd43;
        i_metrics[5][3] <= 10'd46; i_labels[5][3] <= 8'd44;
        i_metrics[5][4] <= 10'd48; i_labels[5][4] <= 8'd45;
        i_metrics[5][5] <= 10'd51; i_labels[5][5] <= 8'd46;
        i_metrics[5][6] <= 10'd52; i_labels[5][6] <= 8'd47;
        i_metrics[5][7] <= 10'd53; i_labels[5][7] <= 8'd48;

        i_metrics[6][0] <= 10'd60; i_labels[6][0] <= 8'd49;
        i_metrics[6][1] <= 10'd59; i_labels[6][1] <= 8'd50;
        i_metrics[6][2] <= 10'd58; i_labels[6][2] <= 8'd51;
        i_metrics[6][3] <= 10'd57; i_labels[6][3] <= 8'd52;
        i_metrics[6][4] <= 10'd56; i_labels[6][4] <= 8'd53;
        i_metrics[6][5] <= 10'd55; i_labels[6][5] <= 8'd54;
        i_metrics[6][6] <= 10'd54; i_labels[6][6] <= 8'd55;
        i_metrics[6][7] <= 10'd61; i_labels[6][7] <= 8'd56;

        i_metrics[7][0] <= 10'd70; i_labels[7][0] <= 8'd57;
        i_metrics[7][1] <= 10'd69; i_labels[7][1] <= 8'd58;
        i_metrics[7][2] <= 10'd68; i_labels[7][2] <= 8'd59;
        i_metrics[7][3] <= 10'd67; i_labels[7][3] <= 8'd60;
        i_metrics[7][4] <= 10'd66; i_labels[7][4] <= 8'd61;
        i_metrics[7][5] <= 10'd65; i_labels[7][5] <= 8'd62;
        i_metrics[7][6] <= 10'd64; i_labels[7][6] <= 8'd63;
        i_metrics[7][7] <= 10'd63; i_labels[7][7] <= 8'd64;

        @(posedge clk);
        i_valid <= 1'b0;

        repeat (20) @(posedge clk);
        $finish;
    end

endmodule