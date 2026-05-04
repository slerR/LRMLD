module comparator #(
    parameter DATA_W = 6  
) (
    input  logic [DATA_W - 1 : 0]  i_data,    
    input  logic [DATA_W - 1 : 0]  i_data1,
    output logic                   o_flag,     
    output logic [DATA_W - 1 : 0]  o_min, 
    output logic [DATA_W - 1 : 0]  o_max  
);

    always_comb begin
        if ($unsigned(i_data) <= $unsigned(i_data1)) begin
            o_flag = 1'b1;
            o_min  = i_data;
            o_max  = i_data1;
        end else begin
            o_flag = 1'b0;
            o_min  = i_data1;
            o_max  = i_data;
        end
    end
    
endmodule