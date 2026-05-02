`timescale 1ns / 1ps

module tb_sum_lists;
    
    parameter  L          = 16;
    parameter  N          = 12;
    parameter  N1         = 12;
    parameter  METRIC_W   = 10;
    parameter  METRIC_W1  = 10;
    parameter  LABEL_W    = 16;
    parameter  LABEL_W1   = 16;
    parameter  SUM_W      = (METRIC_W > METRIC_W1) ? METRIC_W + 1 : METRIC_W1 + 1; 
    parameter  CONC_W     = LABEL_W + LABEL_W1;
    localparam L_TARGET   = (N*N1 < L) ? (N*N1) : (L <= 4 ? 4 : L <= 8 ? 8 : 16);
    localparam N_LIM      = (N*N1 < L) ? N : ( (N < 3) ? N : ( (L_TARGET/3 + (L_TARGET%3 != 0)) > N ? N : ( (L_TARGET/4 + (L_TARGET%4 != 0)) > N ? N : ( (N >= 4 && N1 >= 4) ? 4 : (N < 4 ? N : 4) ) ) ) );
    localparam N1_LIM     = (N*N1 < L) ? N1 : ( (L_TARGET / N_LIM) + (L_TARGET % N_LIM != 0) );
    localparam [METRIC_W-1 : 0] MAX_METRIC = {METRIC_W{1'b1}};
    localparam [  CONC_W-1 : 0] CONC_PAD   = {CONC_W{1'b0}};
    parameter  L_OUT      = (N_LIM*N1_LIM < L) ? (N_LIM*N1_LIM) : (N_LIM*N1_LIM <= 4 ? 4 : N_LIM*N1_LIM <= 8 ? 8 : 16);
    
    logic clk;
    logic i_valid;
    logic [    N*METRIC_W - 1 : 0] i_metrics;
    logic [     N*LABEL_W - 1 : 0] i_labels;
    logic [  N1*METRIC_W1 - 1 : 0] i_metrics1;
    logic [   N1*LABEL_W1 - 1 : 0] i_labels1;
    
    logic o_valid;
    logic [      METRIC_W - 1 : 0] o_metrics [0 : L_OUT - 1];
    logic [        CONC_W - 1 : 0] o_labels  [0 : L_OUT - 1];
    
    full_sum_lists #(
        .L(L),
        .N(N),
        .N1(N1),
        .METRIC_W(METRIC_W),
        .METRIC_W1(METRIC_W1),
        .LABEL_W(LABEL_W),
        .LABEL_W1(LABEL_W1)
    ) dut (
        .clk(clk),
        .i_valid(i_valid),
        .i_metrics(i_metrics),
        .i_labels(i_labels),
        .i_metrics1(i_metrics1),
        .i_labels1(i_labels1),
        .o_valid(o_valid),
        .o_metrics(o_metrics),
        .o_labels(o_labels)
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
            i_metrics[(i+1)*METRIC_W-1 -: METRIC_W] <= (i+1)*10;
            i_labels[(i+1)*LABEL_W-1 -: LABEL_W]    <= i;
        end
        for (int i = 0; i < N1; i++) begin
            i_metrics1[(i+1)*METRIC_W1-1 -: METRIC_W1] <= (i+1)*5;
            i_labels1[(i+1)*LABEL_W1-1 -: LABEL_W1]   <= i + 10;
        end
    
        @(posedge clk);
        for (int i = 0; i < N; i++) begin
            i_metrics[(i+1)*METRIC_W-1 -: METRIC_W] <= (i+1)*100;
            i_labels[(i+1)*LABEL_W-1 -: LABEL_W]    <= i + 20;
        end
        for (int i = 0; i < N1; i++) begin
            i_metrics1[(i+1)*METRIC_W1-1 -: METRIC_W1] <= (i+1)*50;
            i_labels1[(i+1)*LABEL_W1-1 -: LABEL_W1]   <= i + 30;
        end
    
        @(posedge clk);
        i_valid <= 0;
    
        repeat(40) @(posedge clk);
        $finish;
    end
    
endmodule