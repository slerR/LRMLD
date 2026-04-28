`timescale 1ns / 1ps

// Latency, clk: 4
module bitonic_merge_8_8_ir #(
    parameter M_W = 10, 
    parameter L_W = 16  
)(
    input  logic                 clk,
    
    input  logic [M_W-1:0]      i_m1 [0:7],
    input  logic [L_W-1:0]      i_l1 [0:7],    
    
    input  logic [M_W-1:0]      i_m2 [0:7],
    input  logic [L_W-1:0]      i_l2 [0:7],  
    
    output logic [M_W-1:0]      o_m  [0:15],
    output logic [L_W-1:0]      o_l  [0:15]  
);
    logic [L_W-1:0] ld     [0:3][0:15];
    logic [M_W-1:0] i_m1_r [0:7];
    logic [M_W-1:0] i_m2_r [0:7];
    
    always_ff @(posedge clk) begin
        for(int i = 0; i < 8; i++) begin
            i_m1_r[i]  <= i_m1[i];
            i_m2_r[i]  <= i_m2[i];
            ld[0][i]   <= i_l1[i];
            ld[0][i+8] <= i_l2[i]; 
        end
        for(int k = 1; k < 4; k++) begin
            ld[k] <= ld[k-1];
        end
    end
    
    logic [3:0]     idx_l [0:15];
    logic [M_W-1:0] m     [0:15];
    
    always_comb begin
        for (int i = 0; i < 8; i++) begin
            m[i]       = i_m1_r[i];
            m[i+8]     = i_m2_r[7-i];
            idx_l[i]   = i[3:0];
            idx_l[i+8] = 4'd15 - i[3:0];
        end
    end

    genvar i, j, g;

    logic [M_W-1:0] s1_m_min [0:7], s1_m_max [0:7];
    logic [3:0]     s1_l_min [0:7], s1_l_max [0:7];

    generate
        for (i = 0; i < 8; i++) begin : gen_stage1
            cas #(.METRIC_W(M_W), .LABEL_W(4)) cas_s1 (
                .i_m0(m[i]),          .i_m1(m[i+8]),
                .i_l0(idx_l[i]),      .i_l1(idx_l[i+8]),
                .o_min(s1_m_min[i]),  .o_max(s1_m_max[i]),
                .o_lmin(s1_l_min[i]), .o_lmax(s1_l_max[i])
            );
        end
    endgenerate
    
    logic [3:0]     idx_l1 [0:15];
    logic [M_W-1:0] m1     [0:15];
    
    always_ff @(posedge clk) begin
        for (int k = 0; k < 8; k++) begin
            m1[k]       <= s1_m_min[k]; 
            m1[k+8]     <= s1_m_max[k];
            idx_l1[k]   <= s1_l_min[k]; 
            idx_l1[k+8] <= s1_l_max[k];
        end
    end

    logic [M_W-1:0] s2_m_min [0:7], s2_m_max [0:7];
    logic [3:0]     s2_l_min [0:7], s2_l_max [0:7];

    generate
        for (g = 0; g < 16; g += 8) begin : grp_stage2
            for (j = 0; j < 4; j++) begin : gen_stage2
                cas #(.METRIC_W(M_W), .LABEL_W(4)) cas_s2 (
                    .i_m0(m1[g+j]),        .i_m1(m1[g+j+4]),
                    .i_l0(idx_l1[g+j]),    .i_l1(idx_l1[g+j+4]),
                    .o_min(s2_m_min[(g/2)+j]), .o_max(s2_m_max[(g/2)+j]),
                    .o_lmin(s2_l_min[(g/2)+j]), .o_lmax(s2_l_max[(g/2)+j])
                );
            end
        end
    endgenerate

    logic [3:0]     idx_l2 [0:15];
    logic [M_W-1:0] m2     [0:15];
    
    always_ff @(posedge clk) begin
        for (int k = 0; k < 16; k += 8) begin
            for (int n = 0; n < 4; n++) begin
                m2[k+n]       <= s2_m_min[(k/2)+n]; 
                m2[k+n+4]     <= s2_m_max[(k/2)+n];
                idx_l2[k+n]   <= s2_l_min[(k/2)+n]; 
                idx_l2[k+n+4] <= s2_l_max[(k/2)+n];
            end
        end
    end

    logic [M_W-1:0] s3_m_min [0:7], s3_m_max [0:7];
    logic [3:0]     s3_l_min [0:7], s3_l_max [0:7];

    generate
        for (g = 0; g < 16; g += 4) begin : grp_stage3
            for (j = 0; j < 2; j++) begin : gen_stage3
                cas #(.METRIC_W(M_W), .LABEL_W(4)) cas_s3 (
                    .i_m0(m2[g+j]),        .i_m1(m2[g+j+2]),
                    .i_l0(idx_l2[g+j]),    .i_l1(idx_l2[g+j+2]),
                    .o_min(s3_m_min[(g/2)+j]), .o_max(s3_m_max[(g/2)+j]),
                    .o_lmin(s3_l_min[(g/2)+j]), .o_lmax(s3_l_max[(g/2)+j])
                );
            end
        end
    endgenerate

    logic [3:0]     idx_l3 [0:15];
    logic [M_W-1:0] m3     [0:15];
    
    always_ff @(posedge clk) begin
        for (int k = 0; k < 16; k += 4) begin
            for (int n = 0; n < 2; n++) begin
                m3[k+n]       <= s3_m_min[(k/2)+n]; 
                m3[k+n+2]     <= s3_m_max[(k/2)+n];
                idx_l3[k+n]   <= s3_l_min[(k/2)+n]; 
                idx_l3[k+n+2] <= s3_l_max[(k/2)+n];
            end
        end
    end

    logic [M_W-1:0] s4_m_min [0:7], s4_m_max [0:7];
    logic [3:0]     s4_l_min [0:7], s4_l_max [0:7];

    generate
        for (i = 0; i < 16; i += 2) begin : gen_stage4
            cas #(.METRIC_W(M_W), .LABEL_W(4)) cas_s4 (
                .i_m0(m3[i]),          .i_m1(m3[i+1]),
                .i_l0(idx_l3[i]),      .i_l1(idx_l3[i+1]),
                .o_min(s4_m_min[i/2]), .o_max(s4_m_max[i/2]),
                .o_lmin(s4_l_min[i/2]), .o_lmax(s4_l_max[i/2])
            );
        end
    endgenerate

    always_comb begin
        for (int k = 0; k < 8; k++) begin
            o_m[2*k]   = s4_m_min[k];
            o_m[2*k+1] = s4_m_max[k];
            o_l[2*k]   = ld[3][s4_l_min[k]];
            o_l[2*k+1] = ld[3][s4_l_max[k]];
        end
    end

endmodule