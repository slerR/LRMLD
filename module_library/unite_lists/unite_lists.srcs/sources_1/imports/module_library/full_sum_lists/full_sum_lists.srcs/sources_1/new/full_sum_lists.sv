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
    localparam N_LIM       = (N * N1 < L) ? N  : ( (L <= 4) ? 2 : (L <= 6) ? 2 : (L <= 9) ? 3 : (L <= 12) ? 3 : 4 ),
    localparam N1_LIM      = (N * N1 < L) ? N1 : ( (L <= 4) ? 2 : (L <= 6) ? 3 : (L <= 9) ? 3 : (L <= 12) ? 4 : 4 ),
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
            unpacked_m[i] = i_metrics[(i + 1) * METRIC_W - 1 -: METRIC_W];
            unpacked_l[i] = i_labels [  (i + 1) * LABEL_W - 1 -: LABEL_W];
        end
        for(int i = 0; i < N1_LIM; i++) begin
            unpacked_m1[i] = i_metrics1[(i + 1) * METRIC_W - 1 -: METRIC_W];
            unpacked_l1[i] = i_labels1 [(i + 1) * LABEL_W1 - 1 -: LABEL_W1];
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
    
    logic [ TOTAL_COMBO * METRIC_W - 1 : 0 ] sum_packed;
    logic [ TOTAL_COMBO * CONC_W   - 1 : 0 ] conc_packed;
    logic                                    v_sum;
    
    always_ff @(posedge clk) begin
        v_sum <= v_rep;
        for(int i = 0; i < N_LIM; i++) begin
            for(int j = 0; j < N1_LIM; j++) begin
                automatic logic [METRIC_W : 0] full_sum = m_rep[i][j] + m1_rep[i][j];
                sum_packed [(TOTAL_COMBO - (i * N1_LIM + j)) * METRIC_W - 1 -: METRIC_W ] <= full_sum[METRIC_W] ? MAX_METRIC : full_sum[METRIC_W - 1 : 0];
                conc_packed[(TOTAL_COMBO - (i * N1_LIM + j)) * CONC_W   - 1 -: CONC_W   ] <= {l_rep[i][j], l1_rep[i][j]};
            end
        end
    end
    
    logic [TOTAL_COMBO * METRIC_W - 1 : 0] sorted_m_packed;
    logic [TOTAL_COMBO * CONC_W   - 1 : 0] sorted_c_packed;
    logic                                  v_sort;
    
    bitonic_sort_fp #(
        .METRIC_W (METRIC_W   ),
        .LABEL_W  (CONC_W     ),
        .N        (TOTAL_COMBO)
    ) sort_inst (
        .clk       (clk             ),
        .i_valid   (v_sum           ),
        .i_metrics (sum_packed      ),
        .i_labels  (conc_packed     ),
        .o_valid   (v_sort          ),
        .o_metrics (sorted_m_packed ),
        .o_labels  (sorted_c_packed )
    );
    
    always_comb begin
        for(int i = 0; i < L_OUT; i++) begin
            o_metrics[i] = sorted_m_packed[(TOTAL_COMBO - i) * METRIC_W - 1 -: METRIC_W];
            o_labels [i] = sorted_c_packed[ (TOTAL_COMBO - i) * CONC_W   - 1 -: CONC_W ];
        end
    end
    
    assign o_valid = v_sort;
    
endmodule