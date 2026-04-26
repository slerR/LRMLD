`timescale 1ns / 1ps

// Latency 1 cycles
module bitonic_merge_4_4#(
    parameter M_W = 10, 
    parameter L_W = 16  
)(
    input  logic                clk,
    
    input  logic [M_W-1:0]      i_m1 [0:3],
    input  logic [L_W-1:0]      i_l1 [0:3],    
    
    input  logic [M_W-1:0]      i_m2 [0:3],
    input  logic [L_W-1:0]      i_l2 [0:3],  
    
    output logic [M_W-1:0]      o_m  [0:7],
    output logic [L_W-1:0]      o_l  [0:7]  
);
    logic [L_W-1:0]      ld [0:7];
    
    always_ff @(posedge clk) begin
        for(int i = 0; i < 4; i++) begin
            ld[i]   <= i_l1[i];
            ld[i+4] <= i_l2[i]; 
        end
    end
    
    logic [2 : 0]   idx_l [0 : 7];
    logic [M_W-1:0] m     [0 : 7];
    
    always_comb begin
        idx_l[0] = 3'b000;
        idx_l[1] = 3'b001;
        idx_l[2] = 3'b010;
        idx_l[3] = 3'b011;
        idx_l[4] = 3'b111;
        idx_l[5] = 3'b110;
        idx_l[6] = 3'b101;
        idx_l[7] = 3'b100;
    end

    always_comb begin
        for (int i = 0; i < 4; i++) begin
            m[i]   <= i_m1[i];
            m[i+4] <= i_m2[3-i]; 
        end
    end

    genvar i, j;

    // STAGE 1
    logic [M_W-1:0] s1_m_min [0:3], s1_m_max [0:3];
    logic [    2:0] s1_l_min [0:3], s1_l_max [0:3];

    generate
        for (i = 0; i < 4; i++) begin : gen_stage1
            cas #(.METRIC_W(M_W), .LABEL_W(3)) cas_s1 (
                .i_m0(m[i]),   .i_m1(m[i+4]),
                .i_l0(idx_l[i]),   .i_l1(idx_l[i+4]),
                .o_min(s1_m_min[i]), .o_max(s1_m_max[i]),
                .o_lmin(s1_l_min[i]), .o_lmax(s1_l_max[i])
            );
        end
    endgenerate
    
    logic [2 : 0]   idx_l1 [0 : 7];
    logic [M_W-1:0] m1     [0 : 7];
    
    always_comb begin
        for (int k = 0; k < 4; k++) begin
            m1[k]       = s1_m_min[k]; 
            m1[k+4]     = s1_m_max[k];
            idx_l1[k]   = s1_l_min[k]; 
            idx_l1[k+4] = s1_l_max[k];
        end
    end

    // STAGE 2
    logic [M_W-1:0] s2_m_min [0:3], s2_m_max [0:3];
    logic [    2:0] s2_l_min [0:3], s2_l_max [0:3];

    generate
        for (i = 0; i < 8; i += 4) begin : grp_stage2
            for (j = 0; j < 2; j++) begin : gen_stage2
                cas #(.METRIC_W(M_W), .LABEL_W(3)) cas_s2 (
                    .i_m0(m1[i+j]), .i_m1(m1[i+j+2]),
                    .i_l0(idx_l1[i+j]), .i_l1(idx_l1[i+j+2]),
                    .o_min(s2_m_min[(i/2)+j]), .o_max(s2_m_max[(i/2)+j]),
                    .o_lmin(s2_l_min[(i/2)+j]), .o_lmax(s2_l_max[(i/2)+j])
                );
            end
        end
    endgenerate

    logic [2 : 0]   idx_l2 [0 : 7];
    logic [M_W-1:0] m2     [0 : 7];
    
    always_ff @(posedge clk) begin
        for (int k = 0; k < 8; k += 4) begin
            for (int m = 0; m < 2; m++) begin
                m2[k+m]       <= s2_m_min[(k/2)+m]; 
                m2[k+m+2]     <= s2_m_max[(k/2)+m];
                idx_l2[k+m]   <= s2_l_min[(k/2)+m]; 
                idx_l2[k+m+2] <= s2_l_max[(k/2)+m];
            end
        end
    end

    // STAGE 3
    logic [M_W-1:0] s3_m_min [0:3], s3_m_max [0:3];
    logic [  2-1:0] s3_l_min [0:3], s3_l_max [0:3];

    generate
        for (i = 0; i < 8; i += 2) begin : gen_stage3
            cas #(.METRIC_W(M_W), .LABEL_W(3)) cas_s3 (
                .i_m0(m2[i]),   .i_m1(m2[i+1]),
                .i_l0(idx_l2[i]),   .i_l1(idx_l2[i+1]),
                .o_min(s3_m_min[i/2]), .o_max(s3_m_max[i/2]),
                .o_lmin(s3_l_min[i/2]), .o_lmax(s3_l_max[i/2])
            );
        end
    endgenerate
    
    logic [2 : 0]   idx_l3 [0 : 7];
    logic [M_W-1:0] m3     [0 : 7];

    always_comb begin
        for (int k = 0; k < 8; k += 2) begin
            m3[k]       <= s3_m_min[k/2]; 
            m3[k+1]     <= s3_m_max[k/2];
            idx_l3[k]   <= s3_l_min[k/2]; 
            idx_l3[k+1] <= s3_l_max[k/2];
        end
    end

    // STAGE 4
    always_comb begin
        for (int k = 0; k < 8; k++) begin
            o_m[k] = m3[k];
            case (idx_l3[k])
            3'b000: o_l[k] = ld[0];
            3'b001: o_l[k] = ld[1];
            3'b010: o_l[k] = ld[2];
            3'b011: o_l[k] = ld[3];
            3'b100: o_l[k] = ld[4];
            3'b101: o_l[k] = ld[5];
            3'b110: o_l[k] = ld[6];
            3'b111: o_l[k] = ld[7];
            endcase
        end
        
    end

endmodule