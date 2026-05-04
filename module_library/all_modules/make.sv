`timescale 1ns / 1ps

module make#(
    parameter LLR_W   = 6,
    parameter LABEL_W = 4,
    parameter N_COS   = 8,
    parameter N       = 2,
    parameter  logic [LABEL_W-1 : 0] DECOMP [0 : N_COS-1][0 : N-1] = '{
               {4'b0000, 4'b1111},
               {4'b1011, 4'b0100},
               {4'b1101, 4'b0010},
               {4'b0110, 4'b1001},
               {4'b1110, 4'b0001},
               {4'b0101, 4'b1010},
               {4'b0011, 4'b1100},
               {4'b1000, 4'b0111}},
    parameter                METRIC_W    = LLR_W + $clog2(LABEL_W),                                     
    localparam logic signed  MIN_LLR     = 1 << (LLR_W - 1),          
    localparam               LATENCY     = $clog2(LABEL_W) + 2
)(
    input  logic                               clk,
    input  logic                               i_valid,
    input  logic signed [     LLR_W - 1 : 0]   i_llr     [0 : LABEL_W - 1],
    
    output logic        [N*METRIC_W - 1 : 0]   o_metrics [0 : N_COS - 1  ],
    output logic        [ N*LABEL_W - 1 : 0]   o_labels  [0 : N_COS - 1  ],
    output logic                               o_valid
    );
    
    logic [  LATENCY - 1 : 0] valid_d;  
    // signals for calculating metrics
    logic [    LLR_W - 1 : 0] abs_llr   [0 : LABEL_W - 1];
    logic [  LABEL_W - 1 : 0] mismath   [0 : N_COS - 1  ][0 : N - 1];
    logic [    LLR_W - 1 : 0] summand   [0 : N_COS - 1  ][0 : N - 1][LABEL_W - 1 : 0];
    logic [ METRIC_W - 1 : 0] sum       [0 : N_COS - 1  ][0 : N - 1]; 
    logic                     m_valid;
    // table_sort output
    logic [ METRIC_W - 1 : 0] s_metrics [0 : N_COS - 1  ][0 : N - 1];
    logic [  LABEL_W - 1 : 0] s_labels  [0 : N_COS - 1  ][0 : N - 1];
    logic                     s_valid;
    
    always_ff @(posedge clk) begin
        valid_d<=  {valid_d[LATENCY - 2 : 0], i_valid}; 
    end
    
    always_ff @(posedge clk) begin
        for(int i = 0; i < LABEL_W; i++) begin
            if(i_llr[i] == MIN_LLR) begin
                abs_llr[i] <= $unsigned(MIN_LLR - 1); 
            end else if(i_llr[i][LLR_W-1] == 1'b1) begin
                abs_llr[i] <= $unsigned(-i_llr[i]);
            end else begin
                abs_llr[i] <= $unsigned(i_llr[i]);
            end
        end
    end
    
    always_ff @(posedge clk) begin
        for(int c = 0; c < N_COS; c++) begin
            for(int w = 0; w < N; w++) begin
                for(int b = 0; b < LABEL_W; b++) begin
                    mismath[c][w][b] <= DECOMP[c][w][LABEL_W - 1 - b] ^ i_llr[b][LLR_W - 1];   
                end
            end
        end 
    end
    
    always_comb begin
        for(int c = 0; c < N_COS; c++) begin
            for(int w = 0; w < N; w++) begin
                for(int b = 0; b < LABEL_W; b++) begin
                    summand[c][w][b] = (mismath[c][w][b]) ? abs_llr[b] : '0;   
                end
            end
        end 
    end
    
    generate 
        for(genvar c = 0; c < N_COS; c++) begin : coset
            for(genvar w = 0; w < N; w++) begin : codeword
                n_adder#(
                    .N  (LABEL_W ),
                    .I_W(LLR_W   ),
                    .O_W(METRIC_W)
                )n_adder ( 
                    .clk   (clk          ),
                    .i_data(summand[c][w]),
                    .o_data(sum[c][w]    )
                ); 
            end    
        end
    endgenerate
    
    assign m_valid = valid_d[LATENCY-1];
    
    table_sort #(
        .METRIC_W(METRIC_W),
        .LABEL_W (LABEL_W ),
        .N_COS   (N_COS   ),
        .N       (N       )
    )dut (
        .clk      (clk      ),
        .i_valid  (m_valid  ),
        .i_metrics(sum      ),
        .i_labels (DECOMP   ),
        .o_metrics(s_metrics),
        .o_labels (s_labels ),
        .o_valid  (s_valid  )
    );         
        
    always_comb begin
        for(int c = 0; c < N_COS; c++) begin 
            for(int w = 0; w < N; w++) begin 
                o_metrics[c][N*METRIC_W - 1 - w*METRIC_W -: METRIC_W] = s_metrics[c][w];
                o_labels [c][ N*LABEL_W - 1 - w*LABEL_W  -: LABEL_W ] = s_labels [c][w];
            end    
        end
    end 
    
    assign o_valid = s_valid;
     
endmodule
