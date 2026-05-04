`timescale 1ns / 1ps

module table_sort_wrap #(
    parameter METRIC_W = 10,
    parameter LABEL_W  = 4,
    parameter N_COS    = 8,
    parameter N        = 8
)(
    input  logic clk,
    input  logic rst,

    input  logic i_valid,
    input  logic [METRIC_W - 1 : 0] i_metric,
    input  logic [ LABEL_W - 1 : 0] i_label,

    output logic o_valid,
    output logic [METRIC_W - 1 : 0] o_metric,
    output logic [ LABEL_W - 1 : 0] o_label
);

    localparam int MAX_IN_LEN = N;
    localparam int TOTAL_IN   = N_COS * MAX_IN_LEN;
    localparam int IN_CNT_W   = (TOTAL_IN <= 1) ? 1 : $clog2(TOTAL_IN);
    localparam int COS_CNT_W  = (N_COS <= 1) ? 1 : $clog2(N_COS);
    localparam int ELEM_CNT_W = (N <= 1) ? 1 : $clog2(N);

    logic [METRIC_W - 1 : 0] in_metrics [0 : N_COS - 1][0 : N - 1];
    logic [ LABEL_W - 1 : 0] in_labels  [0 : N_COS - 1][0 : N - 1];

    logic [IN_CNT_W - 1 : 0]   wr_cnt;
    logic [COS_CNT_W - 1 : 0]  cos_idx;
    logic [ELEM_CNT_W - 1 : 0] elem_idx;
    logic                      start;

    always_ff @(posedge clk) begin
        if (rst) begin
            wr_cnt   <= '0;
            cos_idx  <= '0;
            elem_idx <= '0;
            start    <= 1'b0;
            for (int i = 0; i < N_COS; i++) begin
                for (int j = 0; j < N; j++) begin
                    in_metrics[i][j] <= '0;
                    in_labels [i][j] <= '0;
                end
            end
        end else begin
            start <= 1'b0;
            if (i_valid) begin
                in_metrics[cos_idx][elem_idx] <= i_metric;
                in_labels [cos_idx][elem_idx] <= i_label;

                if (wr_cnt == TOTAL_IN - 1) begin
                    start    <= 1'b1;
                    wr_cnt   <= '0;
                    cos_idx  <= '0;
                    elem_idx <= '0;
                end else begin
                    wr_cnt <= wr_cnt + 1'b1;
                    if (elem_idx == N - 1) begin
                        elem_idx <= '0;
                        cos_idx  <= cos_idx + 1'b1;
                    end else begin
                        elem_idx <= elem_idx + 1'b1;
                    end
                end
            end
        end
    end

    logic [METRIC_W - 1 : 0] dut_metrics [0 : N_COS - 1][0 : N - 1];
    logic [ LABEL_W - 1 : 0] dut_labels  [0 : N_COS - 1][0 : N - 1];
    logic                    dut_valid;

    table_sort #(
        .METRIC_W (METRIC_W),
        .LABEL_W  (LABEL_W),
        .N_COS    (N_COS),
        .N        (N)
    ) dut (
        .clk      (clk),
        .i_valid  (start),
        .i_metrics(in_metrics),
        .i_labels (in_labels),
        .o_metrics(dut_metrics),
        .o_labels (dut_labels),
        .o_valid  (dut_valid)
    );

    localparam int TOTAL_OUT   = N_COS * N;
    localparam int OUT_COS_W   = (N_COS <= 1) ? 1 : $clog2(N_COS);
    localparam int OUT_ELEM_W  = (N <= 1) ? 1 : $clog2(N);

    logic [METRIC_W - 1 : 0] out_m_buf [0 : N_COS - 1][0 : N - 1];
    logic [ LABEL_W - 1 : 0] out_l_buf [0 : N_COS - 1][0 : N - 1];

    logic [OUT_COS_W - 1 : 0]  rd_cos_idx;
    logic [OUT_ELEM_W - 1 : 0] rd_elem_idx;
    logic [IN_CNT_W - 1 : 0]   rd_cnt;
    logic                      busy;

    always_ff @(posedge clk) begin
        if (rst) begin
            rd_cos_idx  <= '0;
            rd_elem_idx <= '0;
            rd_cnt      <= '0;
            busy        <= 1'b0;
            o_valid     <= 1'b0;
            o_metric    <= '0;
            o_label     <= '0;
            for (int i = 0; i < N_COS; i++) begin
                for (int j = 0; j < N; j++) begin
                    out_m_buf[i][j] <= '0;
                    out_l_buf[i][j] <= '0;
                end
            end
        end else begin
            o_valid <= 1'b0;

            if (dut_valid) begin
                for (int i = 0; i < N_COS; i++) begin
                    for (int j = 0; j < N; j++) begin
                        out_m_buf[i][j] <= dut_metrics[i][j];
                        out_l_buf[i][j] <= dut_labels[i][j];
                    end
                end
                rd_cos_idx  <= '0;
                rd_elem_idx <= '0;
                rd_cnt      <= '0;
                busy        <= 1'b1;
            end

            if (busy) begin
                o_valid  <= 1'b1;
                o_metric <= out_m_buf[rd_cos_idx][rd_elem_idx];
                o_label  <= out_l_buf[rd_cos_idx][rd_elem_idx];

                if (rd_cnt == TOTAL_OUT - 1) begin
                    busy <= 1'b0;
                end else begin
                    rd_cnt <= rd_cnt + 1'b1;
                    if (rd_elem_idx == N - 1) begin
                        rd_elem_idx <= '0;
                        rd_cos_idx  <= rd_cos_idx + 1'b1;
                    end else begin
                        rd_elem_idx <= rd_elem_idx + 1'b1;
                    end
                end
            end
        end
    end

endmodule