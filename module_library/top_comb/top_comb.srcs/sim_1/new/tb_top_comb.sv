`timescale 1ns / 1ps

module tb_top_comb;

    parameter L       = 2;
    parameter N       = 4;
    parameter N1      = 4;
    parameter N_COS   = 2;
    parameter METRIC_W = 8;
    parameter LABEL_W  = 4;
    parameter LABEL_W1 = 4;
    parameter CONC_W   = LABEL_W + LABEL_W1;

    localparam N_LIM       = (N * N1 < L) ? N  : ( (L <= 4) ? 2 : (L <= 6) ? 2 : (L <= 9) ? 3 : (L <= 12) ? 3 : 4 );
    localparam N1_LIM      = (N * N1 < L) ? N1 : ( (L <= 4) ? 2 : (L <= 6) ? 3 : (L <= 9) ? 3 : (L <= 12) ? 4 : 4 );
    localparam TOTAL_COMBO  = N_LIM * N1_LIM;
    localparam L_OUT        = (TOTAL_COMBO < L) ? TOTAL_COMBO : L;
    localparam N_OUT        = (N >= L & N1 >= L) ? L : L_OUT;
    localparam FF_P_W       = $clog2(2*N_OUT);
    localparam logic [FF_P_W - 1 : 0] FF_P = {FF_P_W{1'b1}};

    logic                         clk;
    logic                         i_valid;
    logic [   N*METRIC_W - 1 : 0] i_metrics  [0 : N_COS - 1];
    logic [    N*LABEL_W - 1 : 0] i_labels   [0 : N_COS - 1];
    logic [  N1*METRIC_W - 1 : 0] i_metrics1 [0 : N_COS - 1];
    logic [  N1*LABEL_W1 - 1 : 0] i_labels1  [0 : N_COS - 1];
    logic [     METRIC_W - 1 : 0] o_metrics  [0 : N_OUT - 1];
    logic [       CONC_W - 1 : 0] o_labels   [0 : N_OUT - 1];
    logic                         o_valid;

    top_comb #(
        .L       (L       ),
        .N       (N       ),
        .N1      (N1      ),
        .N_COS   (N_COS   ),
        .METRIC_W(METRIC_W),
        .LABEL_W (LABEL_W ),
        .LABEL_W1(LABEL_W1),
        .CONC_W  (CONC_W  ),
        .FF_P    (FF_P    )
    ) dut (
        .clk       (clk       ),
        .i_valid   (i_valid   ),
        .i_metrics (i_metrics ),
        .i_labels  (i_labels  ),
        .i_metrics1(i_metrics1),
        .i_labels1 (i_labels1 ),
        .o_metrics (o_metrics ),
        .o_labels  (o_labels  ),
        .o_valid   (o_valid   )
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
        i_labels[0]   <= {4'b0000, 4'b0001, 4'b0010, 4'b0100};
        i_metrics[1]  <= {8'd2, 8'd6, 8'd10, 8'd14};
        i_labels[1]   <= {4'b1000, 4'b0011, 4'b0111, 4'b1111};

        i_metrics1[0] <= {8'd3, 8'd7, 8'd11, 8'd15};
        i_labels1[0]  <= {4'b0001, 4'b0010, 4'b0011, 4'b0100};
        i_metrics1[1] <= {8'd4, 8'd8, 8'd12, 8'd16};
        i_labels1[1]  <= {4'b0101, 4'b0111, 4'b1000, 4'b1001};
        
        @(posedge clk);
        i_metrics[0]  <= {8'd17, 8'd18, 8'd19, 8'd20};
        i_metrics[1]  <= {8'd21, 8'd22, 8'd23, 8'd24};
        
        i_metrics1[0] <= {8'd25, 8'd26, 8'd27, 8'd28};
        i_metrics1[1] <= {8'd29, 8'd30, 8'd31, 8'd32};

        @(posedge clk);
        i_valid <= 0;

        repeat (20) @(posedge clk);
        $finish;
    end

endmodule