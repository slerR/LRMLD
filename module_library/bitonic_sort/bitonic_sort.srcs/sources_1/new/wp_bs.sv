`timescale 1ns / 1ps

module bitonic_sort_wrapper #(
    parameter METRIC_W = 10,
    parameter LABEL_W  = 16,
    parameter N        = 16
)(
    input  logic clk,
    input  logic rst,

    input  logic                   i_valid,
    input  logic [METRIC_W-1:0]    i_metric,
    input  logic [ LABEL_W-1:0]    i_label,

    output logic                   o_valid,
    output logic [METRIC_W-1:0]    o_metric,
    output logic [ LABEL_W-1:0]    o_label
);

    logic [N*METRIC_W-1:0] i_metrics_buf;
    logic [N*LABEL_W -1:0] i_labels_buf;

    logic [$clog2(N)-1:0] wr_cnt;
    logic                 start;

    always_ff @(posedge clk) begin
        if (rst) begin
            wr_cnt <= 0;
            start  <= 0;
        end else begin
            start <= 0;
            if (i_valid) begin
                i_metrics_buf [ (N-1-wr_cnt)*METRIC_W +: METRIC_W ] <= i_metric;
                i_labels_buf  [ (N-1-wr_cnt)*LABEL_W  +: LABEL_W  ] <= i_label;

                wr_cnt <= wr_cnt + 1;
                if (wr_cnt == N-1) begin
                    start  <= 1;
                    wr_cnt <= 0;
                end
            end
        end
    end

    logic [N*METRIC_W-1:0] o_m_flat;
    logic [N*LABEL_W -1:0] o_l_flat;
    logic                  dut_valid;

    bitonic_sort_fp #(
        .METRIC_W (METRIC_W),
        .LABEL_W  (LABEL_W),
        .N        (N)
    ) dut (
        .clk       (clk),
        .i_valid   (start),
        .i_metrics (i_metrics_buf),
        .i_labels  (i_labels_buf),
        .o_valid   (dut_valid),
        .o_metrics (o_m_flat),
        .o_labels  (o_l_flat)
    );

    logic [$clog2(N)-1:0] rd_cnt;
    logic                 busy;

    always_ff @(posedge clk) begin
        if (rst) begin
            rd_cnt  <= 0;
            busy    <= 0;
            o_valid <= 0;
        end else begin
            o_valid <= 0;

            if (dut_valid) begin
                busy   <= 1;
                rd_cnt <= 0;
            end

            if (busy) begin
                o_valid  <= 1;
                o_metric <= o_m_flat[ (N-1-rd_cnt)*METRIC_W +: METRIC_W ];
                o_label  <= o_l_flat [ (N-1-rd_cnt)*LABEL_W  +: LABEL_W  ];
                
                rd_cnt <= rd_cnt + 1;
                if (rd_cnt == N-1) begin
                    busy <= 0;
                end
            end
        end
    end

endmodule