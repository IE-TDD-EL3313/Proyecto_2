set base_dir [file normalize [file dirname [info script]]]
set bloque_dir [file dirname $base_dir]
read_vhdl -vhdl2008 "$bloque_dir/rtl/UART_rx.vhd"
read_vhdl -vhdl2008 "$bloque_dir/rtl/UART_tx.vhd"
read_vhdl -vhdl2008 "$bloque_dir/rtl/UART.vhd"
read_vhdl -vhdl2008 "$base_dir/top_prueba_uart_eco.vhd"
read_xdc "$base_dir/uart_eco_nexys4.xdc"
synth_design -top top_prueba_uart_eco -part xc7a100ticsg324-1L
opt_design
place_design
route_design
report_drc -file "$base_dir/drc_uart_eco.rpt"
report_timing_summary -file "$base_dir/timing_uart_eco.rpt"
write_bitstream -force "$base_dir/top_prueba_uart_eco.bit"
puts "BITSTREAM DE ECO UART GENERADO CORRECTAMENTE"
