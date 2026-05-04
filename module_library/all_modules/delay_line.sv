/*******************************************************
Description : Delay line
- SRL STYLE:
  - auto
  - register    : The tool does not infer an SRL, but instead only uses registers.
  - srl         : The tool infers an SRL without any registers before or after.
  - srl_reg     : The tool infers an SRL and leaves one register after the SRL.
  - reg_srl     : The tool infers an SRL and leaves one register before the SRL.
  - reg_srl_reg : The tool infers an SRL and leaves one register before and one register after the SRL.
  - block       : The tool infers the SRL inside a block RAM.
*******************************************************/

`default_nettype none

module delay_line #(
  parameter DELAY = 16,
  parameter WIDTH = 1 ,
  parameter STYLE = "register" // "auto", register", "srl", "srl_reg", "reg_srl", "reg_srl_reg", "block"
) (
  input  wire             clk     ,
  input  wire [WIDTH-1:0] data_in ,
  output wire [WIDTH-1:0] data_out
);

  (* srl_style = STYLE *)
  reg [DELAY-1:0] shreg [WIDTH-1:0];

  genvar i;
  generate
    if (DELAY == 0) begin
      assign data_out = data_in;

    end else if (DELAY == 1) begin
      reg [WIDTH-1:0] dreg = {WIDTH{1'b0}};
      always @(posedge clk)
        dreg <= data_in;
      assign data_out = dreg;

    end else begin
      integer k;
      initial begin : init_empty_register
        for (k = 0; k < WIDTH; k = k + 1)
          shreg[k] <= {DELAY{1'b0}};
      end

      for (i = 0; i < WIDTH; i = i + 1) begin : shift_register
        always @(posedge clk) begin
          shreg[i] <= {shreg[i][DELAY-2:0], data_in[i]};
        end
        assign data_out[i] = shreg[i][DELAY-1];
      end
    end
  endgenerate

endmodule
`default_nettype wire
