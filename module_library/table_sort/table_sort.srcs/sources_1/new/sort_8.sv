`timescale 1ns / 1ps

module sort_8 #(
    parameter METRIC_W = 10,
    parameter LABEL_W  = 8
)(
    input  logic                     clk,
    input  logic                     i_valid,
    input  logic [METRIC_W - 1 : 0]  i_m [0 : 7],
    input  logic [ LABEL_W - 1 : 0]  i_l [0 : 7],
    output logic                     o_valid,
    output logic [METRIC_W - 1 : 0]  o_m [0 : 7],
    output logic [ LABEL_W - 1 : 0]  o_l [0 : 7]
);

    logic [METRIC_W - 1 : 0] m_r [0 : 7];
    logic [ LABEL_W - 1 : 0] l_r [0 : 7];
    logic valid_r;
    
    always_ff @(posedge clk) begin
        valid_r <= i_valid;
        m_r     <= i_m;
        l_r     <= i_l;
    end
    
    logic [METRIC_W - 1 : 0] s1_m [0 : 7], s2_m [0 : 7], s3_m [0 : 7];
    logic [ LABEL_W - 1 : 0] s1_l [0 : 7], s2_l [0 : 7], s3_l [0 : 7];
    
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l1_0 (.clk(clk), .i_m('{m_r[0], m_r[1]}), .i_l('{l_r[0], l_r[1]}), .o_min(s1_m[0]), .o_max(s1_m[1]), .o_lmin(s1_l[0]), .o_lmax(s1_l[1]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l1_1 (.clk(clk), .i_m('{m_r[2], m_r[3]}), .i_l('{l_r[2], l_r[3]}), .o_min(s1_m[3]), .o_max(s1_m[2]), .o_lmin(s1_l[3]), .o_lmax(s1_l[2]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l1_2 (.clk(clk), .i_m('{m_r[4], m_r[5]}), .i_l('{l_r[4], l_r[5]}), .o_min(s1_m[4]), .o_max(s1_m[5]), .o_lmin(s1_l[4]), .o_lmax(s1_l[5]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l1_3 (.clk(clk), .i_m('{m_r[6], m_r[7]}), .i_l('{l_r[6], l_r[7]}), .o_min(s1_m[7]), .o_max(s1_m[6]), .o_lmin(s1_l[7]), .o_lmax(s1_l[6]));
    
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l2_0 (.clk(clk), .i_m('{s1_m[0], s1_m[2]}), .i_l('{s1_l[0], s1_l[2]}), .o_min(s2_m[0]), .o_max(s2_m[2]), .o_lmin(s2_l[0]), .o_lmax(s2_l[2]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l2_1 (.clk(clk), .i_m('{s1_m[1], s1_m[3]}), .i_l('{s1_l[1], s1_l[3]}), .o_min(s2_m[1]), .o_max(s2_m[3]), .o_lmin(s2_l[1]), .o_lmax(s2_l[3]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l2_2 (.clk(clk), .i_m('{s1_m[4], s1_m[6]}), .i_l('{s1_l[4], s1_l[6]}), .o_min(s2_m[6]), .o_max(s2_m[4]), .o_lmin(s2_l[6]), .o_lmax(s2_l[4]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l2_3 (.clk(clk), .i_m('{s1_m[5], s1_m[7]}), .i_l('{s1_l[5], s1_l[7]}), .o_min(s2_m[7]), .o_max(s2_m[5]), .o_lmin(s2_l[7]), .o_lmax(s2_l[5]));
    
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l3_0 (.clk(clk), .i_m('{s2_m[0], s2_m[1]}), .i_l('{s2_l[0], s2_l[1]}), .o_min(s3_m[0]), .o_max(s3_m[1]), .o_lmin(s3_l[0]), .o_lmax(s3_l[1]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l3_1 (.clk(clk), .i_m('{s2_m[2], s2_m[3]}), .i_l('{s2_l[2], s2_l[3]}), .o_min(s3_m[2]), .o_max(s3_m[3]), .o_lmin(s3_l[2]), .o_lmax(s3_l[3]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l3_2 (.clk(clk), .i_m('{s2_m[4], s2_m[5]}), .i_l('{s2_l[4], s2_l[5]}), .o_min(s3_m[5]), .o_max(s3_m[4]), .o_lmin(s3_l[5]), .o_lmax(s3_l[4]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l3_3 (.clk(clk), .i_m('{s2_m[6], s2_m[7]}), .i_l('{s2_l[6], s2_l[7]}), .o_min(s3_m[7]), .o_max(s3_m[6]), .o_lmin(s3_l[7]), .o_lmax(s3_l[6]));
    
    logic [METRIC_W - 1 : 0] mid_m [0 : 7];
    logic [ LABEL_W - 1 : 0] mid_l [0 : 7];
    logic valid_mid;
    
    always_ff @(posedge clk) begin
        valid_mid <= valid_r;
        mid_m     <= s3_m;
        mid_l     <= s3_l;
    end
    
    logic [METRIC_W - 1 : 0] s4_m [0 : 7], s5_m [0 : 7], s6_m [0 : 7];
    logic [ LABEL_W - 1 : 0] s4_l [0 : 7], s5_l [0 : 7], s6_l [0 : 7];
    
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l4_0 (.clk(clk), .i_m('{mid_m[0], mid_m[4]}), .i_l('{mid_l[0], mid_l[4]}), .o_min(s4_m[0]), .o_max(s4_m[4]), .o_lmin(s4_l[0]), .o_lmax(s4_l[4]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l4_1 (.clk(clk), .i_m('{mid_m[1], mid_m[5]}), .i_l('{mid_l[1], mid_l[5]}), .o_min(s4_m[1]), .o_max(s4_m[5]), .o_lmin(s4_l[1]), .o_lmax(s4_l[5]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l4_2 (.clk(clk), .i_m('{mid_m[2], mid_m[6]}), .i_l('{mid_l[2], mid_l[6]}), .o_min(s4_m[2]), .o_max(s4_m[6]), .o_lmin(s4_l[2]), .o_lmax(s4_l[6]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l4_3 (.clk(clk), .i_m('{mid_m[3], mid_m[7]}), .i_l('{mid_l[3], mid_l[7]}), .o_min(s4_m[3]), .o_max(s4_m[7]), .o_lmin(s4_l[3]), .o_lmax(s4_l[7]));
    
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l5_0 (.clk(clk), .i_m('{s4_m[0], s4_m[2]}), .i_l('{s4_l[0], s4_l[2]}), .o_min(s5_m[0]), .o_max(s5_m[2]), .o_lmin(s5_l[0]), .o_lmax(s5_l[2]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l5_1 (.clk(clk), .i_m('{s4_m[1], s4_m[3]}), .i_l('{s4_l[1], s4_l[3]}), .o_min(s5_m[1]), .o_max(s5_m[3]), .o_lmin(s5_l[1]), .o_lmax(s5_l[3]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l5_2 (.clk(clk), .i_m('{s4_m[4], s4_m[6]}), .i_l('{s4_l[4], s4_l[6]}), .o_min(s5_m[4]), .o_max(s5_m[6]), .o_lmin(s5_l[4]), .o_lmax(s5_l[6]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l5_3 (.clk(clk), .i_m('{s4_m[5], s4_m[7]}), .i_l('{s4_l[5], s4_l[7]}), .o_min(s5_m[5]), .o_max(s5_m[7]), .o_lmin(s5_l[5]), .o_lmax(s5_l[7]));
    
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l6_0 (.clk(clk), .i_m('{s5_m[0], s5_m[1]}), .i_l('{s5_l[0], s5_l[1]}), .o_min(s6_m[0]), .o_max(s6_m[1]), .o_lmin(s6_l[0]), .o_lmax(s6_l[1]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l6_1 (.clk(clk), .i_m('{s5_m[2], s5_m[3]}), .i_l('{s5_l[2], s5_l[3]}), .o_min(s6_m[2]), .o_max(s6_m[3]), .o_lmin(s6_l[2]), .o_lmax(s6_l[3]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l6_2 (.clk(clk), .i_m('{s5_m[4], s5_m[5]}), .i_l('{s5_l[4], s5_l[5]}), .o_min(s6_m[4]), .o_max(s6_m[5]), .o_lmin(s6_l[4]), .o_lmax(s6_l[5]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l6_3 (.clk(clk), .i_m('{s5_m[6], s5_m[7]}), .i_l('{s5_l[6], s5_l[7]}), .o_min(s6_m[6]), .o_max(s6_m[7]), .o_lmin(s6_l[6]), .o_lmax(s6_l[7]));
    
    assign o_valid = valid_mid;
    assign o_m     = s6_m;
    assign o_l     = s6_l;

endmodule