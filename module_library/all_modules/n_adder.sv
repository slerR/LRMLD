`timescale 1ns / 1ps

module n_adder#(
    parameter  N         = 16,
    parameter  I_W       = 7,
    parameter  O_W       = I_W + $clog2(N),
    parameter  SKIP_ZERO = 0,
    localparam N_STAGES  = $clog2(N)
)(
    input  logic               clk,
    input  logic [I_W - 1 : 0] i_data [0 : N - 1],
    output logic [O_W - 1 : 0] o_data
    );
    
   logic [O_W - 1 : 0] stage_reg [0 : N_STAGES][0 : N - 1];
   
   always_ff @(posedge clk) begin
       for(int  i = 0; i < N; i++) begin
        stage_reg[0][i] <= i_data[i];
       end 
   end
   
   generate
    for(genvar s = 0; s < N_STAGES; s++) begin
        localparam int CUR_SIZE  = (N + (1 << s) -1) >> s;
        localparam int NEXT_SIZE = (CUR_SIZE + 1) >> 1;
        
        if(SKIP_ZERO) begin
            always_ff @(posedge clk) begin
                 for(int i = 0; i < CUR_SIZE/2; i++) begin
                    if(stage_reg[s][2*i] == '0) begin
                        stage_reg[s+1][i] <= stage_reg[s][2*i + 1];   
                    end else if(stage_reg[s][2*i + 1] == '0) begin
                        stage_reg[s+1][i] <= stage_reg[s][2*i];
                    end else begin
                        stage_reg[s + 1][i] <= stage_reg[s][2*i] + stage_reg[s][2*i + 1];                       
                    end 
                end
                if(CUR_SIZE % 2) begin
                    stage_reg[s + 1][NEXT_SIZE - 1] <=  stage_reg[s][CUR_SIZE - 1];
                end  
                for(int i = NEXT_SIZE; i < N; i++) begin
                    stage_reg[s+1][i] <= '0;  
                end      
            end
        end else begin
            always_ff @(posedge clk) begin
                for(int i = 0; i < CUR_SIZE/2; i++) begin
                    stage_reg[s + 1][i] <= stage_reg[s][2*i] + stage_reg[s][2*i + 1];
                end 
                if(CUR_SIZE % 2) begin
                    stage_reg[s + 1][NEXT_SIZE - 1] <=  stage_reg[s][CUR_SIZE - 1];
                end
                for(int i = NEXT_SIZE; i < N; i++) begin
                    stage_reg[s+1][i] <= '0;  
                end 
            end
        end
    end
   endgenerate
   
   assign o_data = stage_reg[N_STAGES][0];
   
endmodule
