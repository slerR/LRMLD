/* Блок Compare-and-select/compare-and-switch типа l-label.
Сортирует два беззнаковых входных числа при этом соответствующим образом мультипексирует метки.
*/

module cas_l #(  
    parameter METRIC_W = 8,
    parameter LABEL_W  = 2,
    parameter USE_FF   = 1  // Use flip-flops 
) (   
    input  logic                    clk     ,
    input  logic [METRIC_W - 1 : 0] i_m[2]  ,// metric 0, 1
    input  logic [ LABEL_W - 1 : 0] i_l[2]  ,// label  0, 1
    output logic [METRIC_W - 1 : 0] o_min   ,// min
    output logic [METRIC_W - 1 : 0] o_max   ,// min
    output logic [ LABEL_W - 1 : 0] o_lmin  ,//label for min
    output logic [ LABEL_W - 1 : 0] o_lmax   //label for max
);
    
    /* ....... Implementation ........ */
    generate
        if (USE_FF == 1) begin
            always_ff @(posedge clk) begin : proc_mux_ff
                if (i_m[0] < i_m[1]) begin
                    o_min  <= i_m[0];
                    o_max  <= i_m[1];
                    o_lmin <= i_l[0];
                    o_lmax <= i_l[1];
                end
                else begin
                    o_min  <= i_m[1];
                    o_max  <= i_m[0];
                    o_lmin <= i_l[1];
                    o_lmax <= i_l[0];
                end
            end
        end
        else begin
            always_comb begin : proc_mux_comb
                if (i_m[0] < i_m[1]) begin
                    o_min  = i_m[0];
                    o_max  = i_m[1];
                    o_lmin = i_l[0];
                    o_lmax = i_l[1];
                end
                else begin
                    o_min  = i_m[1];
                    o_max  = i_m[0];
                    o_lmin = i_l[1];
                    o_lmax = i_l[0];
                end
            end
        end
    endgenerate
endmodule