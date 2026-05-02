# Clock configuration
set_property PACKAGE_PIN AA13  [get_ports {clk}]
set_property IOSTANDARD LVCMOS33 [get_ports {clk}]
create_clock -add -name sys_clk_pin -period 1 -waveform {0 0.5} [get_ports {clk}]
