`timescale 1ns / 1ps

module SS12_wrapper #(
    parameter  METRIC_W = 8,
    parameter  LABEL_W  = 8,
    parameter  LABEL_W1 = 8,
    localparam CONC_W   = LABEL_W + LABEL_W1
)(
    input  logic clk,
    input  logic rst,

    input  logic                 i_valid,
    input  logic [METRIC_W-1:0]  i_metric,
    input  logic [LABEL_W-1:0]   i_label,
    input  logic [METRIC_W-1:0]  i_metric1,
    input  logic [LABEL_W1-1:0]  i_label1,

    output logic                 o_valid,
    output logic [METRIC_W-1:0]  o_metric,
    output logic [CONC_W-1:0]    o_label
);

    logic [12*METRIC_W-1:0] i_metrics_buf;
    logic [12*LABEL_W -1:0]  i_labels_buf;
    logic [12*METRIC_W-1:0]  i_metrics1_buf;
    logic [12*LABEL_W1-1:0]  i_labels1_buf;

    logic [3:0] wr_cnt;
    logic       start;

    always_ff @(posedge clk) begin
        if (rst) begin
            wr_cnt <= 0;
            start  <= 0;
        end else begin
            start <= 0;
            if (i_valid) begin
                i_metrics_buf [ (11-wr_cnt)*METRIC_W +: METRIC_W ] <= i_metric;
                i_labels_buf  [ (11-wr_cnt)*LABEL_W  +: LABEL_W  ] <= i_label;
                i_metrics1_buf[ (11-wr_cnt)*METRIC_W +: METRIC_W ] <= i_metric1;
                i_labels1_buf [ (11-wr_cnt)*LABEL_W1 +: LABEL_W1 ] <= i_label1;

                wr_cnt <= wr_cnt + 1;
                if (wr_cnt == 11) begin
                    start  <= 1;
                    wr_cnt <= 0;
                end
            end
        end
    end

    logic [METRIC_W-1:0] o_m_arr [0:11];
    logic [CONC_W-1:0]   o_l_arr [0:11];
    logic                dut_valid;

    sum_select_12 #(
        .METRIC_W (METRIC_W),
        .LABEL_W  (LABEL_W),
        .LABEL_W1 (LABEL_W1)
    ) dut (
        .clk        (clk),
        .i_valid    (start),
        .i_metrics  (i_metrics_buf),
        .i_labels   (i_labels_buf),
        .i_metrics1 (i_metrics1_buf),
        .i_labels1  (i_labels1_buf),
        .o_metrics  (o_m_arr),
        .o_labels   (o_l_arr),
        .o_valid    (dut_valid)
    );

    logic [3:0] rd_cnt;
    logic       busy;

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
                o_metric <= o_m_arr[11-rd_cnt];
                o_label  <= o_l_arr[11-rd_cnt];
                
                rd_cnt <= rd_cnt + 1;
                if (rd_cnt == 11) begin
                    busy <= 0;
                end
            end
        end
    end

endmodule