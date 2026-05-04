// Latency 6 cycles
module sum_select_8 #(
    parameter  METRIC_W = 8,
    parameter  LABEL_W  = 6,
    parameter  LABEL_W1 = 6,
    localparam SLICE_W  = METRIC_W,
    localparam SUM_W    = METRIC_W + 1,
    localparam CONC_W   = LABEL_W + LABEL_W1
)(
    input  logic                      clk,
    input  logic [4*METRIC_W - 1 : 0] i_metrics,
    input  logic [4*LABEL_W  - 1 : 0] i_labels,
    input  logic [4*METRIC_W - 1 : 0] i_metrics1,
    input  logic [4*LABEL_W1 - 1 : 0] i_labels1,
    output logic [  METRIC_W - 1 : 0] o_metrics [0 : 7],
    output logic [    CONC_W - 1 : 0] o_labels  [0 : 7]
);

    localparam logic [METRIC_W - 1 : 0] MAX_METRIC = {METRIC_W{1'b1}};

    logic [ SUM_W - 1 : 0] s_raw   [0 : 7];
    logic [CONC_W - 1 : 0] l_raw   [0 : 7];
    logic [         2 : 0] idx_raw [0 : 7];
    
    logic [ SUM_W - 1 : 0] s0_d    [0 : 5];
    logic [CONC_W - 1 : 0] l0_d    [0 : 5];
    
    logic [ SUM_W - 1 : 0] m_p     [0 : 5][0 : 7];
    logic [         2 : 0] idx_p   [0 : 5][0 : 7];
    
    logic [CONC_W - 1 : 0] conc_d  [0 : 5][0 : 7];
    
    logic [ SUM_W - 1 : 0] m_w     [1 : 6][0 : 7];
    logic [         2 : 0] idx_w   [1 : 6][0 : 7];

    always_comb begin
        s_raw[0] = {1'b0, i_metrics[4*SLICE_W-1:3*SLICE_W]} + {1'b0, i_metrics1[4*SLICE_W-1:3*SLICE_W]};
        s_raw[1] = {1'b0, i_metrics[4*SLICE_W-1:3*SLICE_W]} + {1'b0, i_metrics1[3*SLICE_W-1:2*SLICE_W]};
        s_raw[2] = {1'b0, i_metrics[3*SLICE_W-1:2*SLICE_W]} + {1'b0, i_metrics1[4*SLICE_W-1:3*SLICE_W]};
        s_raw[3] = {1'b0, i_metrics[3*SLICE_W-1:2*SLICE_W]} + {1'b0, i_metrics1[3*SLICE_W-1:2*SLICE_W]};
        s_raw[4] = {1'b0, i_metrics[4*SLICE_W-1:3*SLICE_W]} + {1'b0, i_metrics1[2*SLICE_W-1:1*SLICE_W]};
        s_raw[5] = {1'b0, i_metrics[4*SLICE_W-1:3*SLICE_W]} + {1'b0, i_metrics1[1*SLICE_W-1:0*SLICE_W]};
        s_raw[6] = {1'b0, i_metrics[2*SLICE_W-1:1*SLICE_W]} + {1'b0, i_metrics1[4*SLICE_W-1:3*SLICE_W]};
        s_raw[7] = {1'b0, i_metrics[1*SLICE_W-1:0*SLICE_W]} + {1'b0, i_metrics1[4*SLICE_W-1:3*SLICE_W]};

        l_raw[0] = {i_labels[4*LABEL_W-1:3*LABEL_W], i_labels1[4*LABEL_W1-1:3*LABEL_W1]};
        l_raw[1] = {i_labels[4*LABEL_W-1:3*LABEL_W], i_labels1[3*LABEL_W1-1:2*LABEL_W1]};
        l_raw[2] = {i_labels[3*LABEL_W-1:2*LABEL_W], i_labels1[4*LABEL_W1-1:3*LABEL_W1]};
        l_raw[3] = {i_labels[3*LABEL_W-1:2*LABEL_W], i_labels1[3*LABEL_W1-1:2*LABEL_W1]};
        l_raw[4] = {i_labels[4*LABEL_W-1:3*LABEL_W], i_labels1[2*LABEL_W1-1:1*LABEL_W1]};
        l_raw[5] = {i_labels[4*LABEL_W-1:3*LABEL_W], i_labels1[1*LABEL_W1-1:0*LABEL_W1]};
        l_raw[6] = {i_labels[2*LABEL_W-1:1*LABEL_W], i_labels1[4*LABEL_W1-1:3*LABEL_W1]};
        l_raw[7] = {i_labels[1*LABEL_W-1:0*LABEL_W], i_labels1[4*LABEL_W1-1:3*LABEL_W1]};
        
        for (int i = 0; i < 8; i++) idx_raw[i] = i[2:0];
    end

    always_ff @(posedge clk) begin
        s0_d[0] <= s_raw[0]; l0_d[0] <= l_raw[0];
        for (int i = 1; i < 6; i++) begin s0_d[i] <= s0_d[i-1]; l0_d[i] <= l0_d[i-1]; end
        for (int j = 0; j < 8; j++) begin
            conc_d[0][j] <= l_raw[j];
            for (int i = 1; i < 6; i++) conc_d[i][j] <= conc_d[i-1][j];
            m_p[0][j] <= m_w[1][j]; idx_p[0][j] <= idx_w[1][j];
            m_p[1][j] <= m_w[2][j]; idx_p[1][j] <= idx_w[2][j];
            m_p[2][j] <= m_w[3][j]; idx_p[2][j] <= idx_w[3][j];
            m_p[3][j] <= m_w[4][j]; idx_p[3][j] <= idx_w[4][j];
            m_p[4][j] <= m_w[5][j]; idx_p[4][j] <= idx_w[5][j];
            m_p[5][j] <= m_w[6][j]; idx_p[5][j] <= idx_w[6][j];
        end
    end
  
    cas #(.METRIC_W(SUM_W), .LABEL_W(3)) c11(.i_m0(s_raw[0]),   .i_m1(s_raw[1]),   .i_l0(idx_raw[0]), .i_l1(idx_raw[1]), .o_min(m_w[1][0]), .o_max(m_w[1][1]), .o_lmin(idx_w[1][0]), .o_lmax(idx_w[1][1]));
    cas #(.METRIC_W(SUM_W), .LABEL_W(3)) c12(.i_m0(s_raw[2]),   .i_m1(s_raw[3]),   .i_l0(idx_raw[2]), .i_l1(idx_raw[3]), .o_min(m_w[1][2]), .o_max(m_w[1][3]), .o_lmin(idx_w[1][2]), .o_lmax(idx_w[1][3]));
    cas #(.METRIC_W(SUM_W), .LABEL_W(3)) c13(.i_m0(s_raw[4]),   .i_m1(s_raw[5]),   .i_l0(idx_raw[4]), .i_l1(idx_raw[5]), .o_min(m_w[1][4]), .o_max(m_w[1][5]), .o_lmin(idx_w[1][4]), .o_lmax(idx_w[1][5]));
    cas #(.METRIC_W(SUM_W), .LABEL_W(3)) c14(.i_m0(s_raw[6]),   .i_m1(s_raw[7]),   .i_l0(idx_raw[6]), .i_l1(idx_raw[7]), .o_min(m_w[1][6]), .o_max(m_w[1][7]), .o_lmin(idx_w[1][6]), .o_lmax(idx_w[1][7]));
    
    cas #(.METRIC_W(SUM_W), .LABEL_W(3)) c21(.i_m0(m_p[0][0]), .i_m1(m_p[0][2]), .i_l0(idx_p[0][0]), .i_l1(idx_p[0][2]), .o_min(m_w[2][0]), .o_max(m_w[2][2]), .o_lmin(idx_w[2][0]), .o_lmax(idx_w[2][2]));
    cas #(.METRIC_W(SUM_W), .LABEL_W(3)) c22(.i_m0(m_p[0][1]), .i_m1(m_p[0][3]), .i_l0(idx_p[0][1]), .i_l1(idx_p[0][3]), .o_min(m_w[2][1]), .o_max(m_w[2][3]), .o_lmin(idx_w[2][1]), .o_lmax(idx_w[2][3]));
    cas #(.METRIC_W(SUM_W), .LABEL_W(3)) c23(.i_m0(m_p[0][4]), .i_m1(m_p[0][6]), .i_l0(idx_p[0][4]), .i_l1(idx_p[0][6]), .o_min(m_w[2][4]), .o_max(m_w[2][6]), .o_lmin(idx_w[2][4]), .o_lmax(idx_w[2][6]));
    cas #(.METRIC_W(SUM_W), .LABEL_W(3)) c24(.i_m0(m_p[0][5]), .i_m1(m_p[0][7]), .i_l0(idx_p[0][5]), .i_l1(idx_p[0][7]), .o_min(m_w[2][5]), .o_max(m_w[2][7]), .o_lmin(idx_w[2][5]), .o_lmax(idx_w[2][7]));
    
    assign m_w[3][0] = m_p[1][0]; assign idx_w[3][0] = idx_p[1][0];
    assign m_w[3][3] = m_p[1][3]; assign idx_w[3][3] = idx_p[1][3];
    assign m_w[3][4] = m_p[1][4]; assign idx_w[3][4] = idx_p[1][4];
    assign m_w[3][7] = m_p[1][7]; assign idx_w[3][7] = idx_p[1][7];
    
    cas #(.METRIC_W(SUM_W), .LABEL_W(3)) c31(.i_m0(m_p[1][1]), .i_m1(m_p[1][2]), .i_l0(idx_p[1][1]), .i_l1(idx_p[1][2]), .o_min(m_w[3][1]), .o_max(m_w[3][2]), .o_lmin(idx_w[3][1]), .o_lmax(idx_w[3][2]));
    cas #(.METRIC_W(SUM_W), .LABEL_W(3)) c32(.i_m0(m_p[1][5]), .i_m1(m_p[1][6]), .i_l0(idx_p[1][5]), .i_l1(idx_p[1][6]), .o_min(m_w[3][5]), .o_max(m_w[3][6]), .o_lmin(idx_w[3][5]), .o_lmax(idx_w[3][6]));
    
    cas #(.METRIC_W(SUM_W), .LABEL_W(3)) c41(.i_m0(m_p[2][0]), .i_m1(m_p[2][4]), .i_l0(idx_p[2][0]), .i_l1(idx_p[2][4]), .o_min(m_w[4][0]), .o_max(m_w[4][4]), .o_lmin(idx_w[4][0]), .o_lmax(idx_w[4][4]));
    cas #(.METRIC_W(SUM_W), .LABEL_W(3)) c42(.i_m0(m_p[2][1]), .i_m1(m_p[2][5]), .i_l0(idx_p[2][1]), .i_l1(idx_p[2][5]), .o_min(m_w[4][1]), .o_max(m_w[4][5]), .o_lmin(idx_w[4][1]), .o_lmax(idx_w[4][5]));
    cas #(.METRIC_W(SUM_W), .LABEL_W(3)) c43(.i_m0(m_p[2][2]), .i_m1(m_p[2][6]), .i_l0(idx_p[2][2]), .i_l1(idx_p[2][6]), .o_min(m_w[4][2]), .o_max(m_w[4][6]), .o_lmin(idx_w[4][2]), .o_lmax(idx_w[4][6]));
    cas #(.METRIC_W(SUM_W), .LABEL_W(3)) c44(.i_m0(m_p[2][3]), .i_m1(m_p[2][7]), .i_l0(idx_p[2][3]), .i_l1(idx_p[2][7]), .o_min(m_w[4][3]), .o_max(m_w[4][7]), .o_lmin(idx_w[4][3]), .o_lmax(idx_w[4][7]));
    
    assign m_w[5][0] = m_p[3][0]; assign idx_w[5][0] = idx_p[3][0];
    assign m_w[5][1] = m_p[3][1]; assign idx_w[5][1] = idx_p[3][1];
    assign m_w[5][6] = m_p[3][6]; assign idx_w[5][6] = idx_p[3][6];
    assign m_w[5][7] = m_p[3][7]; assign idx_w[5][7] = idx_p[3][7];
    
    cas #(.METRIC_W(SUM_W), .LABEL_W(3)) c51(.i_m0(m_p[3][2]), .i_m1(m_p[3][4]), .i_l0(idx_p[3][2]), .i_l1(idx_p[3][4]), .o_min(m_w[5][2]), .o_max(m_w[5][4]), .o_lmin(idx_w[5][2]), .o_lmax(idx_w[5][4]));
    cas #(.METRIC_W(SUM_W), .LABEL_W(3)) c52(.i_m0(m_p[3][3]), .i_m1(m_p[3][5]), .i_l0(idx_p[3][3]), .i_l1(idx_p[3][5]), .o_min(m_w[5][3]), .o_max(m_w[5][5]), .o_lmin(idx_w[5][3]), .o_lmax(idx_w[5][5]));
    
    assign m_w[6][0] = m_p[4][0]; assign idx_w[6][0] = idx_p[4][0];
    assign m_w[6][7] = m_p[4][7]; assign idx_w[6][7] = idx_p[4][7];
    
    cas #(.METRIC_W(SUM_W), .LABEL_W(3)) c61(.i_m0(m_p[4][1]), .i_m1(m_p[4][2]), .i_l0(idx_p[4][1]), .i_l1(idx_p[4][2]), .o_min(m_w[6][1]), .o_max(m_w[6][2]), .o_lmin(idx_w[6][1]), .o_lmax(idx_w[6][2]));
    cas #(.METRIC_W(SUM_W), .LABEL_W(3)) c62(.i_m0(m_p[4][3]), .i_m1(m_p[4][4]), .i_l0(idx_p[4][3]), .i_l1(idx_p[4][4]), .o_min(m_w[6][3]), .o_max(m_w[6][4]), .o_lmin(idx_w[6][3]), .o_lmax(idx_w[6][4]));
    cas #(.METRIC_W(SUM_W), .LABEL_W(3)) c63(.i_m0(m_p[4][5]), .i_m1(m_p[4][6]), .i_l0(idx_p[4][5]), .i_l1(idx_p[4][6]), .o_min(m_w[6][5]), .o_max(m_w[6][6]), .o_lmin(idx_w[6][5]), .o_lmax(idx_w[6][6]));

    always_comb begin
        o_metrics[0] = (s0_d[5][SUM_W-1]) ? MAX_METRIC : s0_d[5][METRIC_W-1:0];
        o_labels[0]  = l0_d[5];
        for (int i = 1; i < 8; i++) begin
            o_metrics[i] = (m_p[5][i][SUM_W-1]) ? MAX_METRIC : m_p[5][i][METRIC_W-1:0];
            o_labels[i]  = conc_d[5][idx_p[5][i]];
        end
    end
endmodule