`timescale 1ns / 1ps

module merge_tree_wrapper #(
    parameter                       NUM_LISTS = 8,
    parameter                       N_INPUTS  = 8,
    parameter                       METRIC_W  = 10,
    parameter                       LABEL_W   = 16,
    localparam                      FF_P_W    = $clog2(2*N_INPUTS),
    parameter [0 : FF_P_W - 1]      FF_P      = {FF_P_W{1'b1}}
)(
    input  logic                    clk,
    input  logic                    rst,
    
    input  logic                    i_valid,
    input  logic [METRIC_W - 1 : 0] i_metric,
    input  logic [ LABEL_W - 1 : 0] i_label,
    
    output logic                    o_valid,
    output logic [METRIC_W - 1 : 0] o_metric,
    output logic [ LABEL_W - 1 : 0] o_label
);
    
    localparam TOTAL_IN = NUM_LISTS * N_INPUTS;
    
    logic [METRIC_W-1:0] i_m_buf [NUM_LISTS][N_INPUTS];
    logic [LABEL_W-1:0]  i_l_buf [NUM_LISTS][N_INPUTS];
    
    logic [$clog2(TOTAL_IN):0] wr_cnt;
    logic [$clog2(NUM_LISTS):0] list_idx;
    logic [$clog2(N_INPUTS):0]  elem_idx;
    logic start;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            wr_cnt   <= 0;
            list_idx <= 0;
            elem_idx <= 0;
            start    <= 0;
        end else begin
            start <= 0;
            if (i_valid) begin
                i_m_buf[list_idx][elem_idx] <= i_metric;
                i_l_buf[list_idx][elem_idx] <= i_label;
    
                if (wr_cnt == TOTAL_IN - 1) begin
                    start    <= 1;
                    wr_cnt   <= 0;
                    list_idx <= 0;
                    elem_idx <= 0;
                end else begin
                    wr_cnt <= wr_cnt + 1;
                    if (elem_idx == N_INPUTS - 1) begin
                        elem_idx <= 0;
                        list_idx <= list_idx + 1;
                    end else begin
                        elem_idx <= elem_idx + 1;
                    end
                end
            end
        end
    end
    
    logic [METRIC_W - 1 : 0] dut_m [N_INPUTS];
    logic [ LABEL_W - 1 : 0] dut_l [N_INPUTS];
    logic dut_valid;
    
    merge_tree #(
        .NUM_LISTS (NUM_LISTS),
        .N_INPUTS  (N_INPUTS),
        .METRIC_W  (METRIC_W),
        .LABEL_W   (LABEL_W),
        .FF_P      (FF_P)
    ) dut (
        .clk     (clk),
        .i_valid (start),
        .i_m     (i_m_buf),
        .i_l     (i_l_buf),
        .o_m     (dut_m),
        .o_l     (dut_l),
        .o_valid (dut_valid)
    );
    
    logic [$clog2(N_INPUTS):0] rd_cnt;
    logic busy;
    
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
                o_metric <= dut_m[rd_cnt];
                o_label  <= dut_l[rd_cnt];
    
                if (rd_cnt == N_INPUTS - 1) begin
                    busy <= 0;
                end else begin
                    rd_cnt <= rd_cnt + 1;
                end
            end
        end
    end
endmodule