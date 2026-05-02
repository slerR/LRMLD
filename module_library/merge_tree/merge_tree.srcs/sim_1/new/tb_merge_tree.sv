`timescale 1ns / 1ps

module tb_merge_tree;

    parameter NUM_LISTS = 5;
    parameter N_INPUTS  = 4;
    parameter METRIC_W  = 8;
    parameter LABEL_W   = 2;
    parameter [1:0] FF_P = 2'b11;

    logic                    clk;
    logic                    i_valid;
    logic [METRIC_W - 1 : 0] i_m [NUM_LISTS][N_INPUTS];
    logic [ LABEL_W - 1 : 0] i_l [NUM_LISTS][N_INPUTS];

    logic [METRIC_W - 1 : 0] o_m [N_INPUTS];
    logic [ LABEL_W - 1 : 0] o_l [N_INPUTS];
    logic                    o_valid;

    merge_tree #(
        .NUM_LISTS (NUM_LISTS),
        .N_INPUTS  (N_INPUTS),
        .METRIC_W  (METRIC_W),
        .LABEL_W   (LABEL_W),
        .FF_P      (FF_P)
    ) dut (
        .clk     (clk),
        .i_valid (i_valid),
        .i_m     (i_m),
        .i_l     (i_l),
        .o_valid (o_valid),
        .o_m     (o_m),
        .o_l     (o_l)
    );

    initial begin
        clk = 0;
    end
    
    always #5 clk = ~clk;


    initial begin
        @(posedge clk);
        i_valid <= 1;
        
        i_m[0] <= '{8'd10, 8'd20, 8'd30, 8'd40};
        i_l[0] <= '{2'd0,  2'd1,  2'd2,  2'd3};
               
        i_m[1] <= '{8'd5,  8'd15, 8'd25, 8'd35};
        i_l[1] <= '{2'd3,  2'd2,  2'd1,  2'd0};
               
        i_m[2] <= '{8'd8,  8'd18, 8'd28, 8'd38};
        i_l[2] <= '{2'd1,  2'd1,  2'd1,  2'd1};
               
        i_m[3] <= '{8'd12, 8'd22, 8'd32, 8'd42};
        i_l[3] <= '{2'd2,  2'd2,  2'd2,  2'd2};
        
        i_m[4] <= '{8'd4, 8'd7, 8'd32, 8'd42};
        i_l[4] <= '{2'd0,  2'd2,  2'd2,  2'd2};

        @(posedge clk);
        i_m[0] <= '{8'd1,  8'd2,  8'd3,  8'd4};
        i_m[1] <= '{8'd6,  8'd7,  8'd8,  8'd9};
        i_m[2] <= '{8'd11, 8'd12, 8'd13, 8'd14};
        i_m[3] <= '{8'd16, 8'd17, 8'd18, 8'd19};
        i_m[4] <= '{8'd5, 8'd7, 8'd32, 8'd42};

        @(posedge clk);
        i_valid <= 0;

        repeat (20) @(posedge clk);
        $finish;
    end

endmodule