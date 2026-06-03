`timescale 1ns / 1ps

module comb#(
    parameter L            = 4,
    parameter logic [1:0]  FSM = 2'b00,
    parameter  N           = 4,                 
    parameter  N1          = 4,
    parameter  N_COS       = 4,                 
    parameter  METRIC_W    = 10,                
    parameter  LABEL_W     = 16,                
    parameter  LABEL_W1    = 16,                
    parameter  CONC_W      = LABEL_W + LABEL_W1,
    parameter  N_U         = 2,
    parameter logic [2*$clog2(N_COS) - 1 : 0] TBL [0 : N_COS - 1][0 : N_U - 1],
    localparam B_N  = (L <= 4) ? 2 : (L <= 6) ? 2 : (L <= 9) ? 3 : (L <= 12) ? 3 : 4,
    localparam B_N1 = (L <= 4) ? 2 : (L <= 6) ? 3 : (L <= 9) ? 3 : (L <= 12) ? 4 : 4,
    localparam N_LIM  = (N * N1 < L) ? N  : (N < B_N) ? N : (N1 < B_N1) ? ((L + N1 - 1) / N1) : B_N,
    localparam N1_LIM = (N * N1 < L) ? N1 : (N1 < B_N1) ? N1 : (N < B_N)  ? ((L +  N - 1) / N)  : B_N1,
    localparam TOTAL_COMBO = N_LIM * N1_LIM,
    localparam L_OUT       = (TOTAL_COMBO < L) ? TOTAL_COMBO : L,
    parameter  N_OUT       = (N >= L & N1 >= L) ? L : L_OUT,
    localparam FF_P_W      = $clog2(2*N_OUT),
    parameter [0 : FF_P_W - 1] FF_P = {FF_P_W{1'b1}}
)(
    input logic                          clk,
    input logic                          i_valid,
    input  logic [   N*METRIC_W - 1 : 0] i_metrics   [0 : N_COS - 1],
    input  logic [    N*LABEL_W - 1 : 0] i_labels    [0 : N_COS - 1],
    input  logic [  N1*METRIC_W - 1 : 0] i_metrics1  [0 : N_COS - 1],
    input  logic [  N1*LABEL_W1 - 1 : 0] i_labels1   [0 : N_COS - 1],
    output logic [N_OUT*METRIC_W - 1 : 0] o_metrics  [0 : N_COS - 1],    
    output logic [  N_OUT*CONC_W - 1 : 0] o_labels   [0 : N_COS - 1],
    output logic                          o_valid
);
    
    generate 
        if(FSM == 2'b00) begin : SEQUENTIAL
            logic [METRIC_W - 1 : 0] u_metrics [0 : N_COS - 1][0 : N_U - 1][0 : N_OUT - 1];
            logic [  CONC_W - 1 : 0] u_labels  [0 : N_COS - 1][0 : N_U - 1][0 : N_OUT - 1];
            logic [     N_U - 1 : 0] u_valid   [0 : N_COS - 1];
            logic [   N_COS - 1 : 0] c_valid;
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
                    .LABEL_W   (CONC_W  )
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
            
        end else if(FSM == 2'b01) begin : FSM_NU
            logic                          valid_d;
            logic [    N*METRIC_W - 1 : 0] metrics_r  [0 : N_COS - 1];
            logic [     N*LABEL_W - 1 : 0] labels_r   [0 : N_COS - 1];                                                  
            logic [   N1*METRIC_W - 1 : 0] metrics1_r [0 : N_COS - 1];
            logic [   N1*LABEL_W1 - 1 : 0] labels1_r  [0 : N_COS - 1];
            
            logic [$clog2(N_U) - 1 : 0] phase;
            logic [$clog2(N_U) - 1 : 0] cur_phase;
            logic                       act;
            logic                       valid;
            
            logic [METRIC_W - 1 : 0] u_metrics [0 : N_COS - 1][0 : N_OUT - 1];
            logic [  CONC_W - 1 : 0] u_labels  [0 : N_COS - 1][0 : N_OUT - 1];
            logic [   N_COS - 1 : 0] u_valid;   
            
            logic [METRIC_W - 1 : 0] u_metrics_d [0 : N_COS - 1][0 : N_U - 1][0 : N_OUT - 1];
            logic [  CONC_W - 1 : 0] u_labels_d  [0 : N_COS - 1][0 : N_U - 1][0 : N_OUT - 1];  
            
            logic [$clog2(N_U) - 1 : 0] out_cnt  [0 : N_COS - 1];
            logic [      N_COS - 1 : 0] c_valid;  
            
            logic [METRIC_W - 1 : 0] m_metrics [0 : N_COS - 1][0 : N_OUT - 1];
            logic [  CONC_W - 1 : 0] m_labels  [0 : N_COS - 1][0 : N_OUT - 1];
            logic [   N_COS - 1 : 0] m_valid;      
            
            always_ff @(posedge clk) begin
                valid_d <= i_valid;
                if(i_valid) begin
                    metrics_r  <= i_metrics;
                    labels_r   <= i_labels;
                    metrics1_r <= i_metrics1;
                    labels1_r  <= i_labels1;
                end
            end
            
            logic  start;
            assign start = i_valid & ~valid_d;
            
            always_ff @(posedge clk) begin
                if(start) begin
                    phase <= 0;
                    act   <= 1;
                end else if(act) begin
                    if(phase == N_U - 1) begin
                        phase <= 0;
                        act   <= 0;
                    end else begin
                        phase <= phase + 1;
                    end
                end
            end
                      
            assign cur_phase = phase;
            assign valid     = act;
            
            for(genvar i = 0; i < N_COS; i++) begin : COSSET
                logic [ N*METRIC_W - 1 : 0] mux_metrics;
                logic [  N*LABEL_W - 1 : 0] mux_labels;
                logic [N1*METRIC_W - 1 : 0] mux_metrics1;
                logic [N1*LABEL_W1 - 1 : 0] mux_labels1;   
                
                logic [$clog2(N_COS) - 1 : 0] L_IDX; 
                logic [$clog2(N_COS) - 1 : 0] R_IDX;
                
                assign L_IDX = TBL[i][cur_phase][2*$clog2(N_COS) - 1 -: $clog2(N_COS)]; 
                assign R_IDX = TBL[i][cur_phase][  $clog2(N_COS) - 1 -: $clog2(N_COS)];
                
                always_comb begin      
                    mux_metrics  =  metrics_r [L_IDX];
                    mux_labels   =  labels_r  [L_IDX];
                    mux_metrics1 =  metrics1_r[R_IDX];
                    mux_labels1  =  labels1_r [R_IDX];  
                end
                
                unite_lists #(
                    .L         (L       ),
                    .N         (N       ),
                    .N1        (N1      ),
                    .METRIC_W  (METRIC_W),
                    .LABEL_W   (LABEL_W ),
                    .LABEL_W1  (LABEL_W1)
                )unite_lists (
                    .clk       (clk         ),
                    .i_valid   (valid       ),
                    .i_metrics (mux_metrics ),
                    .i_labels  (mux_labels  ),
                    .i_metrics1(mux_metrics1),
                    .i_labels1 (mux_labels1 ),
                    .o_metrics (u_metrics[i]),
                    .o_labels  (u_labels [i]),
                    .o_valid   (u_valid  [i])
                );
                
                for(genvar j = 0; j < N_U; j++) begin : DELAY
                    localparam DELAY = N_U - 1 - j;
                    
                    list_delay#(
                        .DELAY  (DELAY   ),
                        .N_OUT  (N_OUT   ),
                        .WIDTH  (METRIC_W)
                    )dl_metrics (
                        .clk    (clk),
                        .i_data (u_metrics  [i]   ),
                        .o_data (u_metrics_d[i][j])
                    );

                    list_delay#(
                        .DELAY  (DELAY ),
                        .N_OUT  (N_OUT ),
                        .WIDTH  (CONC_W)
                    )dl_labels  (
                        .clk    (clk             ),
                        .i_data (u_labels  [i]   ),
                        .o_data (u_labels_d[i][j])
                    );
                end
                
                always_ff @(posedge clk) begin
                    if(u_valid[i]) begin
                        if(out_cnt[i] == N_U - 1) begin
                            out_cnt[i] <= 0;
                        end else begin
                            out_cnt[i] <= out_cnt[i] + 1;
                        end
                    end else begin
                        out_cnt[i] <= 0;
                    end
                end
                
                assign c_valid[i] = (out_cnt[i] == N_U - 1 && u_valid[i]) ? 1'b1 : 1'b0;
                
                merge_tree #(
                    .NUM_LISTS (N_U     ),
                    .N_INPUTS  (N_OUT   ),
                    .METRIC_W  (METRIC_W),
                    .LABEL_W   (CONC_W  )
                )merge_tree (
                    .clk     (clk            ),
                    .i_valid (c_valid    [i] ),
                    .i_m     (u_metrics_d[i] ),
                    .i_l     (u_labels_d [i] ),
                    .o_m     (m_metrics  [i] ),
                    .o_l     (m_labels   [i] ),
                    .o_valid (m_valid    [i] )
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
            
        end else begin : FSM_NCOS
            logic                          valid_d;
            logic [    N*METRIC_W - 1 : 0] metrics_r  [0 : N_COS - 1];
            logic [     N*LABEL_W - 1 : 0] labels_r   [0 : N_COS - 1];                                                  
            logic [   N1*METRIC_W - 1 : 0] metrics1_r [0 : N_COS - 1];
            logic [   N1*LABEL_W1 - 1 : 0] labels1_r  [0 : N_COS - 1];
            
            logic [$clog2(N_COS) - 1 : 0] phase;
            logic [$clog2(N_COS) - 1 : 0] cur_phase;
            logic                         act;
            logic                         valid;
            
            logic [METRIC_W - 1 : 0] u_metrics [0 : N_U - 1][0 : N_OUT - 1];
            logic [  CONC_W - 1 : 0] u_labels  [0 : N_U - 1][0 : N_OUT - 1];
            logic [     N_U - 1 : 0] u_valid;   
            
            logic [METRIC_W - 1 : 0] m_metrics [0 : N_OUT - 1];
            logic [  CONC_W - 1 : 0] m_labels  [0 : N_OUT - 1];
            logic                    m_valid;      
            
            logic [METRIC_W - 1 : 0] out_m_buf [0 : N_COS - 1][0 : N_OUT - 1];
            logic [  CONC_W - 1 : 0] out_l_buf [0 : N_COS - 1][0 : N_OUT - 1];
            logic [$clog2(N_COS) - 1 : 0] out_cnt;
            logic                         c_valid;
            
            always_ff @(posedge clk) begin
                valid_d <= i_valid;
                if(i_valid) begin
                    metrics_r  <= i_metrics;
                    labels_r   <= i_labels;
                    metrics1_r <= i_metrics1;
                    labels1_r  <= i_labels1;
                end
            end
            
            logic  start;
            assign start = i_valid & ~valid_d;
            
            always_ff @(posedge clk) begin
                if(start) begin
                    phase <= 0;
                    act   <= 1;
                end else if(act) begin
                    if(phase == N_COS - 1) begin
                        phase <= 0;
                        act   <= 0;
                    end else begin
                        phase <= phase + 1;
                    end
                end
            end
                      
            assign cur_phase = phase;
            assign valid     = act;
            
            for(genvar j = 0; j < N_U; j++) begin : UNATION
                logic [ N*METRIC_W - 1 : 0] mux_metrics;
                logic [  N*LABEL_W - 1 : 0] mux_labels;
                logic [N1*METRIC_W - 1 : 0] mux_metrics1;
                logic [N1*LABEL_W1 - 1 : 0] mux_labels1;   
                
                logic [$clog2(N_COS) - 1 : 0] L_IDX; 
                logic [$clog2(N_COS) - 1 : 0] R_IDX;
                
                assign L_IDX = TBL[cur_phase][j][2*$clog2(N_COS) - 1 -: $clog2(N_COS)]; 
                assign R_IDX = TBL[cur_phase][j][  $clog2(N_COS) - 1 -: $clog2(N_COS)];
                
                always_comb begin      
                    mux_metrics  =  metrics_r [L_IDX];
                    mux_labels   =  labels_r  [L_IDX];
                    mux_metrics1 =  metrics1_r[R_IDX];
                    mux_labels1  =  labels1_r [R_IDX];  
                end
                
                unite_lists #(
                    .L         (L       ),
                    .N         (N       ),
                    .N1        (N1      ),
                    .METRIC_W  (METRIC_W),
                    .LABEL_W   (LABEL_W ),
                    .LABEL_W1  (LABEL_W1)
                )unite_lists (
                    .clk       (clk         ),
                    .i_valid   (valid       ),
                    .i_metrics (mux_metrics ),
                    .i_labels  (mux_labels  ),
                    .i_metrics1(mux_metrics1),
                    .i_labels1 (mux_labels1 ),
                    .o_metrics (u_metrics[j]),
                    .o_labels  (u_labels [j]),
                    .o_valid   (u_valid  [j])
                );
            end
            
            logic mt_v_in;
            assign mt_v_in = &u_valid;
            
            merge_tree #(
                .NUM_LISTS (N_U     ),
                .N_INPUTS  (N_OUT   ),
                .METRIC_W  (METRIC_W),
                .LABEL_W   (CONC_W  )
            )merge_tree (
                .clk     (clk      ),
                .i_valid (mt_v_in  ),
                .i_m     (u_metrics),
                .i_l     (u_labels ),
                .o_m     (m_metrics),
                .o_l     (m_labels ),
                .o_valid (m_valid  )
            );
            
            always_ff @(posedge clk) begin
                if(m_valid) begin
                    for(int j = 0; j < N_OUT; j++) begin
                        out_m_buf[out_cnt][j] <= m_metrics[j];
                        out_l_buf[out_cnt][j] <= m_labels[j];
                    end
                    if(out_cnt == N_COS - 1) begin
                        out_cnt <= 0;
                        c_valid <= 1'b1;
                    end else begin
                        out_cnt <= out_cnt + 1;
                        c_valid <= 1'b0;
                    end
                end else begin
                    out_cnt <= 0;
                    c_valid <= 1'b0;
                end
            end
            
            always_comb begin
                for(int i = 0; i < N_COS; i++) begin
                    for(int j = 0; j < N_OUT; j++) begin
                        o_metrics[i][(N_OUT*METRIC_W - 1) -j*METRIC_W -: METRIC_W] = out_m_buf[i][j];
                        o_labels [i][(  N_OUT*CONC_W - 1) -j*CONC_W   -: CONC_W  ] = out_l_buf[i][j];
                    end
                end   
            end
            
            assign o_valid = c_valid;
            
        end
    endgenerate
    
endmodule
