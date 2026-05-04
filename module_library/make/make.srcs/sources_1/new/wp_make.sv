`timescale 1ns / 1ps

module wp_make #(
    parameter LLR_W   = 8,
    parameter LABEL_W = 8,
    parameter N_COS   = 8,
    parameter N       = 4,
    parameter METRIC_W = LLR_W + $clog2(LABEL_W)
)(
    input  logic clk,
    input  logic rst,
    
    input  logic i_valid,
    input  logic signed [LLR_W - 1 : 0] i_llr,
    
    output logic o_valid,
    output logic [METRIC_W - 1 : 0] o_metric,
    output logic [LABEL_W  - 1 : 0] o_label
);
    
    typedef logic [LABEL_W-1:0] decomp_t [0:N_COS-1][0:N-1];
    
    function automatic decomp_t gen_decomp();
        decomp_t tmp;
        for (int c = 0; c < N_COS; c++) begin
            for (int w = 0; w < N; w++) begin
                tmp[c][w] = (LABEL_W > 8) ? (c << (LABEL_W/2)) | w : (c * N + w);
            end
        end
        return tmp;
    endfunction
    
    localparam decomp_t DECOMP_TBL = gen_decomp();
    
    logic signed [LLR_W - 1 : 0] llr_buffer [0 : LABEL_W - 1];
    logic [$clog2(LABEL_W) : 0]  wr_ptr;
    logic                        process_start;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            wr_ptr <= '0;
            process_start <= 1'b0;
            for (int i = 0; i < LABEL_W; i++) llr_buffer[i] <= '0;
        end else begin
            process_start <= 1'b0;
            if (i_valid) begin
                llr_buffer[wr_ptr] <= i_llr;
                if (wr_ptr == LABEL_W - 1) begin
                    wr_ptr <= '0;
                    process_start <= 1'b1;
                end else begin
                    wr_ptr <= wr_ptr + 1'b1;
                end
            end
        end
    end
    
    logic [N*METRIC_W - 1 : 0] dut_metrics [0 : N_COS - 1];
    logic [N*LABEL_W  - 1 : 0] dut_labels  [0 : N_COS - 1];
    logic                      dut_valid;
    
    make #(
        .LLR_W   (LLR_W),
        .LABEL_W (LABEL_W),
        .N_COS   (N_COS),
        .N       (N),
        .DECOMP  (DECOMP_TBL)
    ) dut (
        .clk      (clk),
        .i_valid  (process_start),
        .i_llr    (llr_buffer),
        .o_metrics(dut_metrics),
        .o_labels (dut_labels),
        .o_valid  (dut_valid)
    );
        
    localparam int TOTAL_OUT = N_COS * N;
    localparam int OUT_CNT_W = (TOTAL_OUT <= 1) ? 1 : $clog2(TOTAL_OUT);
    localparam int COS_IDX_W = (N_COS <= 1) ? 1 : $clog2(N_COS);
    localparam int SUB_IDX_W = (N <= 1) ? 1 : $clog2(N);
    
    logic [N*METRIC_W - 1 : 0] out_m_reg [0 : N_COS - 1];
    logic [N*LABEL_W  - 1 : 0] out_l_reg [0 : N_COS - 1];
    
    logic [OUT_CNT_W - 1 : 0] rd_cnt;
    logic [COS_IDX_W - 1 : 0] rd_cos;
    logic [SUB_IDX_W - 1 : 0] rd_sub;
    logic                     active;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            rd_cnt   <= '0;
            rd_cos   <= '0;
            rd_sub   <= '0;
            active   <= 1'b0;
            o_valid  <= 1'b0;
            o_metric <= '0;
            o_label  <= '0;
        end else begin
            o_valid <= 1'b0;
            if (dut_valid) begin
                out_m_reg <= dut_metrics;
                out_l_reg <= dut_labels;
                active    <= 1'b1;
                rd_cnt    <= '0;
                rd_cos    <= '0;
                rd_sub    <= '0;
            end
    
            if (active) begin
                o_valid  <= 1'b1;
                o_metric <= out_m_reg[rd_cos][(N * METRIC_W - 1) - rd_sub * METRIC_W -: METRIC_W];
                o_label  <= out_l_reg[rd_cos][(N * LABEL_W  - 1) - rd_sub * LABEL_W  -: LABEL_W ];
                
                if (rd_cnt == TOTAL_OUT - 1) begin
                    active <= 1'b0;
                end else begin
                    rd_cnt <= rd_cnt + 1'b1;
                    if (rd_sub == N - 1) begin
                        rd_sub <= '0;
                        rd_cos <= rd_cos + 1'b1;
                    end else begin
                        rd_sub <= rd_sub + 1'b1;
                    end
                end
            end
        end
    end
endmodule