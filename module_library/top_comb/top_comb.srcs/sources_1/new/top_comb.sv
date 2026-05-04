`timescale 1ns / 1ps

module top_comb#(
    parameter  L           = 4,
    parameter  N           = 4,                 
    parameter  N1          = 4,
    parameter  N_COS       = 4,                 
    parameter  METRIC_W    = 10,                
    parameter  LABEL_W     = 16,                
    parameter  LABEL_W1    = 16,                
    parameter  CONC_W      = LABEL_W + LABEL_W1,
    localparam N_LIM       = (N * N1 < L) ? N  : ( (L <= 4) ? 2 : (L <= 6) ? 2 : (L <= 9) ? 3 : (L <= 12) ? 3 : 4 ),
    localparam N1_LIM      = (N * N1 < L) ? N1 : ( (L <= 4) ? 2 : (L <= 6) ? 3 : (L <= 9) ? 3 : (L <= 12) ? 4 : 4 ),
    localparam TOTAL_COMBO = N_LIM * N1_LIM,
    localparam L_OUT       = (TOTAL_COMBO < L) ? TOTAL_COMBO : L,
    // Длина списка на выходе    
    parameter  N_OUT       = (N >= L & N1 >= L) ? L : L_OUT,
    localparam FF_P_W      = $clog2(2*N_OUT),
    // кол-во регистровых слоев внутри merge_2n_n
    parameter [0 : FF_P_W - 1] FF_P = {FF_P_W{1'b1}} 
)(
    input logic                          clk,
    input logic                          i_valid,
    // first CBT
    input  logic [   N*METRIC_W - 1 : 0] i_metrics   [0 : N_COS - 1],
    input  logic [    N*LABEL_W - 1 : 0] i_labels    [0 : N_COS - 1],
    // second CBT
    input  logic [   N1*METRIC_W - 1 : 0] i_metrics1 [0 : N_COS - 1],
    input  logic [   N1*LABEL_W1 - 1 : 0] i_labels1  [0 : N_COS - 1],
    // united CBT
    output logic [      METRIC_W - 1 : 0] o_metrics  [0 : N_OUT - 1],    
    output logic [        CONC_W - 1 : 0] o_labels   [0 : N_OUT - 1],
    
    output logic                          o_valid
);
    
    generate 
            // unite_lists output
            logic [METRIC_W - 1 : 0] u_metrics [0 : N_COS - 1][0 : N_OUT - 1];
            logic [  CONC_W - 1 : 0] u_labels  [0 : N_COS - 1][0 : N_OUT - 1];
            logic [   N_COS - 1 : 0] u_valid;
            logic                    valid;                   
            // merge tree output
            logic [METRIC_W - 1 : 0] m_metrics [0 : N_OUT - 1];
            logic [  CONC_W - 1 : 0] m_labels  [0 : N_OUT - 1];
            logic                    m_valid;
            
            for(genvar i = 0; i < N_COS; i++) begin : COSSET                
                    unite_lists #(
                        .L         (L       ),
                        .N         (N       ),
                        .N1        (N1      ),
                        .METRIC_W  (METRIC_W),
                        .LABEL_W   (LABEL_W ),
                        .LABEL_W1  (LABEL_W1)
                    )unite_lists (
                        .clk       (clk          ),
                        .i_valid   (i_valid      ),
                        .i_metrics (i_metrics [i]),
                        .i_labels  (i_labels  [i]),
                        .i_metrics1(i_metrics1[i]),
                        .i_labels1 (i_labels1 [i]),
                        .o_metrics (u_metrics [i]),
                        .o_labels  (u_labels  [i]),
                        .o_valid   (u_valid   [i])
                    );
                
                assign valid = &u_valid;
            end
            
            merge_tree #(
                .NUM_LISTS (N_COS   ),
                .N_INPUTS  (N_OUT   ),
                .METRIC_W  (METRIC_W),
                .LABEL_W   (CONC_W  ),
                .FF_P      (FF_P    )
            )merge_tree (
                .clk     (clk      ),
                .i_valid (valid    ),
                .i_m     (u_metrics),
                .i_l     (u_labels ),
                .o_m     (m_metrics),
                .o_l     (m_labels ),
                .o_valid (m_valid  )
            );
            
            always_comb begin
                for(int i = 0; i < N_OUT; i++) begin
                    o_metrics[i] = m_metrics[i];
                    o_labels [i] = m_labels [i];
                end
            end
            
            assign o_valid = m_valid;    
    endgenerate
    
endmodule
