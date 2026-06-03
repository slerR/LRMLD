`timescale 1ns / 1ps

module unite_lists#(
    parameter  L           = 7,
    parameter  N           = 7,
    parameter  N1          = 7,
    parameter  METRIC_W    = 10,
    parameter  LABEL_W     = 16,
    parameter  LABEL_W1    = 16,  
    parameter  CONC_W      = LABEL_W + LABEL_W1,
    localparam B_N  = (L <= 4) ? 2 : (L <= 6) ? 2 : (L <= 9) ? 3 : (L <= 12) ? 3 : 4,
    localparam B_N1 = (L <= 4) ? 2 : (L <= 6) ? 3 : (L <= 9) ? 3 : (L <= 12) ? 4 : 4,
    localparam N_LIM  = (N * N1 < L) ? N  : (N < B_N) ? N : (N1 < B_N1) ? ((L + N1 - 1) / N1) : B_N,
    localparam N1_LIM = (N * N1 < L) ? N1 : (N1 < B_N1) ? N1 : (N < B_N)  ? ((L +  N - 1) / N)  : B_N1,
    localparam TOTAL_COMBO = N_LIM * N1_LIM,
    localparam L_OUT       = (TOTAL_COMBO < L) ? TOTAL_COMBO : L,    
    parameter  N_OUT       = (N >= L & N1 >= L) ? L : L_OUT              
)(
    input  logic                       clk,
    input  logic                       i_valid,
    // first list
    input  logic [N*METRIC_W - 1 : 0] i_metrics,
    input  logic [ N*LABEL_W - 1 : 0] i_labels,
    // second list
    input  logic [N1*METRIC_W - 1 : 0] i_metrics1,
    input  logic [N1*LABEL_W1 - 1 : 0] i_labels1,
    // united list
    output logic [   METRIC_W - 1 : 0] o_metrics [0 : N_OUT - 1],    
    output logic [     CONC_W - 1 : 0] o_labels  [0 : N_OUT - 1],
    
    output logic                       o_valid
    );
    
    localparam logic [METRIC_W - 1 : 0] MAX_METRIC    = '{METRIC_W{1'b1}};
    localparam logic [ LABEL_W - 1 : 0] L_PAD         = '{ LABEL_W{1'b0}};
    localparam logic [LABEL_W1 - 1 : 0] L1_PAD        = '{LABEL_W1{1'b0}};
        
    generate
        if(N >= L && N1 >= L) begin
            localparam int N_BLOCKS  = (L + 3)/4;
            localparam int N_PADDED  = N_BLOCKS*4;          
                
            logic [N_PADDED*METRIC_W - 1 : 0] metrics; 
            logic [ N_PADDED*LABEL_W - 1 : 0] labels;  
                                         
            logic [N_PADDED*METRIC_W - 1 : 0] metrics1;
            logic [N_PADDED*LABEL_W1 - 1 : 0] labels1; 
            
            logic [  METRIC_W - 1 : 0] m_ss [0 : N_PADDED - 1];
            logic [    CONC_W - 1 : 0] l_ss [0 : N_PADDED - 1];
            
            logic                      valid;
            logic                      valid_ss;
            
            // Latency, clk: 1 = 1
            always_ff @(posedge clk) begin
                valid <= i_valid;
                for(int i = 0; i < N_PADDED; i++) begin
                    if(i < L) begin
                        metrics [(N_PADDED*METRIC_W - 1) -i*METRIC_W -: METRIC_W] <= i_metrics [(N*METRIC_W - 1) -i*METRIC_W -: METRIC_W];
                        labels  [  (N_PADDED*LABEL_W - 1) -i*LABEL_W -: LABEL_W ] <= i_labels  [  (N*LABEL_W - 1) -i*LABEL_W -: LABEL_W ];
                                               
                        metrics1[(N_PADDED*METRIC_W - 1) -i*METRIC_W -: METRIC_W] <= i_metrics1[(N1*METRIC_W - 1) -i*METRIC_W -: METRIC_W];
                        labels1 [  (N_PADDED*LABEL_W1 - 1) -i*LABEL_W1 -: LABEL_W1 ] <= i_labels1 [  (N1*LABEL_W1 - 1) -i*LABEL_W1 -: LABEL_W1 ];
                    end else begin
                        metrics [(N_PADDED*METRIC_W - 1) -i*METRIC_W -: METRIC_W] <= MAX_METRIC;
                        labels  [  (N_PADDED*LABEL_W - 1) -i*LABEL_W -: LABEL_W ] <= L_PAD;
                                                                            
                        metrics1[(N_PADDED*METRIC_W - 1) -i*METRIC_W -: METRIC_W] <= MAX_METRIC;
                        labels1 [  (N_PADDED*LABEL_W1 - 1) -i*LABEL_W1 -: LABEL_W1 ] <= L1_PAD;
                    end
                end
            end  
                
            case(N_BLOCKS)
                1: begin                 
                    logic [2 : 0] valid_d;
                    
                    always_ff @(posedge clk) begin
                        valid_d = {valid_d[1 : 0], valid};
                    end
                
                    sum_select #(
                        .METRIC_W(METRIC_W), 
                        .LABEL_W (LABEL_W ), 
                        .LABEL_W1(LABEL_W1 )
                    )dut (
                        .clk       (clk     ),
                        .i_metrics (metrics ),
                        .i_labels  (labels  ),
                        .i_metrics1(metrics1),
                        .i_labels1 (labels1 ),
                        .o_metrics (m_ss    ),
                        .o_labels  (l_ss    )
                    );    
                    
                    assign valid_ss = valid_d[2];  
                end
                2: begin
                    sum_select8 #(
                        .METRIC_W (METRIC_W),
                        .LABEL_W  (LABEL_W ),
                        .LABEL_W1 (LABEL_W1)
                    )dut (
                        .clk        (clk     ),
                        .i_valid    (valid   ),
                        .i_metrics  (metrics ),
                        .i_labels   (labels  ),
                        .i_metrics1 (metrics1),
                        .i_labels1  (labels1 ),
                        .o_metrics  (m_ss    ),
                        .o_labels   (l_ss    ),
                        .o_valid    (valid_ss)
                    );               
                end
                3: begin
                    sum_select_12_bm_ir #(
                        .METRIC_W (METRIC_W),
                        .LABEL_W  (LABEL_W ),
                        .LABEL_W1 (LABEL_W1)
                    )dut (
                        .clk        (clk     ),
                        .i_valid    (valid   ),
                        .i_metrics  (metrics ),
                        .i_labels   (labels  ),
                        .i_metrics1 (metrics1),
                        .i_labels1  (labels1 ),
                        .o_metrics  (m_ss    ),
                        .o_labels   (l_ss    ),
                        .o_valid    (valid_ss)
                    );
                end
                4: begin
                    sum_select_16_bm_ir #(
                        .METRIC_W (METRIC_W),
                        .LABEL_W  (LABEL_W ),
                        .LABEL_W1 (LABEL_W1)
                    )dut (
                        .clk        (clk     ),
                        .i_valid    (valid   ),
                        .i_metrics  (metrics ),
                        .i_labels   (labels  ),
                        .i_metrics1 (metrics1),
                        .i_labels1  (labels1 ),
                        .o_metrics  (m_ss    ),
                        .o_labels   (l_ss    ),
                        .o_valid    (valid_ss)
                    );              
                end
            endcase 
            
            always_comb begin
                for(int i = 0; i < L; i++) begin
                    o_metrics[i] = m_ss[i];
                    o_labels [i] = l_ss[i];
                end
            end
            
            assign o_valid = valid_ss;
            
        end else begin 
            full_sum_lists #(
                .L       (L       ), 
                .N       (N       ), 
                .N1      (N1      ),
                .METRIC_W(METRIC_W), 
                .LABEL_W (LABEL_W ), 
                .LABEL_W1(LABEL_W1),
                .L_OUT   (L_OUT   )
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
        end      
    endgenerate
       
endmodule
