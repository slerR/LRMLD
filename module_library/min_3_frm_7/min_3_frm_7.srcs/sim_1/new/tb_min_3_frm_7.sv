`timescale 1ns / 1ps

module tb_find;
    
    localparam M_W = 4;
    
    logic               clk;
    logic [M_W - 1 : 0] i_m   [0 : 6];
    logic [      2 : 0] o_idx [0 : 2];
    
    initial clk = 0;
    
    always #5 clk = ~clk;
    
    min3_frm7#(.M_W(M_W)
    )dut (
        .i_m  (i_m  ),
        .o_idx(o_idx)
    );
    
    initial begin
        i_m = {4'd2, 4'd3, 4'd5, 4'd1, 4'd4, 4'd10, 4'd12};
        #10;
        $finish;
    end
      
endmodule
