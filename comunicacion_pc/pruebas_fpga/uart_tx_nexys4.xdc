set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

set_property PACKAGE_PIN E3 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

set_property PACKAGE_PIN C12 [get_ports btnCpuReset]
set_property IOSTANDARD LVCMOS33 [get_ports btnCpuReset]
set_property PACKAGE_PIN E16 [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

# Entrada RX del puente USB-UART, manejada por la salida TX de la FPGA
set_property PACKAGE_PIN D4 [get_ports RsTx]
set_property IOSTANDARD LVCMOS33 [get_ports RsTx]

set_property PACKAGE_PIN T8 [get_ports {led[0]}]
set_property PACKAGE_PIN V9 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]
