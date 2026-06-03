// Total Latency: 2 + NUM_STEPS cycles
`timescale 1ns / 1ps

module bitonic_sort_fp#(
    parameter                   METRIC_W   = 13,
    parameter                   LABEL_W    = 16,
    parameter                   N          = 8,
    localparam                  N_EXT      = 2**$clog2(N),
    localparam                  IDX_W      = $clog2(N_EXT),
    localparam                  NUM_STAGES = $clog2(N_EXT),
    localparam                  NUM_STEPS  = NUM_STAGES*(NUM_STAGES+1)/2,
    localparam [METRIC_W-1 : 0] M_PADDING  = {METRIC_W{1'b1}},
    localparam [ LABEL_W-1 : 0] L_PADDING  = {LABEL_W{1'b0}}
)(
    input  logic                     clk,
    input  logic                     i_valid,
    input  logic [N*METRIC_W -1 : 0] i_metrics,
    input  logic [ N*LABEL_W -1 : 0] i_labels,
    output logic                     o_valid,
    output logic [N*METRIC_W -1 : 0] o_metrics,
    output logic [ N*LABEL_W -1 : 0] o_labels   
);
            
    logic [ NUM_STEPS : 0] pipe_valid;
    logic [METRIC_W-1 : 0] pipe_metrics [0 : NUM_STEPS][0 : N_EXT-1];
    logic [  IDX_W-1 : 0]  pipe_indices [0 : NUM_STEPS][0 : N_EXT-1];
    
    (* srl_style = "reg" *) 
    logic [ LABEL_W-1 : 0] pipe_labels_raw [0 : NUM_STEPS][0 : N_EXT-1];
    
    always_ff @(posedge clk) begin
        pipe_valid[0] <= i_valid;
        for(int i = 0; i < N_EXT; i++) begin
            pipe_indices[0][i] <= i[IDX_W-1:0];
            if (i < N) begin
                pipe_metrics[0][i]    <= i_metrics[(i+1)*METRIC_W-1 -: METRIC_W];
                pipe_labels_raw[0][i] <= i_labels[(i+1)*LABEL_W-1 -: LABEL_W];
            end else begin
                pipe_metrics[0][i]    <= M_PADDING;
                pipe_labels_raw[0][i] <= L_PADDING;
            end
        end
    end
    
    generate 
        for(genvar s = 1; s <= NUM_STAGES; s++) begin 
            for(genvar hop = s-1; hop >= 0; hop--) begin
                localparam int SIZE      = 1 << s;              
                localparam int STEP      = 1 << hop;            
                localparam int PIPE_STEP = (s-1)*s/2+(s-1-hop); 
                
                always_ff @(posedge clk) begin
                    pipe_valid[PIPE_STEP+1]      <= pipe_valid[PIPE_STEP];
                    pipe_labels_raw[PIPE_STEP+1] <= pipe_labels_raw[PIPE_STEP];
                    
                    for(int n = 0; n < N_EXT; n++) begin
                        int pair = n ^ STEP; 
                        if(n < pair) begin  
                            if((n & SIZE) == 0) begin 
                                if(pipe_metrics[PIPE_STEP][n] > pipe_metrics[PIPE_STEP][pair]) begin 
                                    pipe_metrics[PIPE_STEP+1][n]    <= pipe_metrics[PIPE_STEP][pair];   
                                    pipe_indices [PIPE_STEP+1][n]   <= pipe_indices [PIPE_STEP][pair]; 
                                    pipe_metrics[PIPE_STEP+1][pair] <= pipe_metrics[PIPE_STEP][n];   
                                    pipe_indices [PIPE_STEP+1][pair] <= pipe_indices [PIPE_STEP][n];  
                                end else begin 
                                    pipe_metrics[PIPE_STEP+1][n]    <= pipe_metrics[PIPE_STEP][n];   
                                    pipe_indices [PIPE_STEP+1][n]   <= pipe_indices [PIPE_STEP][n]; 
                                    pipe_metrics[PIPE_STEP+1][pair] <= pipe_metrics[PIPE_STEP][pair];   
                                    pipe_indices [PIPE_STEP+1][pair] <= pipe_indices [PIPE_STEP][pair];     
                                end
                            end else begin
                                if(pipe_metrics[PIPE_STEP][n] < pipe_metrics[PIPE_STEP][pair]) begin 
                                    pipe_metrics[PIPE_STEP+1][n]    <= pipe_metrics[PIPE_STEP][pair];   
                                    pipe_indices [PIPE_STEP+1][n]   <= pipe_indices [PIPE_STEP][pair]; 
                                    pipe_metrics[PIPE_STEP+1][pair] <= pipe_metrics[PIPE_STEP][n];   
                                    pipe_indices [PIPE_STEP+1][pair] <= pipe_indices [PIPE_STEP][n];  
                                end else begin 
                                    pipe_metrics[PIPE_STEP+1][n]    <= pipe_metrics[PIPE_STEP][n];   
                                    pipe_indices [PIPE_STEP+1][n]   <= pipe_indices [PIPE_STEP][n]; 
                                    pipe_metrics[PIPE_STEP+1][pair] <= pipe_metrics[PIPE_STEP][pair];   
                                    pipe_indices [PIPE_STEP+1][pair] <= pipe_indices [PIPE_STEP][pair];     
                                end    
                            end
                        end
                    end
                end
            end
        end
    endgenerate
    
    always_comb begin
        o_valid = pipe_valid[NUM_STEPS];
        for(int i = 0; i < N; i++) begin
            o_metrics[(i+1)*METRIC_W-1 -: METRIC_W] = pipe_metrics[NUM_STEPS][N-1-i];
            o_labels [(i+1)*LABEL_W-1 -: LABEL_W ]  = pipe_labels_raw[NUM_STEPS][pipe_indices[NUM_STEPS][N-1-i]];
        end
    end
   
endmodule