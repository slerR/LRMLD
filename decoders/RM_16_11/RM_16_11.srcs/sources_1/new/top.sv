module top #(
    localparam MLABEL_W = 4,
    localparam N_COD    = 2,
    localparam N_COS    = 8,
    localparam N_U      = 4,
    parameter L         = 4,
    parameter IS_FSM    = 0,
    parameter LLR_W     = 8,
    parameter METRIC_W  = LLR_W + $clog2(MLABEL_W)
)(
    input logic                            clk,
    input logic                            i_v,
    input logic signed  [   LLR_W - 1 : 0] i_llr [0 : 15   ],
    output logic        [METRIC_W - 1 : 0] o_m   [0 : L - 1],
    output logic        [          15 : 0] o_l   [0 : L - 1],
    output logic                           o_v  
);
    
    parameter logic [MLABEL_W - 1 : 0] DECOMP [0 : N_COS-1][0 : N_COD-1] = '{
              {4'b0000, 4'b1111},
              {4'b1011, 4'b0100},
              {4'b1101, 4'b0010},
              {4'b0110, 4'b1001},
              {4'b1110, 4'b0001},
              {4'b0101, 4'b1010},
              {4'b0011, 4'b1100},
              {4'b1000, 4'b0111}};
    
    parameter logic [2*$clog2(N_COS) - 1 : 0] TBL [0 : N_COS - 1][0 : N_U - 1] = '{
              '{6'b000_000, 6'b101_101, 6'b011_011, 6'b110_110},
              '{6'b010_010, 6'b111_111, 6'b001_001, 6'b100_100},
              '{6'b110_011, 6'b011_110, 6'b101_000, 6'b000_101},
              '{6'b100_001, 6'b001_100, 6'b111_010, 6'b010_111}, 
              '{6'b110_000, 6'b101_110, 6'b011_101, 6'b000_110},
              '{6'b100_010, 6'b001_111, 6'b111_001, 6'b010_100},
              '{6'b000_011, 6'b101_110, 6'b011_000, 6'b110_101},
              '{6'b010_001, 6'b111_100, 6'b001_010, 6'b100_111}};
    

    logic [N_COD*METRIC_W - 1 : 0] m_m0  [0 : N_COS - 1];
    logic [N_COD*MLABEL_W - 1 : 0] l_m0  [0 : N_COS - 1];
    logic                          v_m0;
    
    logic [N_COD*METRIC_W - 1 : 0] m_m4  [0 : N_COS - 1];
    logic [N_COD*MLABEL_W - 1 : 0] l_m4  [0 : N_COS - 1];
    logic                          v_m4;
    
    logic [N_COD*METRIC_W - 1 : 0] m_m8  [0 : N_COS - 1];
    logic [N_COD*MLABEL_W - 1 : 0] l_m8  [0 : N_COS - 1];
    logic                          v_m8;
    
    logic [N_COD*METRIC_W - 1 : 0] m_m12 [0 : N_COS - 1];
    logic [N_COD*MLABEL_W - 1 : 0] l_m12 [0 : N_COS - 1];
    logic                          v_m12;

    make#(
        .LLR_W   (LLR_W   ),
        .LABEL_W (MLABEL_W),
        .N_COS   (N_COS   ),
        .N       (N_COD   ),
        .DECOMP  (DECOMP  )
    )make_0 (
        .clk      (clk         ),
        .i_valid  (i_v         ),
        .i_llr    (i_llr[0 : 3]),
        .o_metrics(m_m0        ),
        .o_labels (l_m0        ),
        .o_valid  (v_m0        )
    );
    
    make#(
        .LLR_W   (LLR_W   ),
        .LABEL_W (MLABEL_W),
        .N_COS   (N_COS   ),
        .N       (N_COD   ),
        .DECOMP  (DECOMP  )
    )make_4 (
        .clk      (clk         ),
        .i_valid  (i_v         ),
        .i_llr    (i_llr[4 : 7]),
        .o_metrics(m_m4        ),
        .o_labels (l_m4        ),
        .o_valid  (v_m4        )
    );
    
    make#(
        .LLR_W   (LLR_W   ),
        .LABEL_W (MLABEL_W),
        .N_COS   (N_COS   ),
        .N       (N_COD   ),
        .DECOMP  (DECOMP  )
    )make_8 (
        .clk      (clk         ),
        .i_valid  (i_v         ),
        .i_llr    (i_llr[8 : 11]),
        .o_metrics(m_m8        ),
        .o_labels (l_m8        ),
        .o_valid  (v_m8        )
    );
    
    make#(
        .LLR_W   (LLR_W   ),
        .LABEL_W (MLABEL_W),
        .N_COS   (N_COS   ),
        .N       (N_COD   ),
        .DECOMP  (DECOMP  )
    )make_12 (
        .clk      (clk           ),
        .i_valid  (i_v           ),
        .i_llr    (i_llr[12 : 15]),
        .o_metrics(m_m12         ),
        .o_labels (l_m12         ),
        .o_valid  (v_m12         )
    );
    
    parameter N_OUT  = L;
    parameter CONC_W = 2*MLABEL_W;
    
    logic [N_OUT*METRIC_W - 1 : 0] m_c0 [0 : N_COS - 1];
    logic [  N_OUT*CONC_W - 1 : 0] l_c0 [0 : N_COS - 1];
    logic                          v_c0;
    
    logic [N_OUT*METRIC_W - 1 : 0] m_c8 [0 : N_COS - 1];
    logic [  N_OUT*CONC_W - 1 : 0] l_c8 [0 : N_COS - 1];
    logic                          v_c8;
    
    comb#(
        .L        (L       ),
        .IS_FSM   (IS_FSM  ),
        .N        (N_COD   ),
        .N1       (N_COD   ),
        .N_COS    (N_COS   ),
        .METRIC_W (METRIC_W),
        .LABEL_W  (MLABEL_W),
        .LABEL_W1 (MLABEL_W),
        .CONC_W   (CONC_W  ),
        .N_U      (N_U     ),
        .TBL      (TBL     ),
        .N_OUT    (N_OUT   )
    )comb_0 (
        .clk        (clk      ),
        .i_valid    (v_m0&v_m4),
        .i_metrics  (m_m0     ),
        .i_labels   (l_m0     ),
        .i_metrics1 (m_m4     ),
        .i_labels1  (l_m4     ),
        .o_metrics  (m_c0     ),
        .o_labels   (l_c0     ),
        .o_valid    (v_c0     )
    );
    
    comb#(
        .L        (L       ),
        .IS_FSM   (IS_FSM  ),
        .N        (N_COD   ),
        .N1       (N_COD   ),
        .N_COS    (N_COS   ),
        .METRIC_W (METRIC_W),
        .LABEL_W  (MLABEL_W),
        .LABEL_W1 (MLABEL_W),
        .CONC_W   (CONC_W  ),
        .N_U      (N_U     ),
        .TBL      (TBL     ),
        .N_OUT    (N_OUT   )
    )comb_8 (
        .clk        (clk       ),
        .i_valid    (v_m8&v_m12),
        .i_metrics  (m_m8      ),
        .i_labels   (l_m8      ),
        .i_metrics1 (m_m12     ),
        .i_labels1  (l_m12     ),
        .o_metrics  (m_c8      ),
        .o_labels   (l_c8      ),
        .o_valid    (v_c8      )
    );
    
    top_comb #(
        .L        (L       ),
        .N        (N_OUT   ),
        .N1       (N_OUT   ),
        .N_COS    (N_COS   ),
        .METRIC_W (METRIC_W),
        .LABEL_W  (CONC_W  ),
        .LABEL_W1 (CONC_W  ),
        .N_OUT    (L       )
    )top_comb (
        .clk        (clk      ),
        .i_valid    (v_c0&v_c8),
        .i_metrics  (m_c0     ),
        .i_labels   (l_c0     ),
        .i_metrics1 (m_c8     ),
        .i_labels1  (l_c8     ),
        .o_metrics  (o_m      ),
        .o_labels   (o_l      ),
        .o_valid    (o_v      )
    );

endmodule