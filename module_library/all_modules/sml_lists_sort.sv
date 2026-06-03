`timescale 1ns / 1ps

// Latency, cycles: (N < 3) ? 1 : (N < 5) ? : 2 : (N < 9) ? 6 : bitonic latency
module sml_list_sort #(
    parameter METRIC_W = 10,
    parameter LABEL_W  = 8,
    parameter N        = 8
)(
    input  logic                     clk,
    input  logic                     i_valid,
    input  logic [METRIC_W - 1 : 0]  i_metrics [0 : N - 1],
    input  logic [ LABEL_W - 1 : 0]  i_labels  [0 : N - 1],
    output logic                     o_valid,
    output logic [METRIC_W - 1 : 0]  o_metrics [0 : N - 1],
    output logic [ LABEL_W - 1 : 0]  o_labels  [0 : N - 1]
);

    localparam int N_PAD = (N <= 2) ? 2 : (N <= 4) ? 4 : (N <= 8) ? 8 : (N <= 16) ? 16 : 32;
    localparam logic [METRIC_W - 1 : 0]  M_PADDING = {METRIC_W{1'b1}};
    localparam logic [ LABEL_W - 1 : 0]  L_PADDING = {LABEL_W{1'b0}};

    logic [METRIC_W - 1 : 0] in_m [0 : N_PAD - 1];
    logic [ LABEL_W - 1 : 0]  in_l [0 : N_PAD - 1];

    always_comb begin
        for (int i = 0; i < N_PAD; i++) begin
            if (i < N) begin
                in_m[i] = i_metrics[i];
                in_l[i] = i_labels[i];
            end else begin
                in_m[i] = M_PADDING;
                in_l[i] = L_PADDING;
            end
        end
    end

    logic                     sort_valid;

    generate
        if (N_PAD == 2) begin : GEN2
            logic [METRIC_W - 1 : 0]  out_m [0 : N_PAD - 1];
            logic [ LABEL_W - 1 : 0]  out_l [0 : N_PAD - 1];
            
            sort_2 #(
                .METRIC_W (METRIC_W),
                .LABEL_W  (LABEL_W)
            ) u_sort (
                .clk     (clk),
                .i_valid (i_valid),
                .i_m     (in_m),
                .i_l     (in_l),
                .o_valid (sort_valid),
                .o_m     (out_m),
                .o_l     (out_l)
            );
            
            assign o_valid = sort_valid;

            always_comb begin
                for (int i = 0; i < N; i++) begin
                    o_metrics[i] = out_m[i];
                    o_labels[i]  = out_l[i];
                end
            end
        end else if (N_PAD == 4) begin : GEN4
            logic [METRIC_W - 1 : 0]  out_m [0 : N_PAD - 1];
            logic [ LABEL_W - 1 : 0]  out_l [0 : N_PAD - 1];
            
            sort_4 #(
                .METRIC_W (METRIC_W),
                .LABEL_W  (LABEL_W)
            ) u_sort (
                .clk     (clk),
                .i_valid (i_valid),
                .i_m     (in_m),
                .i_l     (in_l),
                .o_valid (sort_valid),
                .o_m     (out_m),
                .o_l     (out_l)
            );
            
            assign o_valid = sort_valid;

            always_comb begin
                for (int i = 0; i < N; i++) begin
                    o_metrics[i] = out_m[i];
                    o_labels[i]  = out_l[i];
                end
            end
        end else if (N_PAD == 8) begin : GEN8
            logic [METRIC_W - 1 : 0]  out_m [0 : N_PAD - 1];
            logic [ LABEL_W - 1 : 0]  out_l [0 : N_PAD - 1];
            
            sort_8 #(
                .METRIC_W (METRIC_W),
                .LABEL_W  (LABEL_W)
            ) u_sort (
                .clk     (clk),
                .i_valid (i_valid),
                .i_m     (in_m),
                .i_l     (in_l),
                .o_valid (sort_valid),
                .o_m     (out_m),
                .o_l     (out_l)
            );
            
            assign o_valid = sort_valid;

            always_comb begin
                for (int i = 0; i < N; i++) begin
                    o_metrics[i] = out_m[i];
                    o_labels[i]  = out_l[i];
                end
            end
        end else begin
            logic [N_PAD*METRIC_W - 1 : 0]  in_mp;
            logic [ N_PAD*LABEL_W - 1 : 0]  in_lp;
            
            logic [N_PAD*METRIC_W - 1 : 0]  out_mp;
            logic [ N_PAD*LABEL_W - 1 : 0]  out_lp;
            
            always_comb begin
                for (int i = 0; i < N_PAD; i++) begin
                    in_mp[N_PAD*METRIC_W - 1 - i*METRIC_W -: METRIC_W] = in_m[i];
                    in_lp[  N_PAD*LABEL_W - 1 - i*LABEL_W -: LABEL_W ] = in_l[i];
                end
            end
            
            bitonic_sort_fp #(
                .METRIC_W (METRIC_W),
                .LABEL_W  (LABEL_W ),
                .N        (N_PAD   )
            ) sort_inst (
                .clk       (clk       ),
                .i_valid   (i_valid   ),
                .i_metrics (in_mp     ),
                .i_labels  (in_lp     ),
                .o_valid   (sort_valid),
                .o_metrics (out_mp    ),
                .o_labels  (out_lp    )
            );
            
            assign o_valid = sort_valid;

            always_comb begin
                for (int i = 0; i < N; i++) begin
                    o_metrics[i] = out_mp[N_PAD*METRIC_W - 1 - i*METRIC_W -: METRIC_W];
                    o_labels [i] = out_lp[  N_PAD*LABEL_W - 1 - i*LABEL_W -: LABEL_W ];
                end
            end
        end
    endgenerate

endmodule