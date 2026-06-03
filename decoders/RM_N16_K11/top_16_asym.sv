module top #(
    parameter     L           = 3,
    parameter     LLR_W       = 6,
    parameter     IS_PAD      = 0,
    parameter logic [1:0] FSM = 2'b00,
    localparam     MLABEL_W   = 4,
    localparam     METRIC_W   = LLR_W + $clog2(MLABEL_W)
)(
    input  logic                            clk,
    input  logic                            i_v,
    input  logic signed  [   LLR_W - 1 : 0] i_llr [0 : 15   ],
    output logic         [METRIC_W - 1 : 0] o_m   [0 : L - 1],
    output logic         [          15 : 0] o_l   [0 : L - 1],
    output logic                            o_v
);

    localparam N_COS = 4;

    localparam logic [2 - 1 : 0] DECOMP_0 [0 : 4 - 1][0 : 1 - 1] = '{
        '{2'b00},
        '{2'b10},
        '{2'b11},
        '{2'b01}
    };

    localparam logic [2 - 1 : 0] DECOMP_1 [0 : 4 - 1][0 : 1 - 1] = '{
        '{2'b00},
        '{2'b10},
        '{2'b11},
        '{2'b01}
    };

    localparam logic [4 - 1 : 0] DECOMP_2 [0 : 4 - 1][0 : 4 - 1] = '{
        '{4'b0000, 4'b1111, 4'b1011, 4'b0100},
        '{4'b1101, 4'b0010, 4'b0110, 4'b1001},
        '{4'b1110, 4'b0001, 4'b0101, 4'b1010},
        '{4'b0011, 4'b1100, 4'b1000, 4'b0111}
    };

    localparam logic [4 - 1 : 0] TBL_0 [0 : 4 - 1][0 : 2 - 1] = '{
        '{4'b00_00, 4'b11_11},
        '{4'b01_01, 4'b10_10},
        '{4'b01_10, 4'b10_01},
        '{4'b11_00, 4'b00_11}
    };

    logic [8 - 1 : 0] m_m_0_2_m [0 : N_COS - 1];
    logic [2 - 1 : 0] m_m_0_2_l [0 : N_COS - 1];
    logic              m_m_0_2_v;

    logic [8 - 1 : 0] m_m_2_4_m [0 : N_COS - 1];
    logic [2 - 1 : 0] m_m_2_4_l [0 : N_COS - 1];
    logic              m_m_2_4_v;

    logic [32 - 1 : 0] m_m_4_8_m [0 : N_COS - 1];
    logic [16 - 1 : 0] m_m_4_8_l [0 : N_COS - 1];
    logic              m_m_4_8_v;

    logic [32 - 1 : 0] m_m_8_12_m [0 : N_COS - 1];
    logic [16 - 1 : 0] m_m_8_12_l [0 : N_COS - 1];
    logic              m_m_8_12_v;

    logic [8 - 1 : 0] m_c_0_4_m [0 : N_COS - 1];
    logic [4 - 1 : 0] m_c_0_4_l [0 : N_COS - 1];
    logic              m_c_0_4_v;

    logic [24 - 1 : 0] m_c_4_12_m [0 : N_COS - 1];
    logic [24 - 1 : 0] m_c_4_12_l [0 : N_COS - 1];
    logic              m_c_4_12_v;

    logic [24 - 1 : 0] m_c_0_12_m [0 : N_COS - 1];
    logic [36 - 1 : 0] m_c_0_12_l [0 : N_COS - 1];
    logic              m_c_0_12_v;

    logic [32 - 1 : 0] m_m_12_16_m [0 : N_COS - 1];
    logic [16 - 1 : 0] m_m_12_16_l [0 : N_COS - 1];
    logic              m_m_12_16_v;

    localparam logic [1:0] TOP_FSM = (FSM == 2'b00) ? 2'b00 : (FSM == 2'b01) ? 2'b00 : (FSM == 2'b10) ? 2'b01 : 2'b10;

    make#(
        .LLR_W   (LLR_W          ),
        .LABEL_W (2             ),
        .N_COS   (N_COS          ),
        .N       (1             ),
        .DECOMP  (DECOMP_0             ),
        .IS_PAD  (IS_PAD         ),
        .METRIC_W(METRIC_W       )
    )make_0_2 (
        .clk      (clk            ),
        .i_valid  (i_v            ),
        .i_llr    (i_llr[0 : 1] ),
        .o_metrics(m_m_0_2_m           ),
        .o_labels (m_m_0_2_l           ),
        .o_valid  (m_m_0_2_v           )
    );

    make#(
        .LLR_W   (LLR_W          ),
        .LABEL_W (2             ),
        .N_COS   (N_COS          ),
        .N       (1             ),
        .DECOMP  (DECOMP_1             ),
        .IS_PAD  (IS_PAD         ),
        .METRIC_W(METRIC_W       )
    )make_2_4 (
        .clk      (clk            ),
        .i_valid  (i_v            ),
        .i_llr    (i_llr[2 : 3] ),
        .o_metrics(m_m_2_4_m           ),
        .o_labels (m_m_2_4_l           ),
        .o_valid  (m_m_2_4_v           )
    );

    make#(
        .LLR_W   (LLR_W          ),
        .LABEL_W (4             ),
        .N_COS   (N_COS          ),
        .N       (4             ),
        .DECOMP  (DECOMP_2             ),
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
        .N       (4             ),
        .DECOMP  (DECOMP_2             ),
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

    comb#(
        .L        (L            ),
        .FSM      (FSM           ),
        .N        (1           ),
        .N1       (1           ),
        .N_COS    (N_COS        ),
        .METRIC_W (METRIC_W     ),
        .LABEL_W  (2           ),
        .LABEL_W1 (2           ),
        .N_OUT    (1           ),
        .CONC_W   (4           ),
        .N_U      (2           ),
        .TBL      (TBL_0           )
    )comb_0_4 (
        .clk        (clk        ),
        .i_valid    (m_m_0_2_v & m_m_2_4_v    ),
        .i_metrics  (m_m_0_2_m         ),
        .i_labels   (m_m_0_2_l         ),
        .i_metrics1 (m_m_2_4_m         ),
        .i_labels1  (m_m_2_4_l         ),
        .o_metrics  (m_c_0_4_m         ),
        .o_labels   (m_c_0_4_l         ),
        .o_valid    (m_c_0_4_v         )
    );

    comb#(
        .L        (L            ),
        .FSM      (FSM           ),
        .N        (4           ),
        .N1       (4           ),
        .N_COS    (N_COS        ),
        .METRIC_W (METRIC_W     ),
        .LABEL_W  (4           ),
        .LABEL_W1 (4           ),
        .N_OUT    (3           ),
        .CONC_W   (8           ),
        .N_U      (2           ),
        .TBL      (TBL_0           )
    )comb_4_12 (
        .clk        (clk        ),
        .i_valid    (m_m_4_8_v & m_m_8_12_v    ),
        .i_metrics  (m_m_4_8_m         ),
        .i_labels   (m_m_4_8_l         ),
        .i_metrics1 (m_m_8_12_m         ),
        .i_labels1  (m_m_8_12_l         ),
        .o_metrics  (m_c_4_12_m         ),
        .o_labels   (m_c_4_12_l         ),
        .o_valid    (m_c_4_12_v         )
    );

    logic [8 - 1 : 0] d_0_4_to_0_12_m [0 : N_COS - 1];
    logic [4 - 1 : 0] d_0_4_to_0_12_l [0 : N_COS - 1];
    logic              d_0_4_to_0_12_v;

    list_delay#(
        .DELAY(6   ),
        .N_OUT(N_COS),
        .WIDTH(8   )
    )delay_d_0_4_to_0_12_m (
        .clk    (clk ),
        .i_data (m_c_0_4_m),
        .o_data (d_0_4_to_0_12_m)
    );

    list_delay #(
        .DELAY(6   ),
        .N_OUT(N_COS),
        .WIDTH(4   )
    ) delay_d_0_4_to_0_12_l (
        .clk    (clk ),
        .i_data (m_c_0_4_l),
        .o_data (d_0_4_to_0_12_l)
    );

    logic [0:0] d_0_4_to_0_12_v_in [0:0];
    logic [0:0] d_0_4_to_0_12_v_out [0:0];
    assign d_0_4_to_0_12_v_in[0] = m_c_0_4_v;

    list_delay #(
        .DELAY(6),
        .N_OUT(1 ),
        .WIDTH(1 )
    ) delay_d_0_4_to_0_12_v (
        .clk    (clk    ),
        .i_data (d_0_4_to_0_12_v_in),
        .o_data (d_0_4_to_0_12_v_out)
    );
    assign d_0_4_to_0_12_v = d_0_4_to_0_12_v_out[0];
    comb#(
        .L        (L            ),
        .FSM      (FSM           ),
        .N        (1           ),
        .N1       (3           ),
        .N_COS    (N_COS        ),
        .METRIC_W (METRIC_W     ),
        .LABEL_W  (4           ),
        .LABEL_W1 (8           ),
        .N_OUT    (3           ),
        .CONC_W   (12           ),
        .N_U      (2           ),
        .TBL      (TBL_0           )
    )comb_0_12 (
        .clk        (clk        ),
        .i_valid    (d_0_4_to_0_12_v & m_c_4_12_v    ),
        .i_metrics  (d_0_4_to_0_12_m         ),
        .i_labels   (d_0_4_to_0_12_l         ),
        .i_metrics1 (m_c_4_12_m         ),
        .i_labels1  (m_c_4_12_l         ),
        .o_metrics  (m_c_0_12_m         ),
        .o_labels   (m_c_0_12_l         ),
        .o_valid    (m_c_0_12_v         )
    );

    make#(
        .LLR_W   (LLR_W          ),
        .LABEL_W (4             ),
        .N_COS   (N_COS          ),
        .N       (4             ),
        .DECOMP  (DECOMP_2             ),
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

    logic [32 - 1 : 0] d_12_16_to_0_16_m [0 : N_COS - 1];
    logic [16 - 1 : 0] d_12_16_to_0_16_l [0 : N_COS - 1];
    logic              d_12_16_to_0_16_v;

    list_delay#(
        .DELAY(15   ),
        .N_OUT(N_COS),
        .WIDTH(32   )
    )delay_d_12_16_to_0_16_m (
        .clk    (clk ),
        .i_data (m_m_12_16_m),
        .o_data (d_12_16_to_0_16_m)
    );

    list_delay #(
        .DELAY(15   ),
        .N_OUT(N_COS),
        .WIDTH(16   )
    ) delay_d_12_16_to_0_16_l (
        .clk    (clk ),
        .i_data (m_m_12_16_l),
        .o_data (d_12_16_to_0_16_l)
    );

    logic [0:0] d_12_16_to_0_16_v_in [0:0];
    logic [0:0] d_12_16_to_0_16_v_out [0:0];
    assign d_12_16_to_0_16_v_in[0] = m_m_12_16_v;

    list_delay #(
        .DELAY(15),
        .N_OUT(1 ),
        .WIDTH(1 )
    ) delay_d_12_16_to_0_16_v (
        .clk    (clk    ),
        .i_data (d_12_16_to_0_16_v_in),
        .o_data (d_12_16_to_0_16_v_out)
    );
    assign d_12_16_to_0_16_v = d_12_16_to_0_16_v_out[0];
    top_comb#(
        .L        (L            ),
        .FSM      (TOP_FSM           ),
        .N        (3           ),
        .N1       (4           ),
        .N_COS    (N_COS        ),
        .METRIC_W (METRIC_W     ),
        .LABEL_W  (12           ),
        .LABEL_W1 (4           ),
        .N_OUT    (3           ),
        .CONC_W   (16           )
    )top_comb (
        .clk        (clk        ),
        .i_valid    (m_c_0_12_v & d_12_16_to_0_16_v    ),
        .i_metrics  (m_c_0_12_m         ),
        .i_labels   (m_c_0_12_l         ),
        .i_metrics1 (d_12_16_to_0_16_m         ),
        .i_labels1  (d_12_16_to_0_16_l         ),
        .o_metrics  (o_m         ),
        .o_labels   (o_l         ),
        .o_valid    (o_v         )
    );

endmodule

`timescale 1ns / 1ps