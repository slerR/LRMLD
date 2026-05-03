`timescale 1ns / 1ps

module tb_comb;

    parameter L       = 4;
    parameter logic IS_STM = 1;
    parameter N       = 4;
    parameter N1      = 4;
    parameter N_COS   = 2;
    parameter METRIC_W = 8;
    parameter LABEL_W  = 16;
    parameter LABEL_W1 = 16;
    parameter CONC_W   = LABEL_W + LABEL_W1;
    parameter N_U      = 2;

    localparam N_LIM       = (N * N1 < L) ? N  : ( (L <= 4) ? 2 : (L <= 6) ? 2 : (L <= 9) ? 3 : (L <= 12) ? 3 : 4 );
    localparam N1_LIM      = (N * N1 < L) ? N1 : ( (L <= 4) ? 2 : (L <= 6) ? 3 : (L <= 9) ? 3 : (L <= 12) ? 4 : 4 );
    localparam TOTAL_COMBO  = N_LIM * N1_LIM;
    localparam L_OUT        = (TOTAL_COMBO < L) ? TOTAL_COMBO : L;
    localparam N_OUT        = (N >= L & N1 >= L) ? L : L_OUT;
    localparam FF_P_W       = $clog2(2*N_OUT);
    localparam logic [FF_P_W - 1 : 0] FF_P = {FF_P_W{1'b1}};

    localparam logic [2*$clog2(N_COS) - 1 : 0] TBL [0 : N_COS - 1][0 : N_U - 1] = '{
        '{2'b01, 2'b10},
        '{2'b00, 2'b11}
    };

    logic                          clk;
    logic                          i_valid;
    logic [   N*METRIC_W - 1 : 0]  i_metrics  [0 : N_COS - 1];
    logic [    N*LABEL_W - 1 : 0]  i_labels   [0 : N_COS - 1];
    logic [  N1*METRIC_W - 1 : 0]  i_metrics1 [0 : N_COS - 1];
    logic [   N1*LABEL_W1 - 1 : 0] i_labels1  [0 : N_COS - 1];
    logic [N_OUT*METRIC_W - 1 : 0] o_metrics  [0 : N_COS - 1];
    logic [  N_OUT*CONC_W - 1 : 0] o_labels   [0 : N_COS - 1];
    logic                          o_valid;

    comb #(
        .L       (L),
        .IS_STM  (IS_STM),
        .N       (N),
        .N1      (N1),
        .N_COS   (N_COS),
        .METRIC_W(METRIC_W),
        .LABEL_W (LABEL_W),
        .LABEL_W1(LABEL_W1),
        .CONC_W  (CONC_W),
        .N_U     (N_U),
        .TBL     (TBL),
        .FF_P    (FF_P)
    ) dut (
        .clk      (clk),
        .i_valid  (i_valid),
        .i_metrics(i_metrics),
        .i_labels (i_labels),
        .i_metrics1(i_metrics1),
        .i_labels1 (i_labels1),
        .o_metrics(o_metrics),
        .o_labels (o_labels),
        .o_valid  (o_valid)
    );

    initial begin
        clk = 0;
    end

    always #5 clk = ~clk;

    initial begin
        @(posedge clk);
        i_valid       <= 0;
        repeat(2)@(posedge clk);
        i_valid       <= 1;
        i_metrics[0]  <= {8'd1, 8'd5, 8'd9, 8'd13};
        i_labels[0]   <= {16'd0, 16'd1, 16'd2, 16'd3};
        i_metrics[1]  <= {8'd2, 8'd6, 8'd10, 8'd14};
        i_labels[1]   <= {16'd4, 16'd5, 16'd6, 16'd7};

        i_metrics1[0] <= {8'd3, 8'd7, 8'd11, 8'd15};
        i_labels1[0]  <= {16'd8, 16'd9, 16'd10, 16'd11};
        i_metrics1[1] <= {8'd4, 8'd8, 8'd12, 8'd16};
        i_labels1[1]  <= {16'd12, 16'd13, 16'd14, 16'd15};
        
        @(posedge clk);
        i_valid       <= 0;
        
        repeat(1)@(posedge clk);
        i_valid       <= 1;
        i_metrics[0]  <= {8'd17, 8'd18, 8'd19, 8'd20};
        i_labels[0]   <= {16'd16, 16'd17, 16'd18, 16'd19};
        i_metrics[1]  <= {8'd21, 8'd22, 8'd23, 8'd24};
        i_labels[1]   <= {16'd20, 16'd21, 16'd22, 16'd23};

        i_metrics1[0] <= {8'd25, 8'd26, 8'd27, 8'd28};
        i_labels1[0]  <= {16'd24, 16'd25, 16'd26, 16'd27};
        i_metrics1[1] <= {8'd29, 8'd30, 8'd31, 8'd32};
        i_labels1[1]  <= {16'd28, 16'd29, 16'd30, 16'd31};

        @(posedge clk);
        i_valid <= 0;

        repeat (20) @(posedge clk);
        $finish;
    end

endmodule