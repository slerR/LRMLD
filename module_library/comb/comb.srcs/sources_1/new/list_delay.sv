`default_nettype none

module list_delay #(
    parameter DELAY = 16,
    parameter N_OUT = 4,
    parameter WIDTH = 10 
) (
    input  logic             clk,
    input  logic [WIDTH-1:0] i_data [0 : N_OUT - 1],
    output logic [WIDTH-1:0] o_data [0 : N_OUT - 1]
);

    logic [N_OUT*WIDTH-1:0] flat_in;
    logic [N_OUT*WIDTH-1:0] flat_out;

    genvar i;
    generate
        for (i = 0; i < N_OUT; i = i + 1) begin : pack
            assign flat_in[i*WIDTH +: WIDTH] = i_data[i];
            assign o_data[i] = flat_out[i*WIDTH +: WIDTH];
        end
    endgenerate

    delay_line #(
        .DELAY(DELAY),
        .WIDTH(N_OUT*WIDTH),
        .STYLE("register")
    ) dl_inst (
        .clk(clk),
        .data_in(flat_in),
        .data_out(flat_out)
    );

endmodule