`timescale 1ns / 1ps

module tb_unite_lists;

parameter  L           = 7;
parameter  N           = 7;
parameter  N1          = 7;
parameter  METRIC_W    = 10;
parameter  LABEL_W     = 16;
parameter  LABEL_W1    = 16;  
parameter  CONC_W      = LABEL_W + LABEL_W1;

logic clk;
logic i_valid;
logic [  N*METRIC_W - 1 : 0] i_metrics;
logic [   N*LABEL_W - 1 : 0] i_labels;
logic [ N1*METRIC_W - 1 : 0] i_metrics1;
logic [N1*LABEL_W1 - 1 : 0] i_labels1;

logic o_valid;
logic [    METRIC_W - 1 : 0] o_metrics [0 : 15];    
logic [      CONC_W - 1 : 0] o_labels  [0 : 15];

unite_lists #(
    .L(L),
    .N(N),
    .N1(N1),
    .METRIC_W(METRIC_W),
    .LABEL_W(LABEL_W),
    .LABEL_W1(LABEL_W1)
) dut (
    .clk(clk),
    .i_valid(i_valid),
    .i_metrics(i_metrics),
    .i_labels(i_labels),
    .i_metrics1(i_metrics1),
    .i_labels1(i_labels1),
    .o_metrics(o_metrics),
    .o_labels(o_labels),
    .o_valid(o_valid)
);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    i_valid    = 0;
    i_metrics  = 0;
    i_labels   = 0;
    i_metrics1 = 0;
    i_labels1  = 0;

    @(posedge clk);
    i_valid <= 1;
    for (int i = 0; i < N; i++) begin
        i_metrics[  N*METRIC_W-1 -i*METRIC_W -: METRIC_W] <= i+1;
        i_labels [     N*LABEL_W-1 -i*LABEL_W -: LABEL_W] <= i+1;
    end
    for (int i = 0; i < N1; i++) begin
        i_metrics1[N1*METRIC_W-1 -i*METRIC_W -: METRIC_W] <= i;
        i_labels1 [N1*LABEL_W1-1 -i*LABEL_W1 -: LABEL_W1] <= i;
    end

    @(posedge clk);
    for (int i = 0; i < N; i++) begin
        i_metrics[  N*METRIC_W-1 -i*METRIC_W -: METRIC_W] <= i+2;
        i_labels [     N*LABEL_W-1 -i*LABEL_W -: LABEL_W] <= i+1;
    end
    for (int i = 0; i < N1; i++) begin
        i_metrics1[N1*METRIC_W-1 -i*METRIC_W -: METRIC_W] <= i+1;
        i_labels1 [N1*LABEL_W1-1 -i*LABEL_W1 -: LABEL_W1] <= i;
    end

    @(posedge clk);
    i_valid <= 0;

    repeat(50) @(posedge clk);
    $finish;
end
endmodule