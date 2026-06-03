`timescale 1ns / 1ps

// Latency, cycles: 
// Parallel (IS_SEQ=0): 1 + log(NUM_LISTS)*$countones({log(2*N_INPUTS){1'b1}})
// Sequential (IS_SEQ=1): 1 + log(NUM_LISTS)*$countones({log(2*N_INPUTS){1'b1}}) + (NUM_LISTS - 1)
module merge_tree # (
    parameter                       NUM_LISTS = 5,
    parameter                       N_INPUTS  = 4,
    parameter                       METRIC_W  = 8,
    parameter                       LABEL_W   = 2,
    parameter logic                 IS_SEQ    = 0, // 0 - Parallel, 1 - Sequential
    localparam                      P_INPUTS  = 2**$clog2(N_INPUTS),
    localparam                      FF_P_W    = $clog2(2*P_INPUTS),
    localparam [0:FF_P_W-1]         FF_P = {FF_P_W{1'b1}}
) (
    input  logic                    clk,
    input  logic                    i_valid,
    input  logic [METRIC_W - 1 : 0] i_m [NUM_LISTS][N_INPUTS],
    input  logic [ LABEL_W - 1 : 0] i_l [NUM_LISTS][N_INPUTS],
    output logic [METRIC_W - 1 : 0] o_m [N_INPUTS],
    output logic [ LABEL_W - 1 : 0] o_l [N_INPUTS],
    output logic                    o_valid
);

    localparam                          TREE_DEPTH = $clog2(NUM_LISTS);
    localparam int                      FF_LATENCY = $countones(FF_P);
    localparam logic [METRIC_W - 1 : 0] MAX_METRIC = {METRIC_W{1'b1}};
    localparam logic [ LABEL_W - 1 : 0] L_PAD      = {LABEL_W{1'b0}};

    generate
        if (!IS_SEQ) begin : PARALLEL_TREE
            logic [METRIC_W - 1 : 0]        i_m_r [NUM_LISTS][N_INPUTS];
            logic [ LABEL_W - 1 : 0]        i_l_r [NUM_LISTS][N_INPUTS];
            logic                           i_valid_r;

            always_ff @(posedge clk) begin
                i_valid_r <= i_valid;
                if (i_valid) begin
                    for (int i = 0; i < NUM_LISTS; i++) begin
                        for (int j = 0; j < N_INPUTS; j++) begin
                            i_m_r[i][j] <= i_m[i][j];
                            i_l_r[i][j] <= i_l[i][j];
                        end
                    end
                end
            end

            logic [METRIC_W - 1 : 0]        tree_m [TREE_DEPTH + 1][NUM_LISTS][P_INPUTS];
            logic [ LABEL_W - 1 : 0]        tree_l [TREE_DEPTH + 1][NUM_LISTS][P_INPUTS];
            logic                           tree_v [TREE_DEPTH + 1];
            logic                           layer_v[TREE_DEPTH][NUM_LISTS];

            assign tree_v[0] = i_valid_r;

            for (genvar i = 0; i < NUM_LISTS; i = i + 1) begin : gen_pad
                for (genvar j = 0; j < P_INPUTS; j = j + 1) begin : gen_pad_inner
                    if (j < N_INPUTS) begin
                        assign tree_m[0][i][j] = i_m_r[i][j];
                        assign tree_l[0][i][j] = i_l_r[i][j];
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
                            .N_INPUTS (P_INPUTS), .METRIC_W (METRIC_W), .LABEL_W  (LABEL_W), .FF_P (FF_P)
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
                            delay_line #(.DELAY(FF_LATENCY), .WIDTH(METRIC_W)) delay_m (
                                .clk(clk), .data_in(tree_m[d][2*n][j]), .data_out(tree_m[d+1][n][j])
                            );
                            delay_line #(.DELAY(FF_LATENCY), .WIDTH(LABEL_W)) delay_l (
                                .clk(clk), .data_in(tree_l[d][2*n][j]), .data_out(tree_l[d+1][n][j])
                            );
                        end
                        delay_line #(.DELAY(FF_LATENCY), .WIDTH(1)) delay_v (
                            .clk(clk), .data_in(tree_v[d]), .data_out(pass_v)
                        );
                        assign layer_v[d][n] = pass_v[0];
                    end
                end
                assign tree_v[d+1] = layer_v[d][0];
            end

            for (genvar j = 0; j < N_INPUTS; j = j + 1) begin : gen_out
                assign o_m[j] = tree_m[TREE_DEPTH][0][j];
                assign o_l[j] = tree_l[TREE_DEPTH][0][j];
            end
            assign o_valid = tree_v[TREE_DEPTH];

        end else begin : SEQUENTIAL_TREE           
            function automatic int get_items(int stage);
                int items = NUM_LISTS;
                for (int i = 0; i < stage; i++) begin
                    items = (items + 1) / 2;
                end
                return items;
            endfunction

            logic [METRIC_W - 1 : 0] seq_m_r [N_INPUTS];
            logic [ LABEL_W - 1 : 0] seq_l_r [N_INPUTS];
            logic                    seq_v_r;

            always_ff @(posedge clk) begin
                seq_v_r <= i_valid;
                if (i_valid) begin
                    for (int j = 0; j < N_INPUTS; j++) begin
                        seq_m_r[j] <= i_m[0][j];
                        seq_l_r[j] <= i_l[0][j];
                    end
                end
            end

            logic [METRIC_W - 1 : 0] stg_m [0 : TREE_DEPTH][P_INPUTS];
            logic [ LABEL_W - 1 : 0] stg_l [0 : TREE_DEPTH][P_INPUTS];
            logic                    stg_v [0 : TREE_DEPTH];

            always_comb begin
                for (int j = 0; j < P_INPUTS; j++) begin
                    if (j < N_INPUTS) begin
                        stg_m[0][j] = seq_m_r[j];
                        stg_l[0][j] = seq_l_r[j];
                    end else begin
                        stg_m[0][j] = MAX_METRIC;
                        stg_l[0][j] = L_PAD;
                    end
                end
                stg_v[0] = seq_v_r;
            end

            for (genvar s = 0; s < TREE_DEPTH; s++) begin : STG
                localparam int ITEMS_IN = get_items(s);

                logic [METRIC_W - 1 : 0] hold_m [P_INPUTS];
                logic [ LABEL_W - 1 : 0] hold_l [P_INPUTS];
                logic                    toggle = 1'b0;
                logic [$clog2(ITEMS_IN+1)-1 : 0] cnt = '0;

                logic bypass;
                logic do_merge;
                logic do_bypass;

                assign bypass    = (cnt == ITEMS_IN - 1) && (toggle == 1'b0);
                assign do_merge  = stg_v[s] && (toggle == 1'b1);
                assign do_bypass = stg_v[s] && bypass;

                always_ff @(posedge clk) begin
                    if (stg_v[s]) begin
                        if (toggle == 1'b0) begin
                            for (int j = 0; j < P_INPUTS; j++) begin
                                hold_m[j] <= stg_m[s][j];
                                hold_l[j] <= stg_l[s][j];
                            end
                        end

                        if (cnt == ITEMS_IN - 1) begin
                            cnt    <= '0;
                            toggle <= 1'b0;
                        end else begin
                            cnt    <= cnt + 1'b1;
                            toggle <= ~toggle;
                        end
                    end
                end

                logic [METRIC_W - 1 : 0] merge_m [P_INPUTS];
                logic [ LABEL_W - 1 : 0] merge_l [P_INPUTS];
                logic                    merge_v;

                logic [METRIC_W - 1 : 0] bypass_m [P_INPUTS];
                logic [ LABEL_W - 1 : 0] bypass_l [P_INPUTS];
                logic                    bypass_v;

                merge_2n_n #(
                    .N_INPUTS (P_INPUTS), .METRIC_W (METRIC_W), .LABEL_W  (LABEL_W), .FF_P (FF_P)
                ) merge_inst (
                    .clk     (clk),
                    .i_valid (do_merge),
                    .i_m0    (hold_m),
                    .i_l0    (hold_l),
                    .i_m1    (stg_m[s]),
                    .i_l1    (stg_l[s]),
                    .o_valid (merge_v),
                    .o_m     (merge_m),
                    .o_l     (merge_l)
                );

                if (FF_LATENCY > 0) begin : gen_byp_del
                    for (genvar j = 0; j < P_INPUTS; j++) begin : b_del
                        delay_line #(.DELAY(FF_LATENCY), .WIDTH(METRIC_W)) dl_m (.clk(clk), .data_in(stg_m[s][j]), .data_out(bypass_m[j]));
                        delay_line #(.DELAY(FF_LATENCY), .WIDTH(LABEL_W))  dl_l (.clk(clk), .data_in(stg_l[s][j]), .data_out(bypass_l[j]));
                    end
                    delay_line #(.DELAY(FF_LATENCY), .WIDTH(1)) dl_v (.clk(clk), .data_in(do_bypass), .data_out(bypass_v));
                end else begin : gen_byp_nodel
                    always_comb begin
                        for (int j = 0; j < P_INPUTS; j++) begin
                            bypass_m[j] = stg_m[s][j];
                            bypass_l[j] = stg_l[s][j];
                        end
                        bypass_v = do_bypass;
                    end
                end

                assign stg_v[s+1] = merge_v | bypass_v;
                always_comb begin
                    for (int j = 0; j < P_INPUTS; j++) begin
                        stg_m[s+1][j] = bypass_v ? bypass_m[j] : merge_m[j];
                        stg_l[s+1][j] = bypass_v ? bypass_l[j] : merge_l[j];
                    end
                end
            end

            for (genvar j = 0; j < N_INPUTS; j++) begin : out_map
                assign o_m[j] = stg_m[TREE_DEPTH][j];
                assign o_l[j] = stg_l[TREE_DEPTH][j];
            end
            assign o_valid = stg_v[TREE_DEPTH];

        end
    endgenerate

endmodule