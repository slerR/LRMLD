`timescale 1ns / 1ps

module sort_4 #(
    parameter METRIC_W = 10,
    parameter LABEL_W  = 8
)(
    input  logic                     clk,
    input  logic                     i_valid,
    input  logic [METRIC_W - 1 : 0]  i_m [0 : 3],
    input  logic [ LABEL_W - 1 : 0]  i_l [0 : 3],
    output logic                     o_valid,
    output logic [METRIC_W - 1 : 0]  o_m [0 : 3],
    output logic [ LABEL_W - 1 : 0]  o_l [0 : 3]
);
    
    logic [METRIC_W - 1 : 0] m_r [0 : 3];
    logic [ LABEL_W - 1 : 0] l_r [0 : 3];
    logic valid_r;
    
    always_ff @(posedge clk) begin
        valid_r <= i_valid;
        m_r     <= i_m;
        l_r     <= i_l;
    end
    
    logic [METRIC_W - 1 : 0] s1_m [0 : 3];
    logic [ LABEL_W - 1 : 0] s1_l [0 : 3];
    
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) c1_0 (.clk(clk), .i_m('{m_r[0], m_r[1]}), .i_l('{l_r[0], l_r[1]}), .o_min(s1_m[0]), .o_max(s1_m[1]), .o_lmin(s1_l[0]), .o_lmax(s1_l[1]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) c1_1 (.clk(clk), .i_m('{m_r[2], m_r[3]}), .i_l('{l_r[2], l_r[3]}), .o_min(s1_m[2]), .o_max(s1_m[3]), .o_lmin(s1_l[2]), .o_lmax(s1_l[3]));
    
    logic [METRIC_W - 1 : 0] mid_m [0 : 3];
    logic [ LABEL_W - 1 : 0] mid_l [0 : 3];
    logic valid_mid;
    
    always_ff @(posedge clk) begin
        valid_mid <= valid_r;
        mid_m     <= s1_m;
        mid_l     <= s1_l;
    end
    
    logic [METRIC_W - 1 : 0] s2_m [0 : 3], s3_m [0 : 3];
    logic [ LABEL_W - 1 : 0] s2_l [0 : 3], s3_l [0 : 3];
    
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) c2_0 (.clk(clk), .i_m('{mid_m[0], mid_m[2]}), .i_l('{mid_l[0], mid_l[2]}), .o_min(s2_m[0]), .o_max(s2_m[2]), .o_lmin(s2_l[0]), .o_lmax(s2_l[2]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) c2_1 (.clk(clk), .i_m('{mid_m[1], mid_m[3]}), .i_l('{mid_l[1], mid_l[3]}), .o_min(s2_m[1]), .o_max(s2_m[3]), .o_lmin(s2_l[1]), .o_lmax(s2_l[3]));
    
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) c3_0 (.clk(clk), .i_m('{s2_m[1], s2_m[2]}), .i_l('{s2_l[1], s2_l[2]}), .o_min(s3_m[1]), .o_max(s3_m[2]), .o_lmin(s3_l[1]), .o_lmax(s3_l[2]));
    
    assign s3_m[0] = s2_m[0];
    assign s3_m[3] = s2_m[3];
    assign s3_l[0] = s2_l[0];
    assign s3_l[3] = s2_l[3];
    
    assign o_valid = valid_mid;
    assign o_m     = s3_m;
    assign o_l     = s3_l;
endmodule