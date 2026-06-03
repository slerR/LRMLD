module merge_2n_n # (
    parameter                       N_INPUTS = 4,
    parameter                       METRIC_W = 8,
    parameter                       LABEL_W  = 2,
    localparam                      FF_P_W = $clog2(2*N_INPUTS),
    parameter [0:FF_P_W-1]          FF_P = {FF_P_W/2{2'b10}}
) (
    input  logic                    clk,
    input  logic                    i_valid,
    input  logic [METRIC_W - 1 : 0] i_m0[N_INPUTS],
    input  logic [ LABEL_W - 1 : 0] i_l0[N_INPUTS],
    input  logic [METRIC_W - 1 : 0] i_m1[N_INPUTS],
    input  logic [ LABEL_W - 1 : 0] i_l1[N_INPUTS],
    output logic [METRIC_W - 1 : 0] o_m [N_INPUTS],
    output logic [ LABEL_W - 1 : 0] o_l [N_INPUTS],
    output logic                    o_valid 
);

    localparam                      n   = 2 * N_INPUTS;
    localparam                      p   = N_INPUTS;
    logic [METRIC_W - 1 : 0]        tmpm[$clog2(n) + 1][2*N_INPUTS];
    logic [ LABEL_W - 1 : 0]        tmpl[$clog2(n) + 1][2*N_INPUTS];
    logic [$clog2(n) : 0]           valid_pipe;

    assign valid_pipe[0] = i_valid;

    for (genvar i = 0; i < N_INPUTS; i = i + 1) begin
        assign tmpm[0][i           ] = i_m0[i];
        assign tmpl[0][i           ] = i_l0[i];
        assign tmpm[0][N_INPUTS + i] = i_m1[i];
        assign tmpl[0][N_INPUTS + i] = i_l1[i];
    end

    for (genvar k = p; k >= 1; k = k / 2) begin
        localparam layer = $clog2(p / k);
        
        if (FF_P[layer]) begin
            always_ff @(posedge clk) begin
                valid_pipe[layer + 1] <= valid_pipe[layer];
            end
        end
        else begin
            assign valid_pipe[layer + 1] = valid_pipe[layer];
        end

        for (genvar j = (k == p) ? 0 : k; j < p; j = j + 2*k) begin
            for (genvar i = 0; i < k; i = i + 1) begin
                if ($floor((i+j)/n) == $floor((i+j+k)/n)) begin
                    cas_l # (
                        .METRIC_W   (METRIC_W), 
                        .LABEL_W    (LABEL_W), 
                        .USE_FF     (FF_P[layer])) 
                    cas_l_dut(
                        .clk        (clk), 
                        .i_m        ({tmpm[layer    ][i+j  ], tmpm[layer    ][i+j+k]}), 
                        .i_l        ({tmpl[layer    ][i+j  ], tmpl[layer    ][i+j+k]}), 
                        .o_min      (tmpm[layer + 1][i+j  ]), 
                        .o_max      (tmpm[layer + 1][i+j+k]), 
                        .o_lmin     (tmpl[layer + 1][i+j  ]), 
                        .o_lmax     (tmpl[layer + 1][i+j+k]));
                end
            end
        end
        
        if (layer >= 1) begin
            for (genvar indFF = 0; indFF < k; indFF = indFF + 1) begin
                delay_line # (
                        .DELAY      (FF_P[layer]),
                        .WIDTH      (METRIC_W + LABEL_W), 
                        .STYLE      ("auto")) 
                delay_line_dut(
                        .clk        (clk), 
                        .data_in    ({tmpm[layer    ][indFF], tmpl[layer    ][indFF]}),
                        .data_out   ({tmpm[layer + 1][indFF], tmpl[layer + 1][indFF]}));
            end
        end
    end
    
    assign o_m = tmpm[$clog2(n)][0 : N_INPUTS - 1];
    assign o_l = tmpl[$clog2(n)][0 : N_INPUTS - 1];
    assign o_valid = valid_pipe[$clog2(n)];

endmodule