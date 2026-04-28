`timescale 1ns / 1ps

module tb_bitonic_sort();

    parameter METRIC_W = 16;
    parameter LABEL_W  = 8;
    parameter N        = 8;
    
    logic clk;
    logic i_valid;
    logic [N*METRIC_W-1:0] i_metrics;
    logic [N*LABEL_W-1:0]  i_labels;
    logic o_valid;
    logic [N*METRIC_W-1:0] o_metrics;
    logic [N*LABEL_W-1:0]  o_labels;
    
    bitonic_sort_fp #(
        .METRIC_W(METRIC_W),
        .LABEL_W (LABEL_W),
        .N       (N)
    ) dut (
        .clk      (clk),
        .i_valid  (i_valid),
        .i_metrics(i_metrics),
        .i_labels (i_labels),
        .o_valid  (o_valid),
        .o_metrics(o_metrics),
        .o_labels (o_labels)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        i_valid   <= 0;
        i_metrics <= 0;
        i_labels  <= 0;
        @(posedge clk); 
                
        i_valid   <= 1;
        i_metrics <= {
            16'd1,  
            16'd90,   
            16'd80,   
            16'd70,   
            16'd95,   
            16'd50,   
            16'd60,   
            16'd30    
        };
        i_labels <= {
            8'd7,
            8'd6,
            8'd5,
            8'd4,
            8'd3,
            8'd2,
            8'd1,
            8'd0
        };
        @(posedge clk); 
        i_metrics <= {
            16'd1,  
            16'd1,   
            16'd2,   
            16'd3,   
            16'd0,   
            16'd2,   
            16'd100,   
            16'd30    
        };
        i_labels <= {
            8'd7,
            8'd6,
            8'd5,
            8'd4,
            8'd3,
            8'd2,
            8'd1,
            8'd0
        };
        @(posedge clk); 
        
        i_valid <= 0;
       repeat(20) @(posedge clk); 
       $finish;
    end
    
endmodule