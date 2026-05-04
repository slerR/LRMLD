module cas #(
    parameter METRIC_W = 8,
    parameter LABEL_W  = 2
)(
    input  logic [METRIC_W - 1 : 0] i_m0,
    input  logic [METRIC_W - 1 : 0] i_m1,
    input  logic [LABEL_W  - 1 : 0] i_l0,
    input  logic [LABEL_W  - 1 : 0] i_l1,
    output logic [METRIC_W - 1 : 0] o_min,
    output logic [METRIC_W - 1 : 0] o_max,
    output logic [LABEL_W  - 1 : 0] o_lmin,
    output logic [LABEL_W  - 1 : 0] o_lmax
);

    always_comb begin
        if (i_m0 < i_m1) begin
            o_min  = i_m0;
            o_max  = i_m1;
            o_lmin = i_l0;
            o_lmax = i_l1;
        end
        else begin
            o_min  = i_m1;
            o_max  = i_m0;
            o_lmin = i_l1;
            o_lmax = i_l0;
        end
    end

endmodule


