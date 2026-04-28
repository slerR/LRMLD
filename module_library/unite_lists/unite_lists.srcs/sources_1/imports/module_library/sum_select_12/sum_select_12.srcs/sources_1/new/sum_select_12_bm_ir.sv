`timescale 1ns / 1ps

// Total Latency, cycles: 11
module sum_select_12_bm_ir#(
    parameter METRIC_W = 10,
    parameter LABEL_W  = 16,
    parameter LABEL_W1 = 16,                 
    parameter CONC_W   = LABEL_W + LABEL_W1
)(
    input  logic                       clk,
    input  logic                       i_valid,
    // first list
    input  logic [12*METRIC_W - 1 : 0] i_metrics,
    input  logic [ 12*LABEL_W - 1 : 0] i_labels,
    // second list
    input  logic [12*METRIC_W - 1 : 0] i_metrics1,
    input  logic [12*LABEL_W1 - 1 : 0] i_labels1,
    // united list
    output logic [   METRIC_W - 1 : 0] o_metrics [0 : 11],    
    output logic [     CONC_W - 1 : 0] o_labels  [0 : 11],
    
    output logic                       o_valid
    );
    
    logic [             10 : 0] valid_d; 
    
    // first list devided into groups by 4 element
    logic [4*METRIC_W - 1 : 0] A0_m      [0 : 3];
    logic [ 4*LABEL_W - 1 : 0] A0_l      [0 : 3];
    // second list devided into groups by 4 element
    logic [4*METRIC_W - 1 : 0] B0_m      [0 : 3];
    logic [4*LABEL_W1 - 1 : 0] B0_l      [0 : 3];
    
    // first two sum_select output
    logic [  METRIC_W - 1 : 0] AB_m_0b   [0 : 1][0 : 3];
    logic [    CONC_W - 1 : 0] AB_l_0b   [0 : 1][0 : 3];
    // second two sum_select output
    logic [  METRIC_W - 1 : 0] AB_m_a0   [0 : 1][0 : 3];
    logic [    CONC_W - 1 : 0] AB_l_a0   [0 : 1][0 : 3];
    // A0B0 sum_select output
    logic [  METRIC_W - 1 : 0] AB_m_00   [0 : 7];
    logic [    CONC_W - 1 : 0] AB_l_00   [0 : 7];   
    // A1B1 sum_select output
    logic [  METRIC_W - 1 : 0] AB_m_11   [0 : 3];
    logic [    CONC_W - 1 : 0] AB_l_11   [0 : 3];
    
    // sum_select output registration and their delay on 1 cycle
    logic [  METRIC_W - 1 : 0] AB_m_0b_r [0 : 1][0 : 3];
    logic [    CONC_W - 1 : 0] AB_l_0b_r [0 : 1][0 : 3];
    
    logic [  METRIC_W - 1 : 0] AB_m_a0_r [0 : 1][0 : 3];
    logic [    CONC_W - 1 : 0] AB_l_a0_r [0 : 1][0 : 3]; 
    
    logic [  METRIC_W - 1 : 0] AB_m_11_r [0 : 3];
    logic [    CONC_W - 1 : 0] AB_l_11_r [0 : 3];
    
    logic [  METRIC_W - 1 : 0] AB_m_00_r [0 : 7];
    logic [    CONC_W - 1 : 0] AB_l_00_r [0 : 7];
    
    logic [  METRIC_W - 1 : 0] AB_m_0b_d [0 : 1][0 : 3];
    logic [    CONC_W - 1 : 0] AB_l_0b_d [0 : 1][0 : 3];
    
    logic [  METRIC_W - 1 : 0] AB_m_a0_d [0 : 1][0 : 3];
    logic [    CONC_W - 1 : 0] AB_l_a0_d [0 : 1][0 : 3];
    
    logic [  METRIC_W - 1 : 0] AB_m_11_d [0 : 3];
    logic [    CONC_W - 1 : 0] AB_l_11_d [0 : 3];
    
    logic [  METRIC_W - 1 : 0] AB_m_00MS_d [0 : 2][0 : 3];
    logic [    CONC_W - 1 : 0] AB_l_00MS_d [0 : 2][0 : 3];
    
    // min element from each group without A0B0
    logic [  METRIC_W - 1 : 0] AB_m_MS   [0 : 4];
    logic [             2 : 0] ss_idx    [0 : 1];
    // index registration
    logic [             2 : 0] ss_idx_r  [0 : 1];
    
    // best sum_select output for first merge
    logic [  METRIC_W - 1 : 0] AB_m_1    [0 : 3];
    logic [    CONC_W - 1 : 0] AB_l_1    [0 : 3];
    
    logic [  METRIC_W - 1 : 0] AB_m_2    [0 : 3];
    logic [    CONC_W - 1 : 0] AB_l_2    [0 : 3];
    
    // first merge output and it's 4 min elements
    logic [  METRIC_W - 1 : 0] m_mrg1    [0 : 7];
    logic [    CONC_W - 1 : 0] l_mrg1    [0 : 7];
    
    logic [  METRIC_W - 1 : 0] m_mrg1MS  [0 : 3];
    logic [    CONC_W - 1 : 0] l_mrg1MS  [0 : 3];
    
    // max 4 elements from A0B0 for second merge
    logic [  METRIC_W - 1 : 0] AB_m_0    [0 : 3];
    logic [    CONC_W - 1 : 0] AB_l_0    [0 : 3];
    
    logic [  METRIC_W - 1 : 0] m_mrg2    [0 : 7];
    logic [    CONC_W - 1 : 0] l_mrg2    [0 : 7];
    
    always_ff @(posedge clk) begin
        valid_d <= {valid_d[9 : 0], i_valid};
    end
    
    // Latency, cycles: 1 = 1 
    // input data reshaping and registration
    always_ff @(posedge clk) begin
        for(int i = 0; i < 3; i++) begin
            A0_m[i] <= i_metrics [(12*METRIC_W - 1) - i*4*METRIC_W -: 4*METRIC_W];      
            A0_l[i] <= i_labels  [  (12*LABEL_W - 1) - i*4*LABEL_W -: 4*LABEL_W ]; 
                
            B0_m[i] <= i_metrics1[(12*METRIC_W - 1) - i*4*METRIC_W -: 4*METRIC_W];         
            B0_l[i] <= i_labels1 [(12*LABEL_W1 - 1) - i*4*LABEL_W1 -: 4*LABEL_W1];
        end
    end
    
    // Latency, cycles: 1 + 3 = 4
    generate
        for(genvar b = 1; b < 3; b++) begin : A0Bb
            sum_select #(
                .METRIC_W(METRIC_W), 
                .LABEL_W (LABEL_W ), 
                .LABEL_W1(LABEL_W1)
                )SS (
                .clk       (clk        ),
                .i_metrics (A0_m[0]    ),
                .i_labels  (A0_l[0]    ),
                .i_metrics1(B0_m[b]    ),
                .i_labels1 (B0_l[b]    ),
                .o_metrics (AB_m_0b[b-1]),
                .o_labels  (AB_l_0b[b-1])
            );
        end
        
        for(genvar a = 1; a < 3; a++) begin : AaB0
            sum_select #(
                .METRIC_W(METRIC_W), 
                .LABEL_W (LABEL_W ), 
                .LABEL_W1(LABEL_W1)
            )SS (
                .clk       (clk        ),
                .i_metrics (A0_m[a]    ),
                .i_labels  (A0_l[a]    ),
                .i_metrics1(B0_m[0]    ),
                .i_labels1 (B0_l[0]    ),
                .o_metrics (AB_m_a0[a-1]),
                .o_labels  (AB_l_a0[a-1])
            );
        end                 
    endgenerate
    
    // Latency, cycles: 6 -> 3 cycles diff with sum_select
    sum_select_8 #( 
        .METRIC_W(METRIC_W), 
        .LABEL_W (LABEL_W ), 
        .LABEL_W1(LABEL_W1)
    )SS_00 (
        .clk       (clk    ),
        .i_metrics (A0_m[0]),
        .i_labels  (A0_l[0]),
        .i_metrics1(B0_m[0]),
        .i_labels1 (B0_l[0]),
        .o_metrics (AB_m_00),
        .o_labels  (AB_l_00)
    );
        
    sum_select #(
        .METRIC_W(METRIC_W), 
        .LABEL_W (LABEL_W ), 
        .LABEL_W1(LABEL_W1)
    )SS_11 (
        .clk       (clk    ),
        .i_metrics (A0_m[1]),
        .i_labels  (A0_l[1]),
        .i_metrics1(B0_m[1]),
        .i_labels1 (B0_l[1]),
        .o_metrics (AB_m_11),
        .o_labels  (AB_l_11)
    );
    
    // Latency, cycles: 1 + 3 + 1 = 5
    // sum_select output registration and their delay on 1 cycle
    always_ff @(posedge clk) begin
        for(int i = 0; i < 2; i++) begin
            for(int j = 0; j < 4; j++) begin
                AB_m_0b_r[i][j] <= AB_m_0b[i][j];
                AB_l_0b_r[i][j] <= AB_l_0b[i][j];
                
                AB_m_0b_d[i][j] <= AB_m_0b_r[i][j];
                AB_l_0b_d[i][j] <= AB_l_0b_r[i][j];
                
                AB_m_a0_r[i][j] <= AB_m_a0[i][j];
                AB_l_a0_r[i][j] <= AB_l_a0[i][j];
                
                AB_m_a0_d[i][j] <= AB_m_a0_r[i][j];
                AB_l_a0_d[i][j] <= AB_l_a0_r[i][j];
            end
        end
        
        for(int j = 0; j < 4; j++) begin      
            AB_m_11_r[j] <= AB_m_11[j];
            AB_l_11_r[j] <= AB_l_11[j];
            
            AB_m_11_d[j] <= AB_m_11_r[j];
            AB_l_11_d[j] <= AB_l_11_r[j];
        end
        
        for(int j = 0; j < 8; j++) begin      
            AB_m_00_r[j] <= AB_m_00[j];
            AB_l_00_r[j] <= AB_l_00[j];
        end
        
        for(int j = 0; j < 4; j++) begin
            AB_m_00MS_d[0][j] <= AB_m_00_r[j]; 
            AB_l_00MS_d[0][j] <= AB_l_00_r[j];             
        end    
        
        for(int i = 1; i < 3; i++) begin
            for(int j = 0; j < 4; j++) begin                     
                AB_m_00MS_d[i][j] <= AB_m_00MS_d[i-1][j]; 
                AB_l_00MS_d[i][j] <= AB_l_00MS_d[i-1][j];              
            end    
        end
    end
    
    // take min element from each group without A0B0
    always_comb begin
        for(int i = 0; i < 2; i++) begin
            AB_m_MS[i]   <= AB_m_0b_r[i][0];
            AB_m_MS[i+2] <= AB_m_a0_r[i][0];
        end
         AB_m_MS[4] <= AB_m_11_r[0];
    end
    
    min2_frm5#(
        .M_W(METRIC_W)
    )min3_frm7 (
        .i_m  (AB_m_MS),
        .o_idx(ss_idx )
    );
    
    // Latency, cycles: 1 + 3 + 1 + 1 = 6
    always_ff @(posedge clk) begin
        for(int i = 0; i < 3; i++) begin
            ss_idx_r[i] <= ss_idx[i];
        end
    end
    
    // Latency, cycles: 1 + 3 + 1 + 1 + 1 = 7
    // select 3 best sum_selet output
    always_ff @(posedge clk) begin
        case(ss_idx_r[0])
            3'b000: begin
                for(int i = 0; i < 4; i++) begin
                    AB_m_1[i] <= AB_m_0b_d[0][i];
                    AB_l_1[i] <= AB_l_0b_d[0][i];
                end
            end 
            3'b001: begin
                for(int i = 0; i < 4; i++) begin
                    AB_m_1[i] <= AB_m_0b_d[1][i];
                    AB_l_1[i] <= AB_l_0b_d[1][i];
                end
            end 
            3'b010: begin
                for(int i = 0; i < 4; i++) begin
                    AB_m_1[i] <= AB_m_a0_d[0][i];
                    AB_l_1[i] <= AB_l_a0_d[0][i];
                end
            end 
            3'b011: begin
                for(int i = 0; i < 4; i++) begin
                    AB_m_1[i] <= AB_m_a0_d[1][i];
                    AB_l_1[i] <= AB_l_a0_d[1][i];
                end
            end 
            3'b100: begin
                for(int i = 0; i < 4; i++) begin
                    AB_m_1[i] <= AB_m_11_d[i];
                    AB_l_1[i] <= AB_l_11_d[i];
                end
            end 
        endcase 
        
        case(ss_idx_r[1])
            3'b000: begin
                for(int i = 0; i < 4; i++) begin
                    AB_m_2[i] <= AB_m_0b_d[0][i];
                    AB_l_2[i] <= AB_l_0b_d[0][i];
                end
            end 
            3'b001: begin
                for(int i = 0; i < 4; i++) begin
                    AB_m_2[i] <= AB_m_0b_d[1][i];
                    AB_l_2[i] <= AB_l_0b_d[1][i];
                end
            end 
            3'b010: begin
                for(int i = 0; i < 4; i++) begin
                    AB_m_2[i] <= AB_m_a0_d[0][i];
                    AB_l_2[i] <= AB_l_a0_d[0][i];
                end
            end 
            3'b011: begin
                for(int i = 0; i < 4; i++) begin
                    AB_m_2[i] <= AB_m_a0_d[1][i];
                    AB_l_2[i] <= AB_l_a0_d[1][i];
                end
            end 
            3'b100: begin
                for(int i = 0; i < 4; i++) begin
                    AB_m_2[i] <= AB_m_11_d[i];
                    AB_l_2[i] <= AB_l_11_d[i];
                end
            end 
        endcase 
    end
       
    // merge best sum_select outputs
    // Latency, cycles: 1 + 3 + 1 + 1 + 1 + 2 = 9
    bitonic_merge_4_4_ir#(
        .M_W(METRIC_W),
        .L_W(CONC_W  )
    )merge1 (
        .clk (clk   ),
        .i_m1(AB_m_1),
        .i_l1(AB_l_1),
        .i_m2(AB_m_2),
        .i_l2(AB_l_2),
        .o_m (m_mrg1),
        .o_l (l_mrg1)
    );
        
    // Latency, cycles: 1 + 3 + 1 + 1 + 1 + 2 + 2= 11   
    always_ff@(posedge clk) begin
        for(int i = 0; i < 4; i++) begin
            AB_m_0[i] <=  AB_m_00_r[i+4];
            AB_l_0[i] <=  AB_l_00_r[i+4];
        end
    end
    
    always_comb begin               
        for(int i = 0; i < 4; i++) begin
            m_mrg1MS[i] =  m_mrg1[i];
            l_mrg1MS[i] =  l_mrg1[i];
        end
    end
    
    bitonic_merge_4_4_ir#(
        .M_W(METRIC_W),
        .L_W(CONC_W  )
    )merge_board (
        .clk (clk     ),
        .i_m1(AB_m_0  ),
        .i_l1(AB_l_0  ),
        .i_m2(m_mrg1MS),
        .i_l2(l_mrg1MS),
        .o_m (m_mrg2  ),
        .o_l (l_mrg2  )
    );
       
    always_comb begin
        for(int i = 0; i < 4; i++) begin
            o_metrics[i] <= AB_m_00MS_d[2][i];
            o_labels [i] <= AB_l_00MS_d[2][i];
        end
        
        for(int i = 4; i < 12; i++) begin
            o_metrics[i] <= m_mrg2[i-4];
            o_labels [i] <= l_mrg2[i-4];
        end
    end
    
    assign o_valid = valid_d[10];
          
endmodule
