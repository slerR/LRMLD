module wp_simple_SS #(
    parameter  METRIC_W = 10,
    parameter  LABEL_W  = 32,
    parameter  LABEL_W1 = 32,
    localparam SUM_W    = METRIC_W + 1,
    localparam CONC_W   = LABEL_W + LABEL_W1
)(
    input  logic                     clk,
    input  logic                     i_valid,
    input  logic [METRIC_W-1:0]      i_metric,
    input  logic [LABEL_W-1:0]       i_label,
    input  logic [METRIC_W-1:0]      i_metric1,
    input  logic [LABEL_W1-1:0]      i_label1,
    output logic                     o_valid,
    output logic [METRIC_W-1:0]      o_metric,
    output logic [CONC_W-1:0]        o_label
);

logic [2:0]                      cnt_in;
logic                            full;

logic [4*METRIC_W-1:0]           buf_metrics0;
logic [4*LABEL_W-1:0]            buf_labels0;
logic [4*METRIC_W-1:0]           buf_metrics1;
logic [4*LABEL_W1-1:0]           buf_labels1;

logic                            start;

logic [(4*SUM_W)-1:0]            ss_metrics;
logic [(4*CONC_W)-1:0]           ss_labels;

logic [1:0]                      cnt_out;
logic                            busy;

logic [(4*SUM_W)-1:0]            out_metrics_r;
logic [(4*CONC_W)-1:0]           out_labels_r;

always_ff @(posedge clk) begin
    if (i_valid) begin
        buf_metrics0[(3-cnt_in)*METRIC_W +: METRIC_W] <= i_metric;
        buf_labels0 [(3-cnt_in)*LABEL_W  +: LABEL_W ] <= i_label;
        buf_metrics1[(3-cnt_in)*METRIC_W +: METRIC_W] <= i_metric1;
        buf_labels1 [(3-cnt_in)*LABEL_W1 +: LABEL_W1] <= i_label1;
    end
end

always_ff @(posedge clk) begin
    if (i_valid) begin
        if (cnt_in == 3)
            cnt_in <= 0;
        else
            cnt_in <= cnt_in + 1;
    end
end

assign full  = (i_valid && cnt_in == 3);
assign start = full;

simple_sum_select #(
    .METRIC_W (METRIC_W),
    .LABEL_W  (LABEL_W),
    .LABEL_W1 (LABEL_W1)
) dut (
    .clk        (clk),
    .i_metrics  (buf_metrics0),
    .i_labels   (buf_labels0),
    .i_metrics1 (buf_metrics1),
    .i_labels1  (buf_labels1),
    .o_metrics  (ss_metrics),
    .o_labels   (ss_labels)
);

always_ff @(posedge clk) begin
    if (start) begin
        out_metrics_r <= ss_metrics;
        out_labels_r  <= ss_labels;
    end
end

always_ff @(posedge clk) begin
    if (start) begin
        busy   <= 1'b1;
        cnt_out <= 0;
    end else if (busy) begin
        if (cnt_out == 3) begin
            busy <= 1'b0;
            cnt_out <= 0;
        end else begin
            cnt_out <= cnt_out + 1;
        end
    end
end

always_comb begin
    if (out_metrics_r[(4*SUM_W - 1) - cnt_out*SUM_W + SUM_W - 1] == 1'b1)
        o_metric = {METRIC_W{1'b1}};
    else
        o_metric = out_metrics_r[(4*SUM_W - 1) - cnt_out*SUM_W -: METRIC_W];

    o_label  = out_labels_r[(4*CONC_W - 1) - cnt_out*CONC_W -: CONC_W];
end

always_ff @(posedge clk) begin
    o_valid <= busy;
end

endmodule