module merge_tree # (
    parameter                       NUM_LISTS = 5,
    parameter                       N_INPUTS  = 4,
    parameter                       METRIC_W  = 8,
    parameter                       LABEL_W   = 2,
    localparam                      FF_P_W    = $clog2(2*N_INPUTS),
    parameter [0 : FF_P_W - 1]      FF_P      = {FF_P_W{1'b1}}
) (
    input  logic                    clk,
    input  logic                    i_valid,
    input  logic [METRIC_W - 1 : 0] i_m [NUM_LISTS][N_INPUTS],
    input  logic [ LABEL_W - 1 : 0] i_l [NUM_LISTS][N_INPUTS],
    output logic [METRIC_W - 1 : 0] o_m [N_INPUTS],
    output logic [ LABEL_W - 1 : 0] o_l [N_INPUTS],
    output logic                    o_valid
);

    localparam                      P_INPUTS   = 2**$clog2(N_INPUTS);
    localparam                      TREE_DEPTH = $clog2(NUM_LISTS);
    localparam int                  FF_LATENCY = $countones(FF_P);

    localparam logic [METRIC_W - 1 : 0] MAX_METRIC = {METRIC_W{1'b1}};
    localparam logic [ LABEL_W - 1 : 0] L_PAD      = {LABEL_W{1'b0}};

    logic [METRIC_W - 1 : 0]        tree_m [TREE_DEPTH + 1][NUM_LISTS][P_INPUTS];
    logic [ LABEL_W - 1 : 0]        tree_l [TREE_DEPTH + 1][NUM_LISTS][P_INPUTS];
    logic                           tree_v [TREE_DEPTH + 1];
    logic                           layer_v[TREE_DEPTH][NUM_LISTS];

    assign tree_v[0] = i_valid;

    generate
        for (genvar i = 0; i < NUM_LISTS; i = i + 1) begin : gen_pad
            for (genvar j = 0; j < P_INPUTS; j = j + 1) begin : gen_pad_inner
                if (j < N_INPUTS) begin
                    assign tree_m[0][i][j] = i_m[i][j];
                    assign tree_l[0][i][j] = i_l[i][j];
                end else begin
                    assign tree_m[0][i][j] = MAX_METRIC;
                    assign tree_l[0][i][j] = L_PAD;
                end
            end
        end

        for (genvar d = 0; d < TREE_DEPTH; d = d + 1) begin : gen_layer
            localparam int num_nodes  = (NUM_LISTS + (1 << d) - 1) >> d;
            localparam int next_nodes = (num_nodes + 1) >> 1;

            for (genvar n = 0; n < next_nodes; n = n + 1) begin : gen_node
                if ((2*n + 1) < num_nodes) begin
                    merge_2n_n # (
                        .N_INPUTS (P_INPUTS),
                        .METRIC_W (METRIC_W),
                        .LABEL_W  (LABEL_W),
                        .FF_P     (FF_P)
                    ) merge_inst (
                        .clk     (clk),
                        .i_valid (tree_v[d]),
                        .i_m0    (tree_m[d][2*n]),
                        .i_l0    (tree_l[d][2*n]),
                        .i_m1    (tree_m[d][2*n + 1]),
                        .i_l1    (tree_l[d][2*n + 1]),
                        .o_valid (layer_v[d][n]),
                        .o_m     (tree_m[d+1][n]),
                        .o_l     (tree_l[d+1][n])
                    );
                end else begin
                    logic [0 : 0] pass_v;

                    for (genvar j = 0; j < P_INPUTS; j = j + 1) begin : gen_delay
                        delay_line #(
                            .DELAY (FF_LATENCY),
                            .WIDTH (METRIC_W)
                        ) delay_m (
                            .clk      (clk),
                            .data_in  (tree_m[d][2*n][j]),
                            .data_out (tree_m[d+1][n][j])
                        );

                        delay_line #(
                            .DELAY (FF_LATENCY),
                            .WIDTH (LABEL_W)
                        ) delay_l (
                            .clk      (clk),
                            .data_in  (tree_l[d][2*n][j]),
                            .data_out (tree_l[d+1][n][j])
                        );
                    end

                    delay_line #(
                        .DELAY (FF_LATENCY),
                        .WIDTH (1)
                    ) delay_v (
                        .clk      (clk),
                        .data_in  (tree_v[d]),
                        .data_out (pass_v)
                    );

                    assign layer_v[d][n] = pass_v[0];
                end
            end

            assign tree_v[d+1] = layer_v[d][0];
        end
    endgenerate

    generate
        for (genvar j = 0; j < N_INPUTS; j = j + 1) begin : gen_out
            assign o_m[j] = tree_m[TREE_DEPTH][0][j];
            assign o_l[j] = tree_l[TREE_DEPTH][0][j];
        end
    endgenerate

    assign o_valid = tree_v[TREE_DEPTH];

endmodule