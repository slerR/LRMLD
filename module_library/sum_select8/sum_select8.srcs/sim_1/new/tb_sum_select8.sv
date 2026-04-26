module tb_sum_select;
    localparam METRIC_W    = 6;
    localparam LABEL_W     = 4;
    localparam FRAQ_PART   = 4;

    logic                     clk;
    logic [4*METRIC_W -1 : 0] din, din1;
    logic [ METRIC_W - 1 : 0] dout     [0 : 7];
    logic [4*LABEL_W - 1 : 0] lab_in, lab_in1;
    logic [2*LABEL_W - 1 : 0] lab_dout [0 : 7];
    
    function automatic logic [METRIC_W-1:0] fixed(real val);
        logic [METRIC_W-1:0] result;
        result = val * (2.0 ** FRAQ_PART);
        return result;
    endfunction
    
    sum_select_8 #(.METRIC_W(METRIC_W), .LABEL_W(LABEL_W), .LABEL_W1(LABEL_W)) dut(
        .clk       (clk),
        .i_metrics (din),
        .i_labels  (lab_in),
        .i_metrics1(din1),
        .i_labels1 (lab_in1),
        .o_metrics (dout),
        .o_labels  (lab_dout)
    );
    
    initial clk = 0;
    always #5 clk = ~clk;
    
    initial begin
        @(posedge clk)
        din     <= {fixed(0), fixed(0.75), fixed(1.22), fixed(1.3)};
        din1    <= {fixed(0.2), fixed(0.25), fixed(0.288), fixed(1.9)};
        lab_in  <= 16'b0001_0010_0100_1000;
        lab_in1 <= 16'b1111_0000_1010_0101;
        @(posedge clk);
        
        din     <= {fixed(0), fixed(0), fixed(2), fixed(1)};  
        din1    <= {fixed(0), fixed(0), fixed(3), fixed(4)};  
        lab_in  <= 16'b0101_0101_0000_1111;
        lab_in1 <= 16'b1010_1010_1111_0000;
        repeat(4) @(posedge clk);   
        $finish;
    end
    
endmodule