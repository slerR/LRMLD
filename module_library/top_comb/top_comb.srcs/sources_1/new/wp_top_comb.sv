`timescale 1ns / 1ps

module wp_top_comb #(
    parameter  L           = 8,
    parameter  N           = 8,
    parameter  N1          = 8,
    parameter  N_COS       = 8,
    parameter  METRIC_W    = 10,
    parameter  LABEL_W     = 32, 
    parameter  LABEL_W1    = 32,
    parameter  CONC_W      = LABEL_W + LABEL_W1,
    localparam N_LIM       = (N * N1 < L) ? N  : ( (L <= 4) ? 2 : (L <= 6) ? 2 : (L <= 9) ? 3 : (L <= 12) ? 3 : 4 ),
    localparam N1_LIM      = (N * N1 < L) ? N1 : ( (L <= 4) ? 2 : (L <= 6) ? 3 : (L <= 9) ? 3 : (L <= 12) ? 4 : 4 ),
    localparam TOTAL_COMBO = N_LIM * N1_LIM,
    localparam L_OUT       = (TOTAL_COMBO < L) ? TOTAL_COMBO : L,
    parameter  N_OUT       = (N >= L & N1 >= L) ? L : L_OUT,
    localparam int FF_P_W  = (2 * N_OUT <= 1) ? 1 : $clog2(2 * N_OUT),
    parameter [0 : FF_P_W - 1] FF_P = {FF_P_W{1'b1}}
)(
    input  logic clk,
    input  logic rst,
    
    input  logic i_valid,
    input  logic [METRIC_W - 1 : 0] i_metric,
    input  logic [LABEL_W  - 1 : 0] i_label,
    input  logic [METRIC_W - 1 : 0] i_metric1,
    input  logic [LABEL_W1 - 1 : 0] i_label1,
    
    output logic o_valid,
    output logic [METRIC_W - 1 : 0] o_metric,
    output logic [CONC_W   - 1 : 0] o_label
);
    
    logic [N * METRIC_W - 1 : 0]  in_metrics  [0 : N_COS - 1];
    logic [N * LABEL_W  - 1 : 0]  in_labels   [0 : N_COS - 1];
    logic [N1 * METRIC_W - 1 : 0] in_metrics1 [0 : N_COS - 1];
    logic [N1 * LABEL_W1 - 1 : 0] in_labels1  [0 : N_COS - 1];
    
    localparam int MAX_IN_LEN = (N > N1) ? N : N1;
    localparam int TOTAL_IN   = N_COS * MAX_IN_LEN;
    localparam int IN_CNT_W   = (TOTAL_IN <= 1) ? 1 : $clog2(TOTAL_IN);
    localparam int COS_CNT_W  = (N_COS <= 1) ? 1 : $clog2(N_COS);
    localparam int ELEM_CNT_W = (MAX_IN_LEN <= 1) ? 1 : $clog2(MAX_IN_LEN);
    
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
            for (int k = 0; k < N_COS; k++) begin
                in_metrics[k]  <= '0;
                in_labels[k]   <= '0;
                in_metrics1[k] <= '0;
                in_labels1[k]  <= '0;
            end
        end else begin
            start <= 1'b0;
            if (i_valid) begin
                if (elem_idx < N) begin
                    in_metrics[cos_idx][(N * METRIC_W - 1) - elem_idx * METRIC_W -: METRIC_W] <= i_metric;
                    in_labels[cos_idx][(N * LABEL_W - 1) - elem_idx * LABEL_W -: LABEL_W] <= i_label;
                end
                if (elem_idx < N1) begin
                    in_metrics1[cos_idx][(N1 * METRIC_W - 1) - elem_idx * METRIC_W -: METRIC_W] <= i_metric1;
                    in_labels1[cos_idx][(N1 * LABEL_W1 - 1) - elem_idx * LABEL_W1 -: LABEL_W1] <= i_label1;
                end
                if (wr_cnt == TOTAL_IN - 1) begin
                    start    <= 1'b1;
                    wr_cnt   <= '0;
                    cos_idx  <= '0;
                    elem_idx <= '0;
                end else begin
                    wr_cnt <= wr_cnt + 1'b1;
                    if (elem_idx == MAX_IN_LEN - 1) begin
                        elem_idx <= '0;
                        cos_idx  <= cos_idx + 1'b1;
                    end else begin
                        elem_idx <= elem_idx + 1'b1;
                    end
                end
            end
        end
    end
    
    logic [METRIC_W - 1 : 0] dut_metrics [0 : N_OUT - 1];
    logic [CONC_W   - 1 : 0] dut_labels  [0 : N_OUT - 1];
    logic                    dut_valid;
    
    top_comb #(
        .L        (L),
        .N        (N),
        .N1       (N1),
        .N_COS    (N_COS),
        .METRIC_W (METRIC_W),
        .LABEL_W  (LABEL_W),
        .LABEL_W1 (LABEL_W1),
        .N_OUT    (N_OUT),
        .FF_P     (FF_P)
    ) dut (
        .clk        (clk),
        .i_valid    (start),
        .i_metrics  (in_metrics),
        .i_labels   (in_labels),
        .i_metrics1 (in_metrics1),
        .i_labels1  (in_labels1),
        .o_metrics  (dut_metrics),
        .o_labels   (dut_labels),
        .o_valid    (dut_valid)
    );
    
    localparam int RD_CNT_W = (N_OUT <= 1) ? 1 : $clog2(N_OUT);
    logic [METRIC_W - 1 : 0] out_m_buf [0 : N_OUT - 1];
    logic [CONC_W   - 1 : 0] out_l_buf [0 : N_OUT - 1];
    logic [RD_CNT_W - 1 : 0] rd_cnt;
    logic                    busy;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            rd_cnt      <= '0;
            busy        <= 1'b0;
            o_valid     <= 1'b0;
            o_metric    <= '0;
            o_label     <= '0;
            for (int k = 0; k < N_OUT; k++) begin
                out_m_buf[k] <= '0;
                out_l_buf[k] <= '0;
            end
        end else begin
            o_valid <= 1'b0;
            if (dut_valid) begin
                out_m_buf <= dut_metrics;
                out_l_buf <= dut_labels;
                busy      <= 1'b1;
                rd_cnt    <= '0;
            end
            if (busy) begin
                o_valid  <= 1'b1;
                o_metric <= out_m_buf[rd_cnt];
                o_label  <= out_l_buf[rd_cnt];
                if (rd_cnt == N_OUT - 1) begin
                    busy <= 1'b0;
                end else begin
                    rd_cnt <= rd_cnt + 1'b1;
                end
            end
        end
    end
endmodule