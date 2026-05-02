`timescale 1ns / 1ps

module merge_2n_n_wrapper #(
    parameter                       N_INPUTS = 16,
    parameter                       METRIC_W = 10,
    parameter                       LABEL_W  = 16,
    localparam                      FF_P_W = $clog2(2*N_INPUTS),
    parameter [0 : FF_P_W - 1]      FF_P   = {FF_P_W{1'b1}}
)(
    input  logic                    clk,
    input  logic                    rst,

    input  logic                    i_valid,
    input  logic [METRIC_W - 1 : 0] i_m0,
    input  logic [ LABEL_W - 1 : 0] i_l0,
    input  logic [METRIC_W - 1 : 0] i_m1,
    input  logic [ LABEL_W - 1 : 0] i_l1,

    output logic                    o_valid,
    output logic [METRIC_W - 1 : 0] o_m,
    output logic [ LABEL_W - 1 : 0] o_l
);

    logic [METRIC_W - 1 : 0] i_m0_buf [N_INPUTS];
    logic [ LABEL_W - 1 : 0] i_l0_buf [N_INPUTS];
    logic [METRIC_W - 1 : 0] i_m1_buf [N_INPUTS];
    logic [ LABEL_W - 1 : 0] i_l1_buf [N_INPUTS];

    logic [$clog2(N_INPUTS)-1:0] wr_cnt;
    logic start;

    always_ff @(posedge clk) begin
        if (rst) begin
            wr_cnt <= 0;
            start  <= 0;
        end else begin
            start <= 0;
            if (i_valid) begin
                i_m0_buf[wr_cnt] <= i_m0;
                i_l0_buf[wr_cnt] <= i_l0;
                i_m1_buf[wr_cnt] <= i_m1;
                i_l1_buf[wr_cnt] <= i_l1;

                if (wr_cnt == N_INPUTS - 1) begin
                    start  <= 1;
                    wr_cnt <= 0;
                end else begin
                    wr_cnt <= wr_cnt + 1;
                end
            end
        end
    end

    logic [METRIC_W - 1 : 0] dut_o_m [N_INPUTS];
    logic [ LABEL_W - 1 : 0] dut_o_l [N_INPUTS];
    logic dut_o_valid;

    merge_2n_n #(
        .N_INPUTS (N_INPUTS),
        .METRIC_W (METRIC_W),
        .LABEL_W  (LABEL_W),
        .FF_P     (FF_P)
    ) dut (
        .clk     (clk),
        .i_valid (start),
        .i_m0    (i_m0_buf),
        .i_l0    (i_l0_buf),
        .i_m1    (i_m1_buf),
        .i_l1    (i_l1_buf),
        .o_valid (dut_o_valid),
        .o_m     (dut_o_m),
        .o_l     (dut_o_l)
    );

    logic [$clog2(N_INPUTS)-1:0] rd_cnt;
    logic busy;

    always_ff @(posedge clk) begin
        if (rst) begin
            rd_cnt  <= 0;
            busy    <= 0;
            o_valid <= 0;
        end else begin
            o_valid <= 0;

            if (dut_o_valid) begin
                busy   <= 1;
                rd_cnt <= 0;
            end

            if (busy) begin
                o_valid <= 1;
                o_m     <= dut_o_m[rd_cnt];
                o_l     <= dut_o_l[rd_cnt];

                if (rd_cnt == N_INPUTS - 1) begin
                    busy <= 0;
                end else begin
                    rd_cnt <= rd_cnt + 1;
                end
            end
        end
    end

endmodule