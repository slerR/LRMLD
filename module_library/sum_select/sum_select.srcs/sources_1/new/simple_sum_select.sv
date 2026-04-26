module simple_sum_select #(
    parameter  METRIC_W = 12,
    parameter  LABEL_W  = 6,
    parameter  LABEL_W1 = 6,
    localparam SLICE_W  = METRIC_W,         
    localparam SUM_W    = METRIC_W + 1,            
    localparam CONC_W   = LABEL_W + LABEL_W1
)(
    input  logic                      clk,
    input  logic [4*METRIC_W - 1 : 0] i_metrics,
    input  logic [ 4*LABEL_W - 1 : 0] i_labels,
    input  logic [4*METRIC_W - 1 : 0] i_metrics1,
    input  logic [4*LABEL_W1 - 1 : 0] i_labels1,
    output logic [4*METRIC_W - 1 : 0] o_metrics,    
    output logic [4*(CONC_W) - 1 : 0] o_labels
);

localparam logic [METRIC_W - 1 : 0] MAX_METRIC  = '{METRIC_W{1'b1}};

logic [ SUM_W - 1 : 0] sig_summ [0 : 7];
logic [CONC_W - 1 : 0] sig_conc [0 : 7];

// задержка нименьшей суммы и соответствующей конкатенации
logic [ SUM_W - 1 : 0] sig_summ_d [0 : 1];
logic [CONC_W - 1 : 0] sig_conc_d [0 : 1];

logic [ SUM_W - 1 : 0] sig_summ_r [0 : 7];
logic [CONC_W - 1 : 0] sig_conc_r [0 : 7];

logic                  flag       [0 : 4];

logic [ SUM_W - 1 : 0] c_slots    [0 : 2];
logic [CONC_W - 1 : 0] l_slots    [0 : 2];

logic [ SUM_W - 1 : 0] c_slots_r  [0 : 2];
logic [CONC_W - 1 : 0] l_slots_r  [0 : 2];

logic [ SUM_W - 1 : 0] c_m1       [0 : 2];
logic [ SUM_W - 1 : 0] c_m1_r     [0 : 2];
logic [ SUM_W - 1 : 0] c_m2       [0 : 2];
logic [ SUM_W - 1 : 0] c_m3temp   [0 : 2];

logic [CONC_W - 1 : 0] l_m1       [0 : 2];
logic [CONC_W - 1 : 0] l_m1_r     [0 : 2];
logic [CONC_W - 1 : 0] l_m2       [0 : 2];
logic [CONC_W - 1 : 0] l_m3temp   [0 : 2];

logic [ SUM_W - 1 : 0] c_final    [0 : 3];   
logic [CONC_W - 1 : 0] l_final    [0 : 3];

logic                  If0, If1, If2;

logic [ SUM_W - 1 : 0] sort1_min;
logic [ SUM_W - 1 : 0] sort1_max;

logic [ SUM_W - 1 : 0] sort2_min;
logic [ SUM_W - 1 : 0] sort2_max;

logic [ SUM_W - 1 : 0] sort3_min;
logic [ SUM_W - 1 : 0] sort3_max;

