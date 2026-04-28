`timescale 1ns / 1ps

module unite_lists#(
    parameter L        = 7,
    parameter N1       = 7,
    parameter N2       = 7,
    parameter METRIC_W = 10,
    parameter LABEL_W  = 16,
    parameter LABEL_W1 = 16,  
    parameter N_OUT    = (N1 == L & N2 == L) ? ((L < 4) ? 4 : (L < 8) ? 8 : (L < 16) ? 16 : 8) : 10, // вместо 10 логика на случае не списочные              
    parameter CONC_W   = LABEL_W + LABEL_W1
)(
    input  logic                       clk,
    input  logic                       i_valid,
    // first list
    input  logic [N1*METRIC_W - 1 : 0] i_metrics,
    input  logic [ N1*LABEL_W - 1 : 0] i_labels,
    // second list
    input  logic [N2*METRIC_W - 1 : 0] i_metrics1,
    input  logic [N2*LABEL_W1 - 1 : 0] i_labels1,
    // united list
    output logic [   METRIC_W - 1 : 0] o_metrics [0 : 15],    
    output logic [     CONC_W - 1 : 0] o_labels  [0 : 15],
    
    output logic                       o_valid
    );
    
    localparam logic [METRIC_W - 1 : 0] MAX_METRIC    = '{METRIC_W{1'b1}};
    localparam logic [ LABEL_W - 1 : 0] L_PAD         = '{ LABEL_W{1'b0}};
    localparam logic [LABEL_W1 - 1 : 0] L1_PAD        = '{LABEL_W1{1'b0}};
    localparam logic [  CONC_W - 1 : 0] CONC_PAD      = '{  CONC_W{1'b0}};
    
    // выход будет длины 4 8 или 16, в случае sum_select_12 придется дополнить до 16, чтобы merge сделать
    generate
        if(N1 >= L && N2 >= L) begin
            localparam int N_BLOCKS  = (L + 3)/4;
            localparam int N         = N_BLOCKS*4;          
                
            logic [N*METRIC_W - 1 : 0] metrics; 
            logic [ N*LABEL_W - 1 : 0] labels;  
                                         
            logic [N*METRIC_W - 1 : 0] metrics1;
            logic [N*LABEL_W1 - 1 : 0] labels1; 
            
            logic [  METRIC_W - 1 : 0] m_ss [0 : N - 1];
            logic [    CONC_W - 1 : 0] l_ss [0 : N - 1];
            
            logic                      valid_ss;
            
            // Latency, clk: 1 = 1
            always_ff @(posedge clk) begin
                for(int i = 0; i < N; i++) begin
                    if(i < L) begin
                        metrics [(N*METRIC_W - 1) -i*METRIC_W -: METRIC_W] <= i_metrics [(N1*METRIC_W - 1) -i*METRIC_W -: METRIC_W];
                        labels  [  (N*LABEL_W - 1) -i*LABEL_W -: LABEL_W ] <= i_labels  [  (N1*LABEL_W - 1) -i*LABEL_W -: LABEL_W ];
                                               
                        metrics1[(N*METRIC_W - 1) -i*METRIC_W -: METRIC_W] <= i_metrics1[(N2*METRIC_W - 1) -i*METRIC_W -: METRIC_W];
                        labels1 [  (N*LABEL_W - 1) -i*LABEL_W -: LABEL_W ] <= i_labels1 [  (N2*LABEL_W - 1) -i*LABEL_W -: LABEL_W ];
                    end else begin
                        metrics [(N*METRIC_W - 1) -i*METRIC_W -: METRIC_W] <= MAX_METRIC;
                        labels  [  (N*LABEL_W - 1) -i*LABEL_W -: LABEL_W ] <= L_PAD;
                                                                            
                        metrics1[(N*METRIC_W - 1) -i*METRIC_W -: METRIC_W] <= MAX_METRIC;
                        labels1 [  (N*LABEL_W - 1) -i*LABEL_W -: LABEL_W ] <= L1_PAD;
                    end
                end
            end  
                
            case(N_BLOCKS)
                1: begin                 
                    logic [2 : 0] valid_d;
                    
                    always_ff @(posedge clk) begin
                        valid_d = {valid_d[1 : 0], i_valid};
                    end
                
                    sum_select #(
                        .METRIC_W(METRIC_W), 
                        .LABEL_W (LABEL_W ), 
                        .LABEL_W1(LABEL_W )
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
                        .i_valid    (i_valid ),
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
                        .i_valid    (i_valid ),
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
                        .i_valid    (i_valid ),
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
                for(int i = 0; i < N_OUT; i++) begin
                    if(i < N) begin
                        o_metrics[i] = m_ss[i];
                        o_labels [i] = l_ss[i];
                    end else begin
                        o_metrics[i] = MAX_METRIC;
                        o_labels [i] = CONC_PAD;
                    end
                end
            end
            
            assign o_valid = valid_ss;
        end
    endgenerate
    
    
    
endmodule
