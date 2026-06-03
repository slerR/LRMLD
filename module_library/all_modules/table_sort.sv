`timescale 1ns / 1ps

// Latency, cycles: (N < 3) ? 1 : (N < 5) ? : 2 : (N < 9) ? : 6 : bitonic latecy
module table_sort#(
    parameter METRIC_W = 10,
    parameter LABEL_W  = 4,
    parameter N_COS    = 8,
    parameter N        = 8
)(
    input  logic                     clk,
    input  logic                     i_valid,
    
    input  logic [METRIC_W - 1 : 0]  i_metrics [0 : N_COS - 1][0 : N - 1],
    input  logic [ LABEL_W - 1 : 0]  i_labels  [0 : N_COS - 1][0 : N - 1],
    
    output logic [METRIC_W - 1 : 0]  o_metrics [0 : N_COS - 1][0 : N - 1],
    output logic [ LABEL_W - 1 : 0]  o_labels  [0 : N_COS - 1][0 : N - 1],
    
    output logic                     o_valid
);

    logic [METRIC_W - 1 : 0]  s_metrics [0 : N_COS - 1][0 : N - 1];
    logic [ LABEL_W - 1 : 0]  s_labels  [0 : N_COS - 1][0 : N - 1];
    logic [   N_COS - 1 : 0]  s_valid;

    generate     
        for(genvar i = 0; i < N_COS; i++) begin
            sml_list_sort#(
                .METRIC_W(METRIC_W),
                .LABEL_W (LABEL_W ),
                .N       (N       )
            )sort (
                .clk      (clk         ),
                .i_valid  (i_valid     ),
                .i_metrics(i_metrics[i]),
                .i_labels (i_labels [i]),
                .o_metrics(s_metrics[i]),
                .o_labels (s_labels [i]),
                .o_valid  (s_valid  [i])
            );
        end
    endgenerate
    
    always_comb begin
        for(int i = 0; i < N_COS; i++) begin
            o_metrics[i] = s_metrics[i];
            o_labels [i] = s_labels [i];
        end
    end
    
    assign o_valid = &s_valid;
        
endmodule
