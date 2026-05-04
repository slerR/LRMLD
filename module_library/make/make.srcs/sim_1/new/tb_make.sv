`timescale 1ns / 1ps

module tb_make;

    localparam LLR_W    = 6;
    localparam LABEL_W  = 4;
    localparam N_COS    = 8;
    localparam N        = 2;
    localparam METRIC_W = LLR_W + $clog2(LABEL_W);

    logic                        clk;
    logic                        i_valid;
    logic signed [LLR_W - 1 : 0] i_llr [0 : LABEL_W - 1];
    logic [  N*METRIC_W - 1 : 0] o_metrics [0 : N_COS - 1];
    logic [  N*LABEL_W  - 1 : 0] o_labels  [0 : N_COS - 1];
    logic                        o_valid;

    make #(
        .LLR_W   (LLR_W),
        .LABEL_W (LABEL_W),
        .N_COS   (N_COS),
        .N       (N)
    ) dut (
        .clk      (clk),
        .i_valid  (i_valid),
        .i_llr    (i_llr),
        .o_metrics(o_metrics),
        .o_labels (o_labels),
        .o_valid  (o_valid)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task print_outputs;
        for (int c = 0; c < N_COS; c++) begin
            $write("coset %0d: ", c);
            for (int i = 0; i < N; i++) begin
                logic [LABEL_W - 1 : 0]  lab;
                logic [METRIC_W - 1 : 0] met;
                lab = o_labels[c][N*LABEL_W - 1 - i*LABEL_W -: LABEL_W];
                met = o_metrics[c][N*METRIC_W - 1 - i*METRIC_W -: METRIC_W];
                $write("lab=%b metric=%0d  ", lab, met);
            end
            $write("\n");
        end
        $write("\n");
    endtask
    
    always_ff @(posedge clk) begin
        if (o_valid) begin
            $display("RESULTS at time %0t:", $time);
            print_outputs();
        end
    end

    initial begin
        i_valid <= 0;
        for(int i = 0; i < LABEL_W; i++) i_llr[i] <= 0;
        
        @(posedge clk);
        i_valid  <= 1;
        i_llr[0] <= 10;
        i_llr[1] <= -5;
        i_llr[2] <= 3;
        i_llr[3] <= -8;
        
        @(posedge clk);
        i_valid  <= 1;
        i_llr[0] <= -12;
        i_llr[1] <= 7;
        i_llr[2] <= -2;
        i_llr[3] <= 4;
        
        @(posedge clk);
        i_valid  <= 0;

        repeat (20) @(posedge clk);
        $finish;
    end

endmodule