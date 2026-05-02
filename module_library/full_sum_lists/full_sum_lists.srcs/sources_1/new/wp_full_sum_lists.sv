`timescale 1ns / 1ps

module wp_full_sum_lists #(
parameter  L          = 16,
parameter  N          = 12,
parameter  N1         = 12,
parameter  METRIC_W   = 10,
parameter  LABEL_W    = 16,
parameter  LABEL_W1   = 16,
localparam N_MAX      = (N > N1) ? N : N1,
localparam N_LIM      = (N * N1 < L) ? N  : ( (L <= 4) ? 2 : (L <= 6) ? 2 : (L <= 9) ? 3 : (L <= 12) ? 3 : 4 ),
localparam N1_LIM     = (N * N1 < L) ? N1 : ( (L <= 4) ? 2 : (L <= 6) ? 3 : (L <= 9) ? 3 : (L <= 12) ? 4 : 4 ),
localparam TOTAL_COMBO = N_LIM * N1_LIM,
localparam L_OUT      = (TOTAL_COMBO < L) ? TOTAL_COMBO : L,
localparam CONC_W     = LABEL_W + LABEL_W1
)(
input  logic                   clk,
input  logic                   i_valid,
input  logic [METRIC_W - 1 : 0] i_metric,
input  logic [ LABEL_W - 1 : 0] i_label,
input  logic [METRIC_W - 1 : 0] i_metric1,
input  logic [LABEL_W1 - 1 : 0] i_label1,
output logic                   o_valid,
output logic [METRIC_W - 1 : 0] o_metric,
output logic [  CONC_W - 1 : 0] o_label
);

logic [$clog2(N_MAX) : 0] cnt_in = 0;

logic [N * METRIC_W - 1 : 0]  buf_metrics0;
logic [N * LABEL_W - 1 : 0]   buf_labels0;
logic [N1 * METRIC_W - 1 : 0] buf_metrics1;
logic [N1 * LABEL_W1 - 1 : 0] buf_labels1;

logic start_processing;

always_ff @(posedge clk) begin
    if (i_valid) begin
        if (cnt_in < N) begin
            buf_metrics0[(N - 1 - cnt_in) * METRIC_W +: METRIC_W] <= i_metric;
            buf_labels0 [(N - 1 - cnt_in) * LABEL_W  +: LABEL_W ] <= i_label;
        end
        if (cnt_in < N1) begin
            buf_metrics1[(N1 - 1 - cnt_in) * METRIC_W +: METRIC_W] <= i_metric1;
            buf_labels1 [(N1 - 1 - cnt_in) * LABEL_W1 +: LABEL_W1] <= i_label1;
        end
    end
end

always_ff @(posedge clk) begin
    if (i_valid) begin
        if (cnt_in == N_MAX - 1)
            cnt_in <= 0;
        else
            cnt_in <= cnt_in + 1;
    end
end

assign start_processing = (i_valid && cnt_in == N_MAX - 1);

logic [METRIC_W - 1 : 0] core_metrics [0 : L_OUT - 1];
logic [  CONC_W - 1 : 0] core_labels  [0 : L_OUT - 1];
logic                    core_valid;

full_sum_lists #(
    .L(L), 
    .N(N), 
    .N1(N1),
    .METRIC_W(METRIC_W), 
    .LABEL_W(LABEL_W), 
    .LABEL_W1(LABEL_W1),
    .L_OUT(L_OUT)
) dut (
    .clk(clk),
    .i_valid(start_processing),
    .i_metrics(buf_metrics0),
    .i_labels(buf_labels0),
    .i_metrics1(buf_metrics1),
    .i_labels1(buf_labels1),
    .o_metrics(core_metrics),
    .o_labels(core_labels),
    .o_valid(core_valid)
);

logic [L_OUT * METRIC_W - 1 : 0] out_metrics_reg;
logic [L_OUT * CONC_W - 1 : 0]   out_labels_reg;
logic [$clog2(L_OUT) : 0]        cnt_out = 0;
logic                            is_busy = 0;

always_ff @(posedge clk) begin
    if (core_valid) begin
        for (int i = 0; i < L_OUT; i++) begin
            out_metrics_reg[(L_OUT - 1 - i) * METRIC_W +: METRIC_W] <= core_metrics[i];
            out_labels_reg [(L_OUT - 1 - i) * CONC_W   +: CONC_W  ] <= core_labels[i];
        end
        is_busy <= 1'b1;
        cnt_out <= 0;
    end else if (is_busy) begin
        if (cnt_out == L_OUT - 1) begin
            is_busy <= 1'b0;
            cnt_out <= 0;
        end else begin
            cnt_out <= cnt_out + 1;
        end
    end
end

always_comb begin
    o_metric = out_metrics_reg[(L_OUT * METRIC_W - 1) - cnt_out * METRIC_W -: METRIC_W];
    o_label  = out_labels_reg [(L_OUT * CONC_W   - 1) - cnt_out * CONC_W   -: CONC_W];
end

always_ff @(posedge clk) begin
    o_valid <= is_busy;
end
endmodule