always_comb begin       
    sig_summ[0] = {1'b0, i_metrics [4*SLICE_W - 1 : 3*SLICE_W]} +
                  {1'b0, i_metrics1[4*SLICE_W - 1 : 3*SLICE_W]};

    sig_summ[1] = {1'b0, i_metrics [4*SLICE_W - 1 : 3*SLICE_W]} +
                  {1'b0, i_metrics1[3*SLICE_W - 1 : 2*SLICE_W]};

    sig_summ[2] = {1'b0, i_metrics [3*SLICE_W - 1 : 2*SLICE_W]} +
                  {1'b0, i_metrics1[4*SLICE_W - 1 : 3*SLICE_W]};

    sig_summ[3] = {1'b0, i_metrics [3*SLICE_W - 1 : 2*SLICE_W]} +
                  {1'b0, i_metrics1[3*SLICE_W - 1 : 2*SLICE_W]};

    sig_summ[4] = {1'b0, i_metrics [4*SLICE_W - 1 : 3*SLICE_W]} +
                  {1'b0, i_metrics1[2*SLICE_W - 1 : 1*SLICE_W]};

    sig_summ[5] = {1'b0, i_metrics [4*SLICE_W - 1 : 3*SLICE_W]} +
                  {1'b0, i_metrics1[1*SLICE_W - 1 : 0*SLICE_W]};

    sig_summ[6] = {1'b0, i_metrics [2*SLICE_W - 1 : 1*SLICE_W]} +
                  {1'b0, i_metrics1[4*SLICE_W - 1 : 3*SLICE_W]};

    sig_summ[7] = {1'b0, i_metrics [1*SLICE_W - 1 : 0*SLICE_W]} +
                  {1'b0, i_metrics1[4*SLICE_W - 1 : 3*SLICE_W]};
end

always_comb begin
    sig_conc[0] = {i_labels[4*LABEL_W - 1 : 3*LABEL_W], i_labels1[4*LABEL_W1 - 1 : 3*LABEL_W1]};
    sig_conc[1] = {i_labels[4*LABEL_W - 1 : 3*LABEL_W], i_labels1[3*LABEL_W1 - 1 : 2*LABEL_W1]};
    sig_conc[2] = {i_labels[3*LABEL_W - 1 : 2*LABEL_W], i_labels1[4*LABEL_W1 - 1 : 3*LABEL_W1]};
    sig_conc[3] = {i_labels[3*LABEL_W - 1 : 2*LABEL_W], i_labels1[3*LABEL_W1 - 1 : 2*LABEL_W1]};
    sig_conc[4] = {i_labels[4*LABEL_W - 1 : 3*LABEL_W], i_labels1[2*LABEL_W1 - 1 : 1*LABEL_W1]};
    sig_conc[5] = {i_labels[4*LABEL_W - 1 : 3*LABEL_W], i_labels1[1*LABEL_W1 - 1 : 0*LABEL_W1]};
    sig_conc[6] = {i_labels[2*LABEL_W - 1 : 1*LABEL_W], i_labels1[4*LABEL_W1 - 1 : 3*LABEL_W1]};
    sig_conc[7] = {i_labels[1*LABEL_W - 1 : 0*LABEL_W], i_labels1[4*LABEL_W1 - 1 : 3*LABEL_W1]};
end

always_ff @(posedge clk) begin
    for (int k = 0; k < 8; k++) begin
        sig_summ_r[k] <= sig_summ[k];
        sig_conc_r[k] <= sig_conc[k];
    end
    
    sig_summ_d[0] <= sig_summ_r[0];
    sig_conc_d[0] <= sig_conc_r[0];
             
    sig_summ_d[1] <= sig_summ_d[0];
    sig_conc_d[1] <= sig_conc_d[0];
end

comparator #(.DATA_W(SUM_W)) comp1(
    .i_data (sig_summ_r[3]),
    .i_data1(sig_summ_r[4]),
    .o_flag (flag[4])
);

comparator #(.DATA_W(SUM_W)) comp2(
    .i_data (sig_summ_r[3]),
    .i_data1(sig_summ_r[6]),
    .o_flag (flag[3])
);

comparator #(.DATA_W(SUM_W)) comp3(
    .i_data (sig_summ_r[4]),
    .i_data1(sig_summ_r[6]),
    .o_flag (flag[2])
);

comparator #(.DATA_W(SUM_W)) comp4(
    .i_data (sig_summ_r[5]),
    .i_data1(sig_summ_r[2]),
    .o_flag (flag[1])
);

comparator #(.DATA_W(SUM_W)) comp5(
    .i_data (sig_summ_r[7]),
    .i_data1(sig_summ_r[1]),
    .o_flag (flag[0])
);

always_comb begin
    if ({flag[4], flag[3]} == 2'b11) begin
        c_slots[0] = sig_summ_r[1];
        c_slots[1] = sig_summ_r[2];
        c_slots[2] = sig_summ_r[3];
        l_slots[0] = sig_conc_r[1];
        l_slots[1] = sig_conc_r[2];
        l_slots[2] = sig_conc_r[3];
    end
    else if (flag[2] && flag[1]) begin
        c_slots[0] = sig_summ_r[1];
        c_slots[1] = sig_summ_r[4];
        c_slots[2] = sig_summ_r[5];
        l_slots[0] = sig_conc_r[1];
        l_slots[1] = sig_conc_r[4];
        l_slots[2] = sig_conc_r[5];
    end
    else if (flag[2] && (!flag[1])) begin
        c_slots[0] = sig_summ_r[1];
        c_slots[1] = sig_summ_r[4];
        c_slots[2] = sig_summ_r[2];
        l_slots[0] = sig_conc_r[1];
        l_slots[1] = sig_conc_r[4];
        l_slots[2] = sig_conc_r[2];
    end
    else if ((!flag[2]) && flag[0]) begin
        c_slots[0] = sig_summ_r[2];
        c_slots[1] = sig_summ_r[6];
        c_slots[2] = sig_summ_r[7];
        l_slots[0] = sig_conc_r[2];
        l_slots[1] = sig_conc_r[6];
        l_slots[2] = sig_conc_r[7];
    end
    else if ((!flag[2]) && (!flag[0])) begin
        c_slots[0] = sig_summ_r[2];
        c_slots[1] = sig_summ_r[6];
        c_slots[2] = sig_summ_r[1];
        l_slots[0] = sig_conc_r[2];
        l_slots[1] = sig_conc_r[6];
        l_slots[2] = sig_conc_r[1];
    end
    else begin
        c_slots[0] = '0;
        c_slots[1] = '0;
        c_slots[2] = '0;
        l_slots[0] = '0;
        l_slots[1] = '0;
        l_slots[2] = '0;
    end
end

always_ff @(posedge clk) begin
    for (int m = 0; m < 3; m++) begin
        c_slots_r[m] <= c_slots[m];
        l_slots_r[m] <= l_slots[m];
    end
end

comparator #(.DATA_W(SUM_W)) sort1(
    .i_data (c_slots_r[1]),
    .i_data1(c_slots_r[2]),
    .o_flag (If0),
    .o_min  (sort1_min),
    .o_max  (sort1_max)
);

always_comb begin
    c_m1[0] = c_slots_r[0];
    c_m1[1] = sort1_min;
    c_m1[2] = sort1_max;
    if (If0) begin
        l_m1[0] = l_slots_r[0];
        l_m1[1] = l_slots_r[1];
        l_m1[2] = l_slots_r[2];
    end else begin
        l_m1[0] = l_slots_r[0];
        l_m1[1] = l_slots_r[2];
        l_m1[2] = l_slots_r[1];
    end
end

always_ff @(posedge clk) begin
    for (int n = 0; n < 3; n++) begin
        c_m1_r[n] <= c_m1[n];
        l_m1_r[n] <= l_m1[n];
    end
end

comparator #(.DATA_W(SUM_W)) sort2(
    .i_data (c_m1_r[0]),
    .i_data1(c_m1_r[1]),
    .o_flag (If1),
    .o_min  (sort2_min),
    .o_max  (sort2_max)
);

always_comb begin
    c_m2[0] = sort2_min;
    c_m2[1] = sort2_max;
    c_m2[2] = c_m1_r[2];

    if (If1) begin
        l_m2[0] = l_m1_r[0];
        l_m2[1] = l_m1_r[1];
        l_m2[2] = l_m1_r[2];
    end else begin
        l_m2[0] = l_m1_r[1];
        l_m2[1] = l_m1_r[0];
        l_m2[2] = l_m1_r[2];
    end
end

comparator #(.DATA_W(SUM_W)) sort3(
    .i_data (c_m2[1]),
    .i_data1(c_m2[2]),
    .o_flag (If2),
    .o_min  (sort3_min),
    .o_max  (sort3_max)
);

always_comb begin
    c_m3temp[0] = c_m2[0];
    c_m3temp[1] = sort3_min;
    c_m3temp[2] = sort3_max;

    if (If2) begin
        l_m3temp[0] = l_m2[0];
        l_m3temp[1] = l_m2[1];
        l_m3temp[2] = l_m2[2];
    end else begin
        l_m3temp[0] = l_m2[0];
        l_m3temp[1] = l_m2[2];
        l_m3temp[2] = l_m2[1];
    end
end

always_comb begin
    c_final[0] = sig_summ_d[1];   
    c_final[1] = c_m3temp[0];
    c_final[2] = c_m3temp[1];
    c_final[3] = c_m3temp[2];

    l_final[0] = sig_conc_d[0];   
    l_final[1] = l_m3temp[0];
    l_final[2] = l_m3temp[1];
    l_final[3] = l_m3temp[2];
end

always_comb begin
    for (int i = 0; i < 4; i = i + 1) begin
        if (c_final[i][SUM_W - 1] == 1'b1) begin
            o_metrics[(4*METRIC_W - 1) - i*METRIC_W -: METRIC_W] = MAX_METRIC;
        end else begin
            o_metrics[(4*METRIC_W - 1) - i*METRIC_W -: METRIC_W] = c_final[i][METRIC_W - 1 : 0];
        end
        o_labels [(4*CONC_W - 1) - i*CONC_W -: CONC_W] = l_final[i];
    end
end

endmodule
