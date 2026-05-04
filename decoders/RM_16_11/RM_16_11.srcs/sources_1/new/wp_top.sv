`timescale 1ns / 1ps

module wp_top #(
    parameter L          = 2,
    parameter IS_FSM     = 0,
    parameter LLR_W      = 6,
    localparam MLABEL_W  = 4,
    localparam METRIC_W  = LLR_W + $clog2(MLABEL_W)
)(
    input  logic clk,
    input  logic rst,
           
    input  logic i_v,
    input  logic signed [LLR_W - 1 : 0] i_llr,
    
    output logic o_v,
    output logic [METRIC_W - 1 : 0] o_m,
    output logic [15 : 0] o_l
);

    logic signed [LLR_W - 1 : 0] in_buf [0 : 15];
    logic [4 : 0] wr_ptr;
    logic trigger;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            wr_ptr <= '0;
            trigger <= 1'b0;
            for (int i = 0; i < 16; i++) in_buf[i] <= '0;
        end else begin
            trigger <= 1'b0;
            if (i_v) begin
                in_buf[wr_ptr] <= i_llr;
                if (wr_ptr == 15) begin
                    wr_ptr <= '0;
                    trigger <= 1'b1;
                end else begin
                    wr_ptr <= wr_ptr + 1'b1;
                end
            end
        end
    end
    
    logic [METRIC_W - 1 : 0] dut_m [0 : L - 1];
    logic [15 : 0] dut_l [0 : L - 1];
    logic dut_v;
    
    top #(
        .L(L),
        .IS_FSM(IS_FSM),
        .LLR_W(LLR_W)
    ) dut (
        .clk(clk),
        .i_v(trigger),
        .i_llr(in_buf),
        .o_m(dut_m),
        .o_l(dut_l),
        .o_v(dut_v)
    );
    
    logic [METRIC_W - 1 : 0] out_m_buf [0 : L - 1];
    logic [15 : 0] out_l_buf [0 : L - 1];
    logic [15 : 0] rd_ptr;
    logic active;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            rd_ptr <= '0;
            active <= 1'b0;
            o_v <= 1'b0;
            o_m <= '0;
            o_l <= '0;
        end else begin
            o_v <= 1'b0;
            if (dut_v) begin
                for (int i = 0; i < L; i++) begin
                    out_m_buf[i] <= dut_m[i];
                    out_l_buf[i] <= dut_l[i];
                end
                active <= 1'b1;
                rd_ptr <= '0;
            end
            
            if (active) begin
                o_v <= 1'b1;
                o_m <= out_m_buf[rd_ptr];
                o_l <= out_l_buf[rd_ptr];
                if (rd_ptr == L - 1) begin
                    active <= 1'b0;
                end else begin
                    rd_ptr <= rd_ptr + 1'b1;
                end
            end
        end
    end
endmodule