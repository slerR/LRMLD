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

    logic [METRIC_W - 1 : 0] r0_m [0 : 7], r1_m [0 : 7], r2_m [0 : 7], r3_m [0 : 7], r4_m [0 : 7], r5_m [0 : 7], r6_m [0 : 7];
    logic [ LABEL_W - 1 : 0] r0_l [0 : 7], r1_l [0 : 7], r2_l [0 : 7], r3_l [0 : 7], r4_l [0 : 7], r5_l [0 : 7], r6_l [0 : 7];
    logic r0_v, r1_v, r2_v, r3_v, r4_v, r5_v, r6_v;

    always_ff @(posedge clk) begin
        r0_v <= i_valid;
        r0_m <= i_m;
        r0_l <= i_l;
    end

    logic [METRIC_W - 1 : 0] s1_m [0 : 7];
    logic [ LABEL_W - 1 : 0] s1_l [0 : 7];

    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l1_0 (.clk(clk), .i_m('{r0_m[0], r0_m[1]}), .i_l('{r0_l[0], r0_l[1]}), .o_min(s1_m[0]), .o_max(s1_m[1]), .o_lmin(s1_l[0]), .o_lmax(s1_l[1]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l1_1 (.clk(clk), .i_m('{r0_m[2], r0_m[3]}), .i_l('{r0_l[2], r0_l[3]}), .o_min(s1_m[3]), .o_max(s1_m[2]), .o_lmin(s1_l[3]), .o_lmax(s1_l[2]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l1_2 (.clk(clk), .i_m('{r0_m[4], r0_m[5]}), .i_l('{r0_l[4], r0_l[5]}), .o_min(s1_m[4]), .o_max(s1_m[5]), .o_lmin(s1_l[4]), .o_lmax(s1_l[5]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l1_3 (.clk(clk), .i_m('{r0_m[6], r0_m[7]}), .i_l('{r0_l[6], r0_l[7]}), .o_min(s1_m[7]), .o_max(s1_m[6]), .o_lmin(s1_l[7]), .o_lmax(s1_l[6]));

    always_ff @(posedge clk) begin
        r1_v <= r0_v;
        r1_m <= s1_m;
        r1_l <= s1_l;
    end

    logic [METRIC_W - 1 : 0] s2_m [0 : 7];
    logic [ LABEL_W - 1 : 0] s2_l [0 : 7];

    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l2_0 (.clk(clk), .i_m('{r1_m[0], r1_m[2]}), .i_l('{r1_l[0], r1_l[2]}), .o_min(s2_m[0]), .o_max(s2_m[2]), .o_lmin(s2_l[0]), .o_lmax(s2_l[2]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l2_1 (.clk(clk), .i_m('{r1_m[1], r1_m[3]}), .i_l('{r1_l[1], r1_l[3]}), .o_min(s2_m[1]), .o_max(s2_m[3]), .o_lmin(s2_l[1]), .o_lmax(s2_l[3]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l2_2 (.clk(clk), .i_m('{r1_m[4], r1_m[6]}), .i_l('{r1_l[4], r1_l[6]}), .o_min(s2_m[6]), .o_max(s2_m[4]), .o_lmin(s2_l[6]), .o_lmax(s2_l[4]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l2_3 (.clk(clk), .i_m('{r1_m[5], r1_m[7]}), .i_l('{r1_l[5], r1_l[7]}), .o_min(s2_m[7]), .o_max(s2_m[5]), .o_lmin(s2_l[7]), .o_lmax(s2_l[5]));

    always_ff @(posedge clk) begin
        r2_v <= r1_v;
        r2_m <= s2_m;
        r2_l <= s2_l;
    end

    logic [METRIC_W - 1 : 0] s3_m [0 : 7];
    logic [ LABEL_W - 1 : 0] s3_l [0 : 7];

    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l3_0 (.clk(clk), .i_m('{r2_m[0], r2_m[1]}), .i_l('{r2_l[0], r2_l[1]}), .o_min(s3_m[0]), .o_max(s3_m[1]), .o_lmin(s3_l[0]), .o_lmax(s3_l[1]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l3_1 (.clk(clk), .i_m('{r2_m[2], r2_m[3]}), .i_l('{r2_l[2], r2_l[3]}), .o_min(s3_m[2]), .o_max(s3_m[3]), .o_lmin(s3_l[2]), .o_lmax(s3_l[3]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l3_2 (.clk(clk), .i_m('{r2_m[4], r2_m[5]}), .i_l('{r2_l[4], r2_l[5]}), .o_min(s3_m[5]), .o_max(s3_m[4]), .o_lmin(s3_l[5]), .o_lmax(s3_l[4]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l3_3 (.clk(clk), .i_m('{r2_m[6], r2_m[7]}), .i_l('{r2_l[6], r2_l[7]}), .o_min(s3_m[7]), .o_max(s3_m[6]), .o_lmin(s3_l[7]), .o_lmax(s3_l[6]));

    always_ff @(posedge clk) begin
        r3_v <= r2_v;
        r3_m <= s3_m;
        r3_l <= s3_l;
    end

    logic [METRIC_W - 1 : 0] s4_m [0 : 7];
    logic [ LABEL_W - 1 : 0] s4_l [0 : 7];

    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l4_0 (.clk(clk), .i_m('{r3_m[0], r3_m[4]}), .i_l('{r3_l[0], r3_l[4]}), .o_min(s4_m[0]), .o_max(s4_m[4]), .o_lmin(s4_l[0]), .o_lmax(s4_l[4]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l4_1 (.clk(clk), .i_m('{r3_m[1], r3_m[5]}), .i_l('{r3_l[1], r3_l[5]}), .o_min(s4_m[1]), .o_max(s4_m[5]), .o_lmin(s4_l[1]), .o_lmax(s4_l[5]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l4_2 (.clk(clk), .i_m('{r3_m[2], r3_m[6]}), .i_l('{r3_l[2], r3_l[6]}), .o_min(s4_m[2]), .o_max(s4_m[6]), .o_lmin(s4_l[2]), .o_lmax(s4_l[6]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l4_3 (.clk(clk), .i_m('{r3_m[3], r3_m[7]}), .i_l('{r3_l[3], r3_l[7]}), .o_min(s4_m[3]), .o_max(s4_m[7]), .o_lmin(s4_l[3]), .o_lmax(s4_l[7]));

    always_ff @(posedge clk) begin
        r4_v <= r3_v;
        r4_m <= s4_m;
        r4_l <= s4_l;
    end

    logic [METRIC_W - 1 : 0] s5_m [0 : 7];
    logic [ LABEL_W - 1 : 0] s5_l [0 : 7];

    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l5_0 (.clk(clk), .i_m('{r4_m[0], r4_m[2]}), .i_l('{r4_l[0], r4_l[2]}), .o_min(s5_m[0]), .o_max(s5_m[2]), .o_lmin(s5_l[0]), .o_lmax(s5_l[2]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l5_1 (.clk(clk), .i_m('{r4_m[1], r4_m[3]}), .i_l('{r4_l[1], r4_l[3]}), .o_min(s5_m[1]), .o_max(s5_m[3]), .o_lmin(s5_l[1]), .o_lmax(s5_l[3]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l5_2 (.clk(clk), .i_m('{r4_m[4], r4_m[6]}), .i_l('{r4_l[4], r4_l[6]}), .o_min(s5_m[4]), .o_max(s5_m[6]), .o_lmin(s5_l[4]), .o_lmax(s5_l[6]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l5_3 (.clk(clk), .i_m('{r4_m[5], r4_m[7]}), .i_l('{r4_l[5], r4_l[7]}), .o_min(s5_m[5]), .o_max(s5_m[7]), .o_lmin(s5_l[5]), .o_lmax(s5_l[7]));

    always_ff @(posedge clk) begin
        r5_v <= r4_v;
        r5_m <= s5_m;
        r5_l <= s5_l;
    end

    logic [METRIC_W - 1 : 0] s6_m [0 : 7];
    logic [ LABEL_W - 1 : 0] s6_l [0 : 7];

    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l6_0 (.clk(clk), .i_m('{r5_m[0], r5_m[1]}), .i_l('{r5_l[0], r5_l[1]}), .o_min(s6_m[0]), .o_max(s6_m[1]), .o_lmin(s6_l[0]), .o_lmax(s6_l[1]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l6_1 (.clk(clk), .i_m('{r5_m[2], r5_m[3]}), .i_l('{r5_l[2], r5_l[3]}), .o_min(s6_m[2]), .o_max(s6_m[3]), .o_lmin(s6_l[2]), .o_lmax(s6_l[3]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l6_2 (.clk(clk), .i_m('{r5_m[4], r5_m[5]}), .i_l('{r5_l[4], r5_l[5]}), .o_min(s6_m[4]), .o_max(s6_m[5]), .o_lmin(s6_l[4]), .o_lmax(s6_l[5]));
    cas_l #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .USE_FF(0)) l6_3 (.clk(clk), .i_m('{r5_m[6], r5_m[7]}), .i_l('{r5_l[6], r5_l[7]}), .o_min(s6_m[6]), .o_max(s6_m[7]), .o_lmin(s6_l[6]), .o_lmax(s6_l[7]));

    always_comb begin
        o_valid = r5_v;
        o_m     = s6_m;
        o_l     = s6_l;
    end

endmodule