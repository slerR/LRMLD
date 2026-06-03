`timescale 1ns / 1ps

module top_comb#(
    parameter  L            = 4,
    parameter  logic [1 : 0] FSM = 2'b00, // 0 - Parallel, 1 - Sequential, only one unite_list,
    // 2 - only one unite_list and log2(N_COS) merge_2n_n 
    parameter  N            = 4,                 
    parameter  N1           = 4,
    parameter  N_COS        = 4,                 
    parameter  METRIC_W     = 10,                
    parameter  LABEL_W      = 16,                
    parameter  LABEL_W1     = 16,                
    parameter  CONC_W       = LABEL_W + LABEL_W1,
    localparam B_N          = (L <= 4) ? 2 : (L <= 6) ? 2 : (L <= 9) ? 3 : (L <= 12) ? 3 : 4,
    localparam B_N1         = (L <= 4) ? 2 : (L <= 6) ? 3 : (L <= 9) ? 3 : (L <= 12) ? 4 : 4,
    localparam N_LIM        = (N * N1 < L) ? N  : (N < B_N) ? N : (N1 < B_N1) ? ((L + N1 - 1) / N1) : B_N,
    localparam N1_LIM       = (N * N1 < L) ? N1 : (N1 < B_N1) ? N1 : (N < B_N)  ? ((L +  N - 1) / N)  : B_N1,
    localparam TOTAL_COMBO  = N_LIM * N1_LIM,
    localparam L_OUT        = (TOTAL_COMBO < L) ? TOTAL_COMBO : L,
    parameter  N_OUT        = (N >= L & N1 >= L) ? L : L_OUT
)(
    input logic                          clk,
    input logic                          i_valid,
    // first CBT
    input  logic [   N*METRIC_W - 1 : 0] i_metrics   [0 : N_COS - 1],
    input  logic [    N*LABEL_W - 1 : 0] i_labels    [0 : N_COS - 1],
    // second CBT
    input  logic [  N1*METRIC_W - 1 : 0] i_metrics1  [0 : N_COS - 1],
    input  logic [  N1*LABEL_W1 - 1 : 0] i_labels1   [0 : N_COS - 1],
    // united CBT
    output logic [      METRIC_W - 1 : 0] o_metrics   [0 : N_OUT - 1],    
    output logic [        CONC_W - 1 : 0] o_labels    [0 : N_OUT - 1],
    
    output logic                          o_valid
);
    
    generate  
        if (FSM == 2'b00) begin : PARALLEL
            logic [METRIC_W - 1 : 0] u_metrics [0 : N_COS - 1][0 : N_OUT - 1];
            logic [  CONC_W - 1 : 0] u_labels  [0 : N_COS - 1][0 : N_OUT - 1];
            logic [   N_COS - 1 : 0] u_valid;
            
            for(genvar i = 0; i < N_COS; i++) begin : COSSET                
                unite_lists #(
                    .L         (L       ),
                    .N         (N       ),
                    .N1        (N1      ),
                    .METRIC_W  (METRIC_W),
                    .LABEL_W   (LABEL_W ),
                    .LABEL_W1  (LABEL_W1)
                )unite_lists (
                    .clk       (clk              ),
                    .i_valid   (i_valid          ),
                    .i_metrics (i_metrics [i]    ),
                    .i_labels  (i_labels  [i]    ),
                    .i_metrics1(i_metrics1[i]    ),
                    .i_labels1 (i_labels1 [i]    ),
                    .o_metrics (u_metrics [i]    ),
                    .o_labels  (u_labels  [i]    ),
                    .o_valid   (u_valid   [i]    )
                );
            end
            
            merge_tree #(
                .NUM_LISTS (N_COS   ),
                .N_INPUTS  (N_OUT   ),
                .METRIC_W  (METRIC_W),
                .LABEL_W   (CONC_W  )
            )merge_tree (
                .clk     (clk      ),
                .i_valid (&u_valid ),
                .i_m     (u_metrics),
                .i_l     (u_labels ),
                .o_m     (o_metrics),
                .o_l     (o_labels ),
                .o_valid (o_valid  )
            );

        end else if(FSM == 2'b01) begin : SEQUENTIAL_FSM
            logic [   N*METRIC_W - 1 : 0] metrics_r  [0 : N_COS - 1];
            logic [    N*LABEL_W - 1 : 0] labels_r   [0 : N_COS - 1];                                                  
            logic [  N1*METRIC_W - 1 : 0] metrics1_r [0 : N_COS - 1];
            logic [  N1*LABEL_W1 - 1 : 0] labels1_r  [0 : N_COS - 1];
            logic                         valid_d;

            logic [$clog2(N_COS) - 1 : 0] phase;
            logic                         act;
            
            logic [METRIC_W - 1 : 0] u_metrics [0 : N_OUT - 1];
            logic [  CONC_W - 1 : 0] u_labels  [0 : N_OUT - 1];
            logic                    u_valid;

            logic [METRIC_W - 1 : 0] u_metrics_d [0 : N_COS - 1][0 : N_OUT - 1];
            logic [  CONC_W - 1 : 0] u_labels_d  [0 : N_COS - 1][0 : N_OUT - 1];
            logic [$clog2(N_COS) - 1 : 0] out_cnt;

            always_ff @(posedge clk) begin
                valid_d <= i_valid;
                if (i_valid) begin
                    metrics_r  <= i_metrics;
                    labels_r   <= i_labels;
                    metrics1_r <= i_metrics1;
                    labels1_r  <= i_labels1;
                end
            end

            logic start;
            assign start = i_valid & ~valid_d;

            always_ff @(posedge clk) begin
                if (start) begin
                    phase <= 0;
                    act   <= 1;
                end else if (act) begin
                    if (phase == N_COS - 1) begin
                        phase <= 0;
                        act   <= 0;
                    end else begin
                        phase <= phase + 1;
                    end
                end
            end

            unite_lists #(
                .L         (L       ),
                .N         (N       ),
                .N1        (N1      ),
                .METRIC_W  (METRIC_W),
                .LABEL_W   (LABEL_W ),
                .LABEL_W1  (LABEL_W1)
            )unite_lists_inst (
                .clk       (clk                   ),
                .i_valid   (act                   ),
                .i_metrics (metrics_r  [phase]    ),
                .i_labels  (labels_r   [phase]    ),
                .i_metrics1(metrics1_r [phase]    ),
                .i_labels1 (labels1_r  [phase]    ),
                .o_metrics (u_metrics             ),
                .o_labels  (u_labels              ),
                .o_valid   (u_valid               )
            );

            for (genvar i = 0; i < N_COS; i++) begin : DELAY_BLOCK
                localparam int D_VAL = N_COS - 1 - i;
                list_delay #(.DELAY(D_VAL), .N_OUT(N_OUT), .WIDTH(METRIC_W)) 
                    dl_m (.clk(clk), .i_data(u_metrics), .o_data(u_metrics_d[i]));
                list_delay #(.DELAY(D_VAL), .N_OUT(N_OUT), .WIDTH(CONC_W))    
                    dl_l (.clk(clk), .i_data(u_labels),  .o_data(u_labels_d[i]));
            end

            always_ff @(posedge clk) begin
                if (u_valid) begin
                    if (out_cnt == N_COS - 1) out_cnt <= 0;
                    else                      out_cnt <= out_cnt + 1;
                end else begin
                    out_cnt <= 0;
                end
            end

            logic tree_valid;
            assign tree_valid = (u_valid && out_cnt == N_COS - 1);

            merge_tree #(
                .NUM_LISTS (N_COS   ),
                .N_INPUTS  (N_OUT   ),
                .METRIC_W  (METRIC_W),
                .LABEL_W   (CONC_W  )
            )merge_tree_inst (
                .clk     (clk          ),
                .i_valid (tree_valid   ),
                .i_m     (u_metrics_d  ),
                .i_l     (u_labels_d   ),
                .o_m     (o_metrics    ),
                .o_l     (o_labels     ),
                .o_valid (o_valid      )
            );
        end else if(FSM == 2'b10) begin : SEQUENTIAL_STAGE_TREE
            logic [   N*METRIC_W - 1 : 0] metrics_r  [0 : N_COS - 1];
            logic [    N*LABEL_W - 1 : 0] labels_r   [0 : N_COS - 1];                                                  
            logic [  N1*METRIC_W - 1 : 0] metrics1_r [0 : N_COS - 1];
            logic [  N1*LABEL_W1 - 1 : 0] labels1_r  [0 : N_COS - 1];
            logic                         valid_d;
            logic [$clog2(N_COS) - 1 : 0] phase;
            logic                         act;
            
            logic [METRIC_W - 1 : 0]      u_metrics [0 : N_OUT - 1];
            logic [  CONC_W - 1 : 0]      u_labels  [0 : N_OUT - 1];
            logic                         u_valid;

            always_ff @(posedge clk) begin
                valid_d <= i_valid;
                if (i_valid) begin
                    metrics_r  <= i_metrics; labels_r   <= i_labels;
                    metrics1_r <= i_metrics1; labels1_r  <= i_labels1;
                end
            end

            logic start;
            assign start = i_valid & ~valid_d;

            always_ff @(posedge clk) begin
                if (start) begin
                    phase <= 0; act   <= 1;
                end else if (act) begin
                    if (phase == N_COS - 1) begin phase <= 0; act <= 0; end 
                    else                          phase <= phase + 1;
                end
            end

            unite_lists #(
                .L(L), .N(N), .N1(N1), .METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .LABEL_W1(LABEL_W1)
            ) unite_lists_inst (
                .clk(clk), .i_valid(act),
                .i_metrics(metrics_r[phase]), .i_labels(labels_r[phase]),
                .i_metrics1(metrics1_r[phase]), .i_labels1(labels1_r[phase]),
                .o_metrics(u_metrics), .o_labels(u_labels), .o_valid(u_valid)
            );

            logic [METRIC_W - 1 : 0] dummy_m [N_COS][N_OUT];
            logic [  CONC_W - 1 : 0] dummy_l [N_COS][N_OUT];

            always_comb begin
                for (int c = 0; c < N_COS; c++) begin
                    for (int j = 0; j < N_OUT; j++) begin
                        if (c == 0) begin
                            dummy_m[c][j] = u_metrics[j];
                            dummy_l[c][j] = u_labels[j];
                        end else begin
                            dummy_m[c][j] = '0;
                            dummy_l[c][j] = '0;
                        end
                    end
                end
            end

            merge_tree #(
                .NUM_LISTS (N_COS   ),
                .N_INPUTS  (N_OUT   ),
                .METRIC_W  (METRIC_W),
                .LABEL_W   (CONC_W  ),
                .IS_SEQ    (1       )
            )merge_tree (
                .clk     (clk      ),
                .i_valid (u_valid  ),
                .i_m     (dummy_m  ),
                .i_l     (dummy_l  ),
                .o_m     (o_metrics),
                .o_l     (o_labels ),
                .o_valid (o_valid  )
            );
        end
    endgenerate
    
endmodule