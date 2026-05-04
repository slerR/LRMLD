`timescale 1ns / 1ps

module wp_comb #(
    parameter L            = 12,
    parameter logic IS_FSM = 1,
    parameter N            = 12,
    parameter N1           = 12,
    parameter N_COS        = 8,
    parameter N_U          = 4,
    parameter METRIC_W     = 10,
    parameter LABEL_W      = 16,
    parameter LABEL_W1     = 16,
    parameter CONC_W       = LABEL_W + LABEL_W1,
    localparam N_LIM       = (N * N1 < L) ? N  : ( (L <= 4) ? 2 : (L <= 6) ? 2 : (L <= 9) ? 3 : (L <= 12) ? 3 : 4 ),
    localparam N1_LIM      = (N * N1 < L) ? N1 : ( (L <= 4) ? 2 : (L <= 6) ? 3 : (L <= 9) ? 3 : (L <= 12) ? 4 : 4 ),
    localparam TOTAL_COMBO = N_LIM * N1_LIM,
    localparam L_OUT       = (TOTAL_COMBO < L) ? TOTAL_COMBO : L,
    parameter  N_OUT       = (N >= L & N1 >= L) ? L : L_OUT,
    localparam int FF_P_W  = (2 * N_OUT <= 1) ? 1 : $clog2(2 * N_OUT),
    parameter [0 : FF_P_W - 1] FF_P = {FF_P_W{1'b1}},
    localparam int IDX_W       = (N_COS <= 1) ? 1 : $clog2(N_COS),
    localparam int TBL_ELEM_W  = 2 * IDX_W,
    localparam int TBL_FLAT_W  = N_COS * N_U * TBL_ELEM_W
)(
    input  wire clk,
    input  wire rst,

    input  wire i_valid,
    input  wire [METRIC_W - 1 : 0] i_metric,
    input  wire [LABEL_W  - 1 : 0] i_label,
    input  wire [METRIC_W - 1 : 0] i_metric1,
    input  wire [LABEL_W1 - 1 : 0] i_label1,

    output logic o_valid,
    output logic [METRIC_W - 1 : 0] o_metric,
    output logic [CONC_W   - 1 : 0] o_label
);

    typedef logic [TBL_ELEM_W-1:0] tbl_elem_t;
    typedef tbl_elem_t tbl_t [0:N_COS-1][0:N_U-1];
    
    function automatic tbl_t gen_tbl();
        tbl_t tmp;
        logic [IDX_W-1:0] l_idx;
        logic [IDX_W-1:0] r_idx;
        for (int i = 0; i < N_COS; i++) begin
            for (int j = 0; j < N_U; j++) begin
                l_idx = (i + j) % N_COS;
                r_idx = (i + 2*j + 1) % N_COS;
                tmp[i][j] = {l_idx, r_idx};
            end
        end
        return tmp;
    endfunction
    
    parameter tbl_t TBL = gen_tbl();

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

    logic [N_OUT * METRIC_W - 1 : 0] dut_metrics [0 : N_COS - 1];
    logic [N_OUT * CONC_W   - 1 : 0] dut_labels  [0 : N_COS - 1];
    logic                            dut_valid;

    comb #(
        .L        (L),
        .IS_FSM   (IS_FSM),
        .N        (N),
        .N1       (N1),
        .N_COS    (N_COS),
        .METRIC_W (METRIC_W),
        .LABEL_W  (LABEL_W),
        .LABEL_W1 (LABEL_W1),
        .N_U      (N_U),
        .TBL      (TBL),
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

    localparam int TOTAL_OUT  = N_COS * N_OUT;
    localparam int OUT_CNT_W  = (TOTAL_OUT <= 1) ? 1 : $clog2(TOTAL_OUT);
    localparam int OUT_COS_W  = (N_COS <= 1) ? 1 : $clog2(N_COS);
    localparam int OUT_ELEM_W = (N_OUT <= 1) ? 1 : $clog2(N_OUT);

    logic [N_OUT * METRIC_W - 1 : 0] out_m_buf [0 : N_COS - 1];
    logic [N_OUT * CONC_W   - 1 : 0] out_l_buf [0 : N_COS - 1];

    logic [OUT_CNT_W - 1 : 0]  rd_cnt;
    logic [OUT_COS_W - 1 : 0]  rd_cos_idx;
    logic [OUT_ELEM_W - 1 : 0] rd_elem_idx;
    logic                      busy;

    always_ff @(posedge clk) begin
        if (rst) begin
            rd_cnt      <= '0;
            rd_cos_idx  <= '0;
            rd_elem_idx <= '0;
            busy        <= 1'b0;
            o_valid     <= 1'b0;
            o_metric    <= '0;
            o_label     <= '0;
            for (int k = 0; k < N_COS; k++) begin
                out_m_buf[k] <= '0;
                out_l_buf[k] <= '0;
            end
        end else begin
            o_valid <= 1'b0;
            if (dut_valid) begin
                for (int k = 0; k < N_COS; k++) begin
                    out_m_buf[k] <= dut_metrics[k];
                    out_l_buf[k] <= dut_labels[k];
                end
                busy        <= 1'b1;
                rd_cnt      <= '0;
                rd_cos_idx  <= '0;
                rd_elem_idx <= '0;
            end
            if (busy) begin
                o_valid  <= 1'b1;
                o_metric <= out_m_buf[rd_cos_idx][(N_OUT * METRIC_W - 1) - rd_elem_idx * METRIC_W -: METRIC_W];
                o_label  <= out_l_buf[rd_cos_idx][(N_OUT * CONC_W - 1) - rd_elem_idx * CONC_W -: CONC_W];
                if (rd_cnt == TOTAL_OUT - 1) begin
                    busy <= 1'b0;
                end else begin
                    rd_cnt <= rd_cnt + 1'b1;
                    if (rd_elem_idx == N_OUT - 1) begin
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