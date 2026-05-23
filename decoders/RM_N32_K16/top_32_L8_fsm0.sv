module top_32 #(
    parameter     L           = 8,
    parameter     LLR_W       = 8,
    parameter     IS_PAD      = 0,
    parameter logic [1:0] FSM = 2'b00,
    localparam     MLABEL_W   = 4,
    localparam     METRIC_W   = LLR_W + $clog2(MLABEL_W)
)(
    input  logic                            clk,
    input  logic                            i_v,
    input  logic signed  [   LLR_W - 1 : 0] i_llr [0 : 31   ],
    output logic         [METRIC_W - 1 : 0] o_m   [0 : L - 1],
    output logic         [          31 : 0] o_l   [0 : L - 1],
    output logic                            o_v
);

    localparam N_COS = 8;

    localparam logic [4 - 1 : 0] DECOMP_0 [0 : 8 - 1][0 : 2 - 1] = '{
        '{4'b0000, 4'b1111},
        '{4'b1011, 4'b0100},
        '{4'b1101, 4'b0010},
        '{4'b0110, 4'b1001},
        '{4'b1110, 4'b0001},
        '{4'b0101, 4'b1010},
        '{4'b0011, 4'b1100},
        '{4'b1000, 4'b0111}
    };

    localparam logic [6 - 1 : 0] TBL_0 [0 : 8 - 1][0 : 4 - 1] = '{
        '{6'b000_000, 6'b101_101, 6'b011_011, 6'b110_110},
        '{6'b010_010, 6'b111_111, 6'b001_001, 6'b100_100},
        '{6'b110_011, 6'b011_110, 6'b101_000, 6'b000_101},
        '{6'b100_001, 6'b001_100, 6'b111_010, 6'b010_111},
        '{6'b110_000, 6'b101_110, 6'b011_101, 6'b000_110},
        '{6'b100_010, 6'b001_111, 6'b111_001, 6'b010_100},
        '{6'b000_011, 6'b101_110, 6'b011_000, 6'b110_101},
        '{6'b010_001, 6'b111_100, 6'b001_010, 6'b100_111}
    };

    logic [20 - 1 : 0] m_m_0_4_m [0 : N_COS - 1];
    logic [8 - 1 : 0] m_m_0_4_l [0 : N_COS - 1];
    logic              m_m_0_4_v;

    logic [20 - 1 : 0] m_m_4_8_m [0 : N_COS - 1];
    logic [8 - 1 : 0] m_m_4_8_l [0 : N_COS - 1];
    logic              m_m_4_8_v;

    logic [20 - 1 : 0] m_m_8_12_m [0 : N_COS - 1];
    logic [8 - 1 : 0] m_m_8_12_l [0 : N_COS - 1];
    logic              m_m_8_12_v;

    logic [20 - 1 : 0] m_m_12_16_m [0 : N_COS - 1];
    logic [8 - 1 : 0] m_m_12_16_l [0 : N_COS - 1];
    logic              m_m_12_16_v;

    logic [20 - 1 : 0] m_m_16_20_m [0 : N_COS - 1];
    logic [8 - 1 : 0] m_m_16_20_l [0 : N_COS - 1];
    logic              m_m_16_20_v;

    logic [20 - 1 : 0] m_m_20_24_m [0 : N_COS - 1];
    logic [8 - 1 : 0] m_m_20_24_l [0 : N_COS - 1];
    logic              m_m_20_24_v;

    logic [20 - 1 : 0] m_m_24_28_m [0 : N_COS - 1];
    logic [8 - 1 : 0] m_m_24_28_l [0 : N_COS - 1];
    logic              m_m_24_28_v;

    logic [20 - 1 : 0] m_m_28_32_m [0 : N_COS - 1];
    logic [8 - 1 : 0] m_m_28_32_l [0 : N_COS - 1];
    logic              m_m_28_32_v;

    logic [40 - 1 : 0] m_c_0_8_m [0 : N_COS - 1];
    logic [32 - 1 : 0] m_c_0_8_l [0 : N_COS - 1];
    logic              m_c_0_8_v;

    logic [40 - 1 : 0] m_c_8_16_m [0 : N_COS - 1];
    logic [32 - 1 : 0] m_c_8_16_l [0 : N_COS - 1];
    logic              m_c_8_16_v;

    logic [40 - 1 : 0] m_c_16_24_m [0 : N_COS - 1];
    logic [32 - 1 : 0] m_c_16_24_l [0 : N_COS - 1];
    logic              m_c_16_24_v;

    logic [40 - 1 : 0] m_c_24_32_m [0 : N_COS - 1];
    logic [32 - 1 : 0] m_c_24_32_l [0 : N_COS - 1];
    logic              m_c_24_32_v;

    logic [80 - 1 : 0] m_c_0_16_m [0 : N_COS - 1];
    logic [128 - 1 : 0] m_c_0_16_l [0 : N_COS - 1];
    logic              m_c_0_16_v;

    logic [80 - 1 : 0] m_c_16_32_m [0 : N_COS - 1];
    logic [128 - 1 : 0] m_c_16_32_l [0 : N_COS - 1];
    logic              m_c_16_32_v;

    localparam logic [1:0] TOP_FSM = (FSM == 2'b00) ? 2'b00 : (FSM == 2'b01) ? 2'b00 : (FSM == 2'b10) ? 2'b01 : 2'b10;

    make#(
        .LLR_W   (LLR_W          ),
        .LABEL_W (4             ),
        .N_COS   (N_COS          ),
        .N       (2             ),
        .DECOMP  (DECOMP_0             ),
        .IS_PAD  (IS_PAD         ),
        .METRIC_W(METRIC_W       )
    )make_0_4 (
        .clk      (clk            ),
        .i_valid  (i_v            ),
        .i_llr    (i_llr[0 : 3] ),
        .o_metrics(m_m_0_4_m           ),
        .o_labels (m_m_0_4_l           ),
        .o_valid  (m_m_0_4_v           )
    );

    make#(
        .LLR_W   (LLR_W          ),
        .LABEL_W (4             ),
        .N_COS   (N_COS          ),
        .N       (2             ),
        .DECOMP  (DECOMP_0             ),
        .IS_PAD  (IS_PAD         ),
        .METRIC_W(METRIC_W       )
    )make_4_8 (
        .clk      (clk            ),
        .i_valid  (i_v            ),
        .i_llr    (i_llr[4 : 7] ),
        .o_metrics(m_m_4_8_m           ),
        .o_labels (m_m_4_8_l           ),
        .o_valid  (m_m_4_8_v           )
    );

    make#(
        .LLR_W   (LLR_W          ),
        .LABEL_W (4             ),
        .N_COS   (N_COS          ),
        .N       (2             ),
        .DECOMP  (DECOMP_0             ),
        .IS_PAD  (IS_PAD         ),
        .METRIC_W(METRIC_W       )
    )make_8_12 (
        .clk      (clk            ),
        .i_valid  (i_v            ),
        .i_llr    (i_llr[8 : 11] ),
        .o_metrics(m_m_8_12_m           ),
        .o_labels (m_m_8_12_l           ),
        .o_valid  (m_m_8_12_v           )
    );

    make#(
        .LLR_W   (LLR_W          ),
        .LABEL_W (4             ),
        .N_COS   (N_COS          ),
        .N       (2             ),
        .DECOMP  (DECOMP_0             ),
        .IS_PAD  (IS_PAD         ),
        .METRIC_W(METRIC_W       )
    )make_12_16 (
        .clk      (clk            ),
        .i_valid  (i_v            ),
        .i_llr    (i_llr[12 : 15] ),
        .o_metrics(m_m_12_16_m           ),
        .o_labels (m_m_12_16_l           ),
        .o_valid  (m_m_12_16_v           )
    );

    make#(
        .LLR_W   (LLR_W          ),
        .LABEL_W (4             ),
        .N_COS   (N_COS          ),
        .N       (2             ),
        .DECOMP  (DECOMP_0             ),
        .IS_PAD  (IS_PAD         ),
        .METRIC_W(METRIC_W       )
    )make_16_20 (
        .clk      (clk            ),
        .i_valid  (i_v            ),
        .i_llr    (i_llr[16 : 19] ),
        .o_metrics(m_m_16_20_m           ),
        .o_labels (m_m_16_20_l           ),
        .o_valid  (m_m_16_20_v           )
    );

    make#(
        .LLR_W   (LLR_W          ),
        .LABEL_W (4             ),
        .N_COS   (N_COS          ),
        .N       (2             ),
        .DECOMP  (DECOMP_0             ),
        .IS_PAD  (IS_PAD         ),
        .METRIC_W(METRIC_W       )
    )make_20_24 (
        .clk      (clk            ),
        .i_valid  (i_v            ),
        .i_llr    (i_llr[20 : 23] ),
        .o_metrics(m_m_20_24_m           ),
        .o_labels (m_m_20_24_l           ),
        .o_valid  (m_m_20_24_v           )
    );

    make#(
        .LLR_W   (LLR_W          ),
        .LABEL_W (4             ),
        .N_COS   (N_COS          ),
        .N       (2             ),
        .DECOMP  (DECOMP_0             ),
        .IS_PAD  (IS_PAD         ),
        .METRIC_W(METRIC_W       )
    )make_24_28 (
        .clk      (clk            ),
        .i_valid  (i_v            ),
        .i_llr    (i_llr[24 : 27] ),
        .o_metrics(m_m_24_28_m           ),
        .o_labels (m_m_24_28_l           ),
        .o_valid  (m_m_24_28_v           )
    );

    make#(
        .LLR_W   (LLR_W          ),
        .LABEL_W (4             ),
        .N_COS   (N_COS          ),
        .N       (2             ),
        .DECOMP  (DECOMP_0             ),
        .IS_PAD  (IS_PAD         ),
        .METRIC_W(METRIC_W       )
    )make_28_32 (
        .clk      (clk            ),
        .i_valid  (i_v            ),
        .i_llr    (i_llr[28 : 31] ),
        .o_metrics(m_m_28_32_m           ),
        .o_labels (m_m_28_32_l           ),
        .o_valid  (m_m_28_32_v           )
    );

    comb#(
        .L        (L            ),
        .FSM      (FSM           ),
        .N        (2           ),
        .N1       (2           ),
        .N_COS    (N_COS        ),
        .METRIC_W (METRIC_W     ),
        .LABEL_W  (4           ),
        .LABEL_W1 (4           ),
        .N_OUT    (4           ),
        .CONC_W   (8           ),
        .N_U      (4           ),
        .TBL      (TBL_0           )
    )comb_0_8 (
        .clk        (clk        ),
        .i_valid    (m_m_0_4_v & m_m_4_8_v    ),
        .i_metrics  (m_m_0_4_m         ),
        .i_labels   (m_m_0_4_l         ),
        .i_metrics1 (m_m_4_8_m         ),
        .i_labels1  (m_m_4_8_l         ),
        .o_metrics  (m_c_0_8_m         ),
        .o_labels   (m_c_0_8_l         ),
        .o_valid    (m_c_0_8_v         )
    );

    comb#(
        .L        (L            ),
        .FSM      (FSM           ),
        .N        (2           ),
        .N1       (2           ),
        .N_COS    (N_COS        ),
        .METRIC_W (METRIC_W     ),
        .LABEL_W  (4           ),
        .LABEL_W1 (4           ),
        .N_OUT    (4           ),
        .CONC_W   (8           ),
        .N_U      (4           ),
        .TBL      (TBL_0           )
    )comb_8_16 (
        .clk        (clk        ),
        .i_valid    (m_m_8_12_v & m_m_12_16_v    ),
        .i_metrics  (m_m_8_12_m         ),
        .i_labels   (m_m_8_12_l         ),
        .i_metrics1 (m_m_12_16_m         ),
        .i_labels1  (m_m_12_16_l         ),
        .o_metrics  (m_c_8_16_m         ),
        .o_labels   (m_c_8_16_l         ),
        .o_valid    (m_c_8_16_v         )
    );

    comb#(
        .L        (L            ),
        .FSM      (FSM           ),
        .N        (2           ),
        .N1       (2           ),
        .N_COS    (N_COS        ),
        .METRIC_W (METRIC_W     ),
        .LABEL_W  (4           ),
        .LABEL_W1 (4           ),
        .N_OUT    (4           ),
        .CONC_W   (8           ),
        .N_U      (4           ),
        .TBL      (TBL_0           )
    )comb_16_24 (
        .clk        (clk        ),
        .i_valid    (m_m_16_20_v & m_m_20_24_v    ),
        .i_metrics  (m_m_16_20_m         ),
        .i_labels   (m_m_16_20_l         ),
        .i_metrics1 (m_m_20_24_m         ),
        .i_labels1  (m_m_20_24_l         ),
        .o_metrics  (m_c_16_24_m         ),
        .o_labels   (m_c_16_24_l         ),
        .o_valid    (m_c_16_24_v         )
    );

    comb#(
        .L        (L            ),
        .FSM      (FSM           ),
        .N        (2           ),
        .N1       (2           ),
        .N_COS    (N_COS        ),
        .METRIC_W (METRIC_W     ),
        .LABEL_W  (4           ),
        .LABEL_W1 (4           ),
        .N_OUT    (4           ),
        .CONC_W   (8           ),
        .N_U      (4           ),
        .TBL      (TBL_0           )
    )comb_24_32 (
        .clk        (clk        ),
        .i_valid    (m_m_24_28_v & m_m_28_32_v    ),
        .i_metrics  (m_m_24_28_m         ),
        .i_labels   (m_m_24_28_l         ),
        .i_metrics1 (m_m_28_32_m         ),
        .i_labels1  (m_m_28_32_l         ),
        .o_metrics  (m_c_24_32_m         ),
        .o_labels   (m_c_24_32_l         ),
        .o_valid    (m_c_24_32_v         )
    );

    comb#(
        .L        (L            ),
        .FSM      (FSM           ),
        .N        (4           ),
        .N1       (4           ),
        .N_COS    (N_COS        ),
        .METRIC_W (METRIC_W     ),
        .LABEL_W  (8           ),
        .LABEL_W1 (8           ),
        .N_OUT    (8           ),
        .CONC_W   (16           ),
        .N_U      (4           ),
        .TBL      (TBL_0           )
    )comb_0_16 (
        .clk        (clk        ),
        .i_valid    (m_c_0_8_v & m_c_8_16_v    ),
        .i_metrics  (m_c_0_8_m         ),
        .i_labels   (m_c_0_8_l         ),
        .i_metrics1 (m_c_8_16_m         ),
        .i_labels1  (m_c_8_16_l         ),
        .o_metrics  (m_c_0_16_m         ),
        .o_labels   (m_c_0_16_l         ),
        .o_valid    (m_c_0_16_v         )
    );

    comb#(
        .L        (L            ),
        .FSM      (FSM           ),
        .N        (4           ),
        .N1       (4           ),
        .N_COS    (N_COS        ),
        .METRIC_W (METRIC_W     ),
        .LABEL_W  (8           ),
        .LABEL_W1 (8           ),
        .N_OUT    (8           ),
        .CONC_W   (16           ),
        .N_U      (4           ),
        .TBL      (TBL_0           )
    )comb_16_32 (
        .clk        (clk        ),
        .i_valid    (m_c_16_24_v & m_c_24_32_v    ),
        .i_metrics  (m_c_16_24_m         ),
        .i_labels   (m_c_16_24_l         ),
        .i_metrics1 (m_c_24_32_m         ),
        .i_labels1  (m_c_24_32_l         ),
        .o_metrics  (m_c_16_32_m         ),
        .o_labels   (m_c_16_32_l         ),
        .o_valid    (m_c_16_32_v         )
    );

    top_comb#(
        .L        (L            ),
        .FSM      (TOP_FSM           ),
        .N        (8           ),
        .N1       (8           ),
        .N_COS    (N_COS        ),
        .METRIC_W (METRIC_W     ),
        .LABEL_W  (16           ),
        .LABEL_W1 (16           ),
        .N_OUT    (8           ),
        .CONC_W   (32           )
    )top_comb (
        .clk        (clk        ),
        .i_valid    (m_c_0_16_v & m_c_16_32_v    ),
        .i_metrics  (m_c_0_16_m         ),
        .i_labels   (m_c_0_16_l         ),
        .i_metrics1 (m_c_16_32_m         ),
        .i_labels1  (m_c_16_32_l         ),
        .o_metrics  (o_m         ),
        .o_labels   (o_l         ),
        .o_valid    (o_v         )
    );

endmodule

`timescale 1ns / 1ps