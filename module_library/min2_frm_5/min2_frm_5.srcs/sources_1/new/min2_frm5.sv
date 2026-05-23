`timescale 1ns / 1ps

module min2_frm5#(
    parameter M_W = 10
)(
    input  logic [M_W - 1 : 0] i_m   [0 : 4],
    output logic [      2 : 0] o_idx [0 : 1]
    );

    logic [M_W - 1 : 0] a0b1, a0b2, a1b0, a2b0, a1b1;
    logic               fg0, fg1, fg2;
    logic [      2 : 0] idx [0 : 1];

    always_comb begin
        a0b1 = i_m[0];
        a0b2 = i_m[1];
        a1b0 = i_m[2];
        a2b0 = i_m[3];
        a1b1 = i_m[4];
    end

    comparator#(
        .DATA_W(M_W)
    )cmp0(
        .i_data (a0b2),
        .i_data1(a1b0),
        .o_flag (fg0 )
    );

    comparator#(
        .DATA_W(M_W)
    )cmp1(
        .i_data (a2b0),
        .i_data1(a0b1),
        .o_flag (fg1 )
    );

    comparator#(
        .DATA_W(M_W)
    )cmp2(
        .i_data (a0b1),
        .i_data1(a1b0),
        .o_flag (fg2 )
    );

    always_comb begin
        if(fg0) begin
            idx[0] = 3'b000;
            idx[1] = 3'b001;
        end else if(fg1) begin
            idx[0] = 3'b010;
            idx[1] = 3'b011;
        end else if(fg2) begin
            idx[0] = 3'b000;
            idx[1] = 3'b010;
        end else begin
            idx[0] = 3'b010;
            idx[1] = 3'b000;
        end
    end

    always_comb begin
        for(int i = 0; i < 2; i++) begin
            o_idx[i] = idx[i];
        end
    end

endmodule