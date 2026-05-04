`timescale 1ns / 1ps

module sort_2 #(
    parameter METRIC_W = 10,
    parameter LABEL_W  = 8
)(
    input  logic                     clk,
    input  logic                     i_valid,
    input  logic [METRIC_W - 1 : 0]  i_m [0 : 1],
    input  logic [ LABEL_W - 1 : 0]  i_l [0 : 1],
    output logic                     o_valid,
    output logic [METRIC_W - 1 : 0]  o_m [0 : 1],
    output logic [ LABEL_W - 1 : 0]  o_l [0 : 1]
);

    logic [METRIC_W - 1 : 0] m_r [0 : 1];
    logic [ LABEL_W - 1 : 0] l_r [0 : 1];
    logic valid_r;

    always_ff @(posedge clk) begin
        valid_r <= i_valid;
        m_r     <= i_m;
        l_r     <= i_l;
    end

    logic [METRIC_W - 1 : 0] min_m;
    logic [METRIC_W - 1 : 0] max_m;
    logic [ LABEL_W - 1 : 0] min_l;
    logic [ LABEL_W - 1 : 0] max_l;

    cas_l #(
        .METRIC_W (METRIC_W),
        .LABEL_W  (LABEL_W),
        .USE_FF   (0)
    ) u_cmp (
        .clk   (clk),
        .i_m   ('{m_r[0], m_r[1]}),
        .i_l   ('{l_r[0], l_r[1]}),
        .o_min (min_m),
        .o_max (max_m),
        .o_lmin(min_l),
        .o_lmax(max_l)
    );

    assign o_valid = valid_r;

    always_comb begin
        o_m[0] = min_m;
        o_m[1] = max_m;
        o_l[0] = min_l;
        o_l[1] = max_l;
    end

endmodule