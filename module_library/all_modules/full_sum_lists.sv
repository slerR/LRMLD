// Total Latency, cycles: 4 + (log(N_EXT) * (log(N_EXT) + 1) / 2)
`timescale 1ns / 1ps

module full_sum_lists#(
    parameter  L           = 15,
    parameter  N           = 12,
    parameter  N1          = 12,
    parameter  METRIC_W    = 7,
    parameter  LABEL_W     = 2,
    parameter  LABEL_W1    = 3,
    localparam CONC_W      = LABEL_W + LABEL_W1,
    localparam B_N  = (L <= 4) ? 2 : (L <= 6) ? 2 : (L <= 9) ? 3 : (L <= 12) ? 3 : 4,
    localparam B_N1 = (L <= 4) ? 2 : (L <= 6) ? 3 : (L <= 9) ? 3 : (L <= 12) ? 4 : 4,
    localparam N_LIM  = (N * N1 < L) ? N  : (N < B_N) ? N : (N1 < B_N1) ? ((L + N1 - 1) / N1) : B_N,
    localparam N1_LIM = (N * N1 < L) ? N1 : (N1 < B_N1) ? N1 : (N < B_N)  ? ((L +  N - 1) / N)  : B_N1,
    localparam TOTAL_COMBO = N_LIM * N1_LIM,
    parameter  L_OUT       = (TOTAL_COMBO < L) ? TOTAL_COMBO : L,
    localparam [METRIC_W-1 : 0] MAX_METRIC = {METRIC_W{1'b1}}
)(
    input  logic                         clk,
    input  logic                         i_valid,
    input  logic [ N * METRIC_W - 1 : 0] i_metrics,
    input  logic [  N * LABEL_W - 1 : 0] i_labels,
    input  logic [N1 * METRIC_W - 1 : 0] i_metrics1,
    input  logic [N1 * LABEL_W1 - 1 : 0] i_labels1,
    output logic [     METRIC_W - 1 : 0] o_metrics [0 : L_OUT - 1],
  
    output logic [       CONC_W - 1 : 0] o_labels  [0 : L_OUT - 1],
    output logic                         o_valid
);

    logic [METRIC_W - 1 : 0] unpacked_m   [0 : N_LIM - 1];
    logic [ LABEL_W - 1 : 0] unpacked_l   [0 : N_LIM - 1];
   
    logic [METRIC_W - 1 : 0] unpacked_m1  [0 : N1_LIM - 1];
    logic [LABEL_W1 - 1 : 0] unpacked_l1  [0 : N1_LIM - 1];
    
    always_comb begin
        for(int i = 0; i < N_LIM; i++) begin
            unpacked_m[i] = i_metrics[N*METRIC_W - 1 - i*METRIC_W -: METRIC_W];
            unpacked_l[i] = i_labels [  N*LABEL_W - 1 - i*LABEL_W -: LABEL_W ];
        end
        for(int i = 0; i < N1_LIM; i++) begin
            unpacked_m1[i] = i_metrics1[N1*METRIC_W - 1 - i*METRIC_W -: METRIC_W];
            unpacked_l1[i] = i_labels1 [N1*LABEL_W1 - 1 - i*LABEL_W1 -: LABEL_W1];
        end
    end
    
    (* max_fanout = 1 *) 
    logic [      METRIC_W - 1 : 0] m_rep    [0 : N_LIM - 1][0 : N1_LIM - 1];
    (* max_fanout = 1 *) 
    logic [      METRIC_W - 1 : 0] m1_rep   [0 : N_LIM - 1][0 : N1_LIM - 1];
    logic [       LABEL_W - 1 : 0] l_rep    [0 : N_LIM - 1][0 : N1_LIM - 1];
    logic [      LABEL_W1 - 1 : 0] l1_rep   [0 : N_LIM - 1][0 : N1_LIM - 1];
    logic                          v_rep;
    
    always_ff @(posedge clk) begin
        v_rep <= i_valid;
        for(int i = 0; i < N_LIM; i++) begin
            for(int j = 0; j < N1_LIM; j++) begin
                m_rep [i][j] <= unpacked_m[i];
                m1_rep[i][j] <= unpacked_m1[j];
                l_rep [i][j] <= unpacked_l[i];
                l1_rep[i][j] <= unpacked_l1[j];
            end
        end 
    end
    
    logic [METRIC_W - 1 : 0 ] sum  [0 : TOTAL_COMBO - 1];
    logic [CONC_W   - 1 : 0 ] conc [0 : TOTAL_COMBO - 1];
    logic                     v_sum;
    
    always_comb begin
        v_sum = v_rep;
        for(int i = 0; i < N_LIM; i++) begin
            for(int j = 0; j < N1_LIM; j++) begin
                automatic logic [METRIC_W : 0] full_sum = m_rep[i][j] + m1_rep[i][j];
                sum [i*N1_LIM + j] = full_sum[METRIC_W] ? MAX_METRIC : full_sum[METRIC_W - 1 : 0];
                conc[i*N1_LIM + j] = {l_rep[i][j], l1_rep[i][j]};
            end
        end
    end
    
    logic [METRIC_W - 1 : 0 ] s_sum  [0 : TOTAL_COMBO - 1];
    logic [CONC_W   - 1 : 0 ] s_conc [0 : TOTAL_COMBO - 1];
    logic                     s_valid;
    
    sml_list_sort#(
        .METRIC_W(METRIC_W   ),
        .LABEL_W (CONC_W     ),
        .N       (TOTAL_COMBO)
    )sort (
        .clk      (clk    ),
        .i_valid  (v_sum  ),
        .i_metrics(sum    ),
        .i_labels (conc   ),
        .o_metrics(s_sum  ),
        .o_labels (s_conc ),
        .o_valid  (s_valid)
    );
    
    always_comb begin
        for(int i = 0; i < L_OUT; i++) begin
            o_metrics[i] = s_sum [i];
            o_labels [i] = s_conc[i];
        end
    end  
    
    assign o_valid = s_valid;
    
endmodule