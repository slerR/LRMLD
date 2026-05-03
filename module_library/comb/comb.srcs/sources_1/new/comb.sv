`timescale 1ns / 1ps

module comb#(
    parameter L            = 4,
    // 0 - на каждое объединение списков по unite_lists, 1 - используется конечный автомат
    parameter logic IS_STM = 0,
    parameter  N           = 4,                 
    parameter  N1          = 4,
    parameter  N_COS       = 4,                 
    parameter  METRIC_W    = 10,                
    parameter  LABEL_W     = 16,                
    parameter  LABEL_W1    = 16,                
    parameter  CONC_W      = LABEL_W + LABEL_W1,
    // кол-во объеденений на 1 ветвь в объединенной CBT
    parameter  N_U         = 2,
    // Таблица объединений
    parameter logic [2*$clog2(N_COS) - 1 : 0] TBL [0 : N_COS - 1][0 : N_U - 1],
    localparam N_LIM       = (N * N1 < L) ? N  : ( (L <= 4) ? 2 : (L <= 6) ? 2 : (L <= 9) ? 3 : (L <= 12) ? 3 : 4 ),
    localparam N1_LIM      = (N * N1 < L) ? N1 : ( (L <= 4) ? 2 : (L <= 6) ? 3 : (L <= 9) ? 3 : (L <= 12) ? 4 : 4 ),
    localparam TOTAL_COMBO = N_LIM * N1_LIM,
    localparam L_OUT       = (TOTAL_COMBO < L) ? TOTAL_COMBO : L,
    // Длина списка на выходе    
    parameter  N_OUT       = (N >= L & N1 >= L) ? L : L_OUT,
    localparam FF_P_W      = $clog2(2*N_OUT),
    // кол-во регистровых слоев внутри одного merge_2n_n
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
    output logic [N_OUT*METRIC_W - 1 : 0] o_metrics  [0 : N_COS - 1],    
    output logic [  N_OUT*CONC_W - 1 : 0] o_labels   [0 : N_COS - 1],
    
    output logic                          o_valid
    );
    
    generate 
        if(!IS_STM) begin
            // unite_lists output
            logic [METRIC_W - 1 : 0] u_metrics [0 : N_COS - 1][0 : N_U - 1][0 : N_OUT - 1];
            logic [  CONC_W - 1 : 0] u_labels  [0 : N_COS - 1][0 : N_U - 1][0 : N_OUT - 1];
            logic [     N_U - 1 : 0] u_valid   [0 : N_COS - 1];
            // valid of the one element unation of the new CBT
            logic [   N_COS - 1 : 0] c_valid;
            // merge tree output
            logic [METRIC_W - 1 : 0] m_metrics [0 : N_COS - 1][0 : N_OUT - 1];
            logic [  CONC_W - 1 : 0] m_labels  [0 : N_COS - 1][0 : N_OUT - 1];
            logic [   N_COS - 1 : 0] m_valid;
            
            for(genvar i = 0; i < N_COS; i++) begin : COSSET
                for(genvar j = 0; j < N_U; j++) begin : UNATION
                    localparam logic [$clog2(N_COS) - 1 : 0] L_IDX = TBL[i][j][2*$clog2(N_COS) - 1 -: $clog2(N_COS)];
                    localparam logic [$clog2(N_COS) - 1 : 0] R_IDX = TBL[i][j][  $clog2(N_COS) - 1 -: $clog2(N_COS)];
                    
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
                        .i_metrics (i_metrics [L_IDX]),
                        .i_labels  (i_labels  [L_IDX]),
                        .i_metrics1(i_metrics1[R_IDX]),
                        .i_labels1 (i_labels1 [R_IDX]),
                        .o_metrics (u_metrics [i][j] ),
                        .o_labels  (u_labels  [i][j] ),
                        .o_valid   (u_valid   [i][j] )
                    );
                end
                
                assign c_valid[i] = &u_valid[i];
                merge_tree #(
                    .NUM_LISTS (N_U     ),
                    .N_INPUTS  (N_OUT   ),
                    .METRIC_W  (METRIC_W),
                    .LABEL_W   (CONC_W  ),
                    .FF_P      (FF_P    )
                )merge_tree (
                    .clk     (clk         ),
                    .i_valid (c_valid  [i]),
                    .i_m     (u_metrics[i]),
                    .i_l     (u_labels [i]),
                    .o_m     (m_metrics[i]),
                    .o_l     (m_labels [i]),
                    .o_valid (m_valid  [i])
                );
            end
            
            always_comb begin
                for(int i = 0; i < N_COS; i++) begin
                    for(int j = 0; j < N_OUT; j++) begin
                        o_metrics[i][(N_OUT*METRIC_W - 1) -j*METRIC_W -: METRIC_W] = m_metrics[i][j];
                        o_labels [i][(  N_OUT*CONC_W - 1) -j*CONC_W   -: CONC_W  ] = m_labels [i][j];
                    end
                end
            end
            
            assign o_valid = &m_valid;
              
        end else begin
        /// добавить конченный автомат
        end
    endgenerate
    
endmodule
