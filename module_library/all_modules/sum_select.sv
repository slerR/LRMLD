// Latency 3 cycles
module sum_select #(
    parameter METRIC_W = 12,
    parameter LABEL_W  = 6,
    parameter LABEL_W1 = 6,                    
    parameter CONC_W   = LABEL_W + LABEL_W1,
    localparam logic [METRIC_W - 1 : 0] MAX_METRIC  = '{METRIC_W{1'b1}}
)(
    input  logic                      clk,
    input  logic [4*METRIC_W - 1 : 0] i_metrics,
    input  logic [ 4*LABEL_W - 1 : 0] i_labels,
    input  logic [4*METRIC_W - 1 : 0] i_metrics1,
    input  logic [4*LABEL_W1 - 1 : 0] i_labels1,
    output logic [  METRIC_W - 1 : 0] o_metrics [0 : 3],    
    output logic [    CONC_W - 1 : 0] o_labels  [0 : 3]
);
    
    logic [           2 : 0] idx_l     [0 : 7];
    logic [  CONC_W - 1 : 0] conc_d    [0 : 2][0 : 7];
    logic [    METRIC_W : 0] summ0_d   [0 : 1];
   
    logic [    METRIC_W : 0] sig_summ  [0 : 7];
    logic [  CONC_W - 1 : 0] sig_conc  [0 : 7];
    
    logic [    METRIC_W : 0] sig_summ_r[0 : 7];
    logic [           2 : 0] idx_l_r   [0 : 7];
   
    logic                    flag      [0 : 4];
    
    logic [    METRIC_W : 0] c_slots   [0 : 2];
    logic [           2 : 0] l_slots   [0 : 2];
   
    logic [    METRIC_W : 0] c_slots_r [0 : 2];
    logic [           2 : 0] l_slots_r [0 : 2];
   
    logic [    METRIC_W : 0] c_m1      [0 : 2];
    logic [    METRIC_W : 0] c_m1_r    [0 : 2];
    logic [    METRIC_W : 0] c_m2      [0 : 2];
    logic [    METRIC_W : 0] c_m3temp  [0 : 2];
   
    logic [           2 : 0] l_m1      [0 : 2];
    logic [           2 : 0] l_m1_r    [0 : 2];
    logic [           2 : 0] l_m2      [0 : 2];
    logic [           2 : 0] l_m3temp  [0 : 2];
   
    logic [    METRIC_W : 0] c_final   [0 : 2];   
    logic [           2 : 0] l_final   [0 : 2];
    
    logic                    If0, If1, If2;
    
    logic [    METRIC_W : 0] sort1_min;
    logic [    METRIC_W : 0] sort1_max;
               
    logic [    METRIC_W : 0] sort2_min;
    logic [    METRIC_W : 0] sort2_max;
               
    logic [    METRIC_W : 0] sort3_min;
    logic [    METRIC_W : 0] sort3_max;
    
    always_comb begin
        idx_l[0] = 3'b000;
        idx_l[1] = 3'b001;
        idx_l[2] = 3'b010;
        idx_l[3] = 3'b011;
        idx_l[4] = 3'b100;
        idx_l[5] = 3'b101;
        idx_l[6] = 3'b110;
        idx_l[7] = 3'b111;
    end
    
    always_comb begin       
        sig_summ[0] = {1'b0, i_metrics [4*METRIC_W - 1 : 3*METRIC_W]} +
                      {1'b0, i_metrics1[4*METRIC_W - 1 : 3*METRIC_W]};
    
        sig_summ[1] = {1'b0, i_metrics [4*METRIC_W - 1 : 3*METRIC_W]} +
                      {1'b0, i_metrics1[3*METRIC_W - 1 : 2*METRIC_W]};
    
        sig_summ[2] = {1'b0, i_metrics [3*METRIC_W - 1 : 2*METRIC_W]} +
                      {1'b0, i_metrics1[4*METRIC_W - 1 : 3*METRIC_W]};
    
        sig_summ[3] = {1'b0, i_metrics [3*METRIC_W - 1 : 2*METRIC_W]} +
                      {1'b0, i_metrics1[3*METRIC_W - 1 : 2*METRIC_W]};
    
        sig_summ[4] = {1'b0, i_metrics [4*METRIC_W - 1 : 3*METRIC_W]} +
                      {1'b0, i_metrics1[2*METRIC_W - 1 : 1*METRIC_W]};
    
        sig_summ[5] = {1'b0, i_metrics [4*METRIC_W - 1 : 3*METRIC_W]} +
                      {1'b0, i_metrics1[1*METRIC_W - 1 : 0*METRIC_W]};
    
        sig_summ[6] = {1'b0, i_metrics [2*METRIC_W - 1 : 1*METRIC_W]} +
                      {1'b0, i_metrics1[4*METRIC_W - 1 : 3*METRIC_W]};
    
        sig_summ[7] = {1'b0, i_metrics [1*METRIC_W - 1 : 0*METRIC_W]} +
                      {1'b0, i_metrics1[4*METRIC_W - 1 : 3*METRIC_W]};
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
        for(int i = 0; i < 8; i++) begin
            conc_d[0][i] <= sig_conc[i];
        end
        
        for(int i = 1; i < 3; i++) begin
            for(int j = 0; j < 8; j++) begin
                conc_d[i][j] <= conc_d[i-1][j];
            end
        end
    end
    
    always_ff @(posedge clk) begin
        for (int k = 0; k < 8; k++) begin
            sig_summ_r[k] <= sig_summ[k];
            idx_l_r[k]    <= idx_l[k];
        end
        
        summ0_d[0] <= sig_summ_r[0];
        summ0_d[1] <= summ0_d[0];
    end
    
    comparator #(.DATA_W(METRIC_W+1)) comp1(
        .i_data (sig_summ_r[3]),
        .i_data1(sig_summ_r[4]),
        .o_flag (flag[4])
    );
    
    comparator #(.DATA_W(METRIC_W+1)) comp2(
        .i_data (sig_summ_r[3]),
        .i_data1(sig_summ_r[6]),
        .o_flag (flag[3])
    );
    
    comparator #(.DATA_W(METRIC_W+1)) comp3(
        .i_data (sig_summ_r[4]),
        .i_data1(sig_summ_r[6]),
        .o_flag (flag[2])
    );
    
    comparator #(.DATA_W(METRIC_W+1)) comp4(
        .i_data (sig_summ_r[5]),
        .i_data1(sig_summ_r[2]),
        .o_flag (flag[1])
    );
    
    comparator #(.DATA_W(METRIC_W+1)) comp5(
        .i_data (sig_summ_r[7]),
        .i_data1(sig_summ_r[1]),
        .o_flag (flag[0])
    );
    
    always_comb begin
        if ({flag[4], flag[3]} == 2'b11) begin
            c_slots[0] = sig_summ_r[1];
            c_slots[1] = sig_summ_r[2];
            c_slots[2] = sig_summ_r[3];
            l_slots[0] = idx_l_r[1];
            l_slots[1] = idx_l_r[2];
            l_slots[2] = idx_l_r[3];
        end
        else if (flag[2] && flag[1]) begin
            c_slots[0] = sig_summ_r[1];
            c_slots[1] = sig_summ_r[4];
            c_slots[2] = sig_summ_r[5];
            l_slots[0] = idx_l_r[1];
            l_slots[1] = idx_l_r[4];
            l_slots[2] = idx_l_r[5];
        end
        else if (flag[2] && (!flag[1])) begin
            c_slots[0] = sig_summ_r[1];
            c_slots[1] = sig_summ_r[4];
            c_slots[2] = sig_summ_r[2];
            l_slots[0] = idx_l_r[1];
            l_slots[1] = idx_l_r[4];
            l_slots[2] = idx_l_r[2];
        end
        else if ((!flag[2]) && flag[0]) begin
            c_slots[0] = sig_summ_r[2];
            c_slots[1] = sig_summ_r[6];
            c_slots[2] = sig_summ_r[7];
            l_slots[0] = idx_l_r[2];
            l_slots[1] = idx_l_r[6];
            l_slots[2] = idx_l_r[7];
        end
        else if ((!flag[2]) && (!flag[0])) begin
            c_slots[0] = sig_summ_r[2];
            c_slots[1] = sig_summ_r[6];
            c_slots[2] = sig_summ_r[1];
            l_slots[0] = idx_l_r[2];
            l_slots[1] = idx_l_r[6];
            l_slots[2] = idx_l_r[1];
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
    
    comparator #(.DATA_W(METRIC_W+1)) sort1(
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
    
    comparator #(.DATA_W(METRIC_W+1)) sort2(
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
    
    comparator #(.DATA_W(METRIC_W+1)) sort3(
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
        c_final[0] = c_m3temp[0];
        c_final[1] = c_m3temp[1];
        c_final[2] = c_m3temp[2];
       
        l_final[0] = l_m3temp[0];
        l_final[1] = l_m3temp[1];
        l_final[2] = l_m3temp[2];
    end
    
    always_comb begin
        o_metrics[0] = summ0_d[1][METRIC_W - 1 : 0];
        for (int i = 1; i < 4; i = i + 1) begin
            if (c_final[i-1][METRIC_W] == 1'b1) begin
                o_metrics[i] = MAX_METRIC;
            end else begin
                o_metrics[i] = c_final[i-1][METRIC_W - 1 : 0];
            end
        end
    end
    
    always_comb begin
        o_labels[0] = conc_d[2][0];
        for (int k = 1; k < 4; k++) begin
            case (l_final[k-1])
            3'b001: o_labels[k] = conc_d[2][1];
            3'b010: o_labels[k] = conc_d[2][2];
            3'b011: o_labels[k] = conc_d[2][3];
            3'b100: o_labels[k] = conc_d[2][4];
            3'b101: o_labels[k] = conc_d[2][5];
            3'b110: o_labels[k] = conc_d[2][6];
            3'b111: o_labels[k] = conc_d[2][7];
            endcase
        end     
    end
    
 endmodule
    