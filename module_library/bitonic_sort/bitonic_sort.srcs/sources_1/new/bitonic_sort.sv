// Total Latency, cycles: 1 + NUM_STAGES
`timescale 1ns / 1ps

module bitonic_sort#(
    parameter                   METRIC_W   = 10,
    parameter                   LABEL_W    = 16,
    parameter                   N          = 16,
    localparam                  N_EXT      = 2**$clog2(N),
    localparam                  NUM_STAGES = $clog2(N_EXT),
    localparam                  IDX_W      = $clog2(N_EXT),
    localparam [METRIC_W-1 : 0] M_PADDING  = {METRIC_W{1'b1}}
)(
    input  logic                     clk,
    input  logic                     i_valid,
    input  logic [N*METRIC_W -1 : 0] i_metrics,
    input  logic [ N*LABEL_W -1 : 0] i_labels,
    output logic                     o_valid,
    output logic [N*METRIC_W -1 : 0] o_metrics,
    output logic [ N*LABEL_W -1 : 0] o_labels
);

    logic [NUM_STAGES : 0] pipe_valid;
    logic [METRIC_W-1 : 0] stage_m       [0 : NUM_STAGES][0 : N_EXT-1];
    logic [   IDX_W-1 : 0] stage_idx     [0 : NUM_STAGES][0 : N_EXT-1];
    logic [ LABEL_W-1 : 0] label_storage [0 : NUM_STAGES][0 : N_EXT-1];

    always_ff @(posedge clk) begin
        pipe_valid[0] <= i_valid;
        for(int i = 0; i < N_EXT; i++) begin
            stage_idx[0][i] <= i[IDX_W-1:0];
            if (i < N) begin
                stage_m[0][i]       <= i_metrics[(i+1)*METRIC_W-1 -: METRIC_W];
                label_storage[0][i] <= i_labels [ (i+1)*LABEL_W-1 -: LABEL_W ];
            end else begin
                stage_m[0][i]       <= M_PADDING;
                label_storage[0][i] <= '0;
            end
        end
    end

    generate
        for (genvar s = 1; s <= NUM_STAGES; s++) begin : gen_stages
            
            always_ff @(posedge clk) begin : stage_reg
                logic [METRIC_W-1:0] m_tmp [0:N_EXT-1];
                logic [   IDX_W-1:0] idx_tmp [0:N_EXT-1];
                int size, step, pair;

                pipe_valid[s] <= pipe_valid[s-1];
                label_storage[s] <= label_storage[s-1];
                
                m_tmp = stage_m[s-1];
                idx_tmp = stage_idx[s-1];
                
                size = 1 << s;
                for (int hop = s-1; hop >= 0; hop--) begin
                    step = 1 << hop;
                    for (int n = 0; n < N_EXT; n++) begin
                        pair = n ^ step;
                        if (n < pair) begin
                            if ((n & size) == 0) begin
                                if (m_tmp[n] > m_tmp[pair]) begin
                                    {m_tmp[n], m_tmp[pair]}     = {m_tmp[pair], m_tmp[n]};
                                    {idx_tmp[n], idx_tmp[pair]} = {idx_tmp[pair], idx_tmp[n]};
                                end
                            end else begin
                                if (m_tmp[n] < m_tmp[pair]) begin
                                    {m_tmp[n], m_tmp[pair]}     = {m_tmp[pair], m_tmp[n]};
                                    {idx_tmp[n], idx_tmp[pair]} = {idx_tmp[pair], idx_tmp[n]};
                                end
                            end
                        end
                    end
                end
                stage_m[s]   <= m_tmp;
                stage_idx[s] <= idx_tmp;
            end
        end
    endgenerate

    always_comb begin
        o_valid = pipe_valid[NUM_STAGES];
        for (int i = 0; i < N; i++) begin
            o_metrics[(i+1)*METRIC_W-1 -: METRIC_W] = stage_m      [NUM_STAGES][N-1-i];
            o_labels [(i+1)*LABEL_W-1 -: LABEL_W  ] = label_storage[NUM_STAGES][stage_idx[NUM_STAGES][N-1-i]];
        end
    end

endmodule