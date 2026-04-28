
// Total Latency, cycles: 7
module sum_select8#(
    parameter METRIC_W = 10,
    parameter LABEL_W  = 16,
    parameter LABEL_W1 = 16,                 
    parameter CONC_W   = LABEL_W + LABEL_W1
)(
    input  logic                       clk,
    input  logic                       i_valid,
    // first list
    input  logic [8*METRIC_W - 1 : 0] i_metrics,
    input  logic [ 8*LABEL_W - 1 : 0] i_labels,
    // second list
    input  logic [8*METRIC_W - 1 : 0] i_metrics1,
    input  logic [8*LABEL_W1 - 1 : 0] i_labels1,
    // united list
    output logic [  METRIC_W - 1 : 0] o_metrics [0 : 7],    
    output logic [    CONC_W - 1 : 0] o_labels  [0 : 7],
    
    output logic                       o_valid
    );
    
    logic [6 : 0] valid_d;
    
    logic [4*METRIC_W - 1 : 0] metrics_r;  
    logic [ 4*LABEL_W - 1 : 0] labels_r;   
                                 
    logic [4*METRIC_W - 1 : 0] metrics1_r; 
    logic [4*LABEL_W1 - 1 : 0] labels1_r;  
    
    logic [  METRIC_W - 1 : 0] metrics [0 : 7];
    logic [    CONC_W - 1 : 0] labels  [0 : 7];
    
    always_ff @(posedge clk) begin
        metrics_r <= i_metrics[8*METRIC_W - 1 -: 4*METRIC_W];
        labels_r  <= i_labels [ 8*LABEL_W - 1 -: 4*LABEL_W ];
       
        metrics1_r <= i_metrics1[8*METRIC_W - 1 -: 4*METRIC_W];
        labels1_r  <= i_labels1 [8*LABEL_W1 - 1 -: 4*LABEL_W1];
        
        valid_d    <= {valid_d[5 : 0], i_valid};
    end
    
    sum_select_8 #( 
        .METRIC_W(METRIC_W), 
        .LABEL_W (LABEL_W ), 
        .LABEL_W1(LABEL_W1)
    )SS_00 (
        .clk       (clk    ),
        .i_metrics (metrics_r),
        .i_labels  (labels_r),
        .i_metrics1(metrics1_r),
        .i_labels1 (labels1_r),
        .o_metrics (metrics),
        .o_labels  (labels)
    );
    
    always_comb begin
        for(int i = 0; i < 8; i++) begin
            o_metrics[i] = metrics[i];
            o_labels[i]  = labels[i];
        end
    end
    
    assign o_valid = valid_d[6];
    
    endmodule