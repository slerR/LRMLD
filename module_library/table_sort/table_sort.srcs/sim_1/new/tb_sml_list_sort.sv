`timescale 1ns / 1ps

module tb_sml_list_sort;

    parameter METRIC_W = 10;
    parameter LABEL_W  = 8;
    parameter N        = 3;

    logic clk;
    logic i_valid;
    logic [METRIC_W - 1 : 0] i_metrics [0 : N - 1];
    logic [ LABEL_W - 1 : 0] i_labels  [0 : N - 1];
    logic o_valid;
    logic [METRIC_W - 1 : 0] o_metrics [0 : N - 1];
    logic [ LABEL_W - 1 : 0] o_labels  [0 : N - 1];

    sml_list_sort #(
        .METRIC_W (METRIC_W),
        .LABEL_W  (LABEL_W),
        .N        (N)
    ) dut (
        .clk      (clk),
        .i_valid  (i_valid),
        .i_metrics(i_metrics),
        .i_labels (i_labels),
        .o_valid  (o_valid),
        .o_metrics(o_metrics),
        .o_labels (o_labels)
    );

    initial begin
        clk = 1'b0;
    end

    always #5 clk = ~clk;

    initial begin
        i_valid = 1'b0;
        for (int k = 0; k < N; k++) begin
            i_metrics[k] = '0;
            i_labels[k]  = '0;
        end

        repeat (2) @(posedge clk);

        i_valid      <= 1'b1;
        i_metrics[0] <= 10'd17; i_labels[0] <= 8'd3;
        i_metrics[1] <= 10'd4;  i_labels[1] <= 8'd7;
        i_metrics[2] <= 10'd29; i_labels[2] <= 8'd1;
//        i_metrics[3] <= 10'd11; i_labels[3] <= 8'd9;
//        i_metrics[4] <= 10'd6;  i_labels[4] <= 8'd2;
        
        @(posedge clk);
        i_metrics[0] <= 10'd1;  i_labels[0] <= 8'd3;
        i_metrics[1] <= 10'd4;  i_labels[1] <= 8'd7;
        i_metrics[2] <= 10'd2;  i_labels[2] <= 8'd1;
//        i_metrics[3] <= 10'd11; i_labels[3] <= 8'd9;
//        i_metrics[4] <= 10'd6;  i_labels[4] <= 8'd2;
        
        @(posedge clk);
        i_valid <= 1'b0;

        repeat (10) @(posedge clk);
        $finish;
    end

endmodule