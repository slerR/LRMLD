`timescale 1ns / 1ps

module tb_sum_select_12;
    parameter M_W = 10;
    parameter L_W = 6;
    parameter L_W1 = 6;

    logic clk;
    logic i_valid;
    logic [12*M_W-1 : 0] i_metrics,  i_metrics1;
    logic [12*L_W-1 : 0] i_labels;
    logic [12*L_W1-1 : 0] i_labels1;
    
    logic [M_W-1 : 0] o_metrics [0 : 11];
    logic [(L_W+L_W1)-1 : 0] o_labels [0 : 11];
    logic o_valid;
    
    // Блок вывода результатов в консоль
    always_ff @(posedge clk) begin
        if (o_valid) begin
            $display("--- New Valid Output Detected ---");
            for (int i = 0; i < 12; i++) begin
                $display("Index %0d: Metric = %0d, Label = %b", 
                         i, o_metrics[i], o_labels[i]);
            end
        end
    end

    sum_select_12_bm_ir #(
        .METRIC_W(M_W),
        .LABEL_W(L_W),
        .LABEL_W1(L_W1)
    ) dut (.*);

    always #5 clk = (clk === 1'b0);

    initial begin
        clk = 0;
        i_valid = 0;
        repeat(2) @(posedge clk);
        i_valid <= 1;
        for (int i = 0; i < 12; i++) begin
            i_metrics[12*M_W - 1 - i*M_W -: M_W]   <= (i + 1) * 10;
            i_metrics1[12*M_W - 1 - i*M_W -: M_W]  <= i * 10 + 5;
            
            i_labels [   12*L_W - 1 - i*L_W -: L_W] <= i;
            i_labels1[12*L_W1 - 1 - i*L_W1 -: L_W1] <= i + 1;
        end

        @(posedge clk);
        for (int i = 0; i < 12; i++) begin
            i_metrics[12*M_W - 1 - i*M_W -: M_W]   <= (i + 2) * 3;
            i_metrics1[12*M_W - 1 - i*M_W -: M_W]  <= i * 3 + 5;
            
            i_labels [   12*L_W - 1 - i*L_W -: L_W] <= i;
            i_labels1[12*L_W1 - 1 - i*L_W1 -: L_W1] <= i + 2;
        end
        
        @(posedge clk);
        for (int i = 0; i < 12; i++) begin
            i_metrics[12*M_W - 1 - i*M_W -: M_W]   <= i;
            i_metrics1[12*M_W - 1 - i*M_W -: M_W]  <= i;
            
            i_labels [   12*L_W - 1 - i*L_W -: L_W] <= 0;
            i_labels1[12*L_W1 - 1 - i*L_W1 -: L_W1] <= i;
        end
        
        @(posedge clk);
        i_valid <= 0; 
        
        repeat(20) @(posedge clk);
        $finish;
    end

endmodule