`timescale 1ns / 1ps

module min3_frm7#(
    parameter M_W = 10
)(
    input  logic [M_W - 1 : 0] i_m   [0 : 6], // a0b1, a0b2, a0b3, a1b0, a2b0, a3b0, a1b1
    output logic [      2 : 0] o_idx [0 : 2]   // indexes of the best 3 sum-select output in term of min sums
    );
    // a0b1, a0b2, a0b3, a1b0, a2b0, a3b0, a1b1 <-> 3'b000, 3'b001, ... 3'b110
    logic [M_W - 1 : 0] a0b1, a0b2, a0b3, a1b0, a2b0, a3b0, a1b1;
    logic               fg0, fg1, fg2, fg3, fg4;
    logic [      2 : 0] idx [0 : 2];
    
    always_comb begin
        a0b1 = i_m[0];
        a0b2 = i_m[1];
        a0b3 = i_m[2];
        a1b0 = i_m[3];
        a2b0 = i_m[4];
        a3b0 = i_m[5];
        a1b1 = i_m[6];
    end
    
    comparator#(
        .DATA_W(M_W)
    )cmp0(
        .i_data (a0b3),
        .i_data1(a1b0),
        .o_flag (fg4 )
    );
    
    comparator#(
        .DATA_W(M_W)
    )cmp1(
        .i_data (a0b3),
        .i_data1(a3b0),
        .o_flag (fg3 )
    );
    
    comparator#(
        .DATA_W(M_W)
    )cmp2(
        .i_data (a1b0),
        .i_data1(a3b0),
        .o_flag (fg2 )
    );
    
    comparator#(
        .DATA_W(M_W)
    )cmp3(
        .i_data (a2b0),
        .i_data1(a0b2),
        .o_flag (fg1 )
    );
    
    comparator#(
        .DATA_W(M_W)
    )cmp4(
        .i_data (a1b1),
        .i_data1(a0b1),
        .o_flag (fg0 )
    );
    
    // a0b1, a0b2, a0b3, a1b0, a2b0, a3b0, a1b1 <-> 3'b000, 3'b001, ... 3'b110
    always_comb begin
        if(fg4 & fg3) begin
            idx[0] = 3'b000; //a0b1;
            idx[1] = 3'b001; //a0b2;
            idx[2] = 3'b010; //a0b3;
        end else if(fg2 & fg1) begin
            idx[0] = 3'b000; //a0b1;
            idx[1] = 3'b011; //a1b0;
            idx[2] = 3'b100; //a2b0;
        end else if(fg2 & (!fg1)) begin
            idx[0] = 3'b000; //a0b1;
            idx[1] = 3'b011; //a1b0;
            idx[2] = 3'b001; //a0b2;
        end else if((!fg2) & fg0) begin
            idx[0] = 3'b001; //a0b2;
            idx[1] = 3'b101; //a3b0;
            idx[2] = 3'b110; //a1b1;
        end else if((!fg2) & (!fg0)) begin
            idx[0] = 3'b001; //a0b2;
            idx[1] = 3'b101; //a3b0;
            idx[2] = 3'b000; //a0b1;
        end else begin
            idx[0] = 3'b000;
            idx[1] = 3'b000;
            idx[2] = 3'b000;
        end
    end
    
    always_comb begin
        for(int i = 0; i < 3; i++) begin
            o_idx[i] = idx[i]; 
        end
    end
    
endmodule