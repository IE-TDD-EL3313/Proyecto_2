set base_dir [file normalize [file dirname [info script]]]
set bloque_dir [file dirname $base_dir]
read_vhdl -vhdl2008 "$bloque_dir/rtl/UART_rx.vhd"
read_vhdl -vhdl2008 "$base_dir/top_prueba_uart_rx.vhd"
read_xdc "$base_dir/uart_rx_nexys4.xdc"
synth_design -top top_prueba_uart_rx -part xc7a100ticsg324-1L
opt_design
place_design
route_design
report_drc -file "$base_dir/drc_uart_rx.rpt"
report_timing_summary -file "$base_dir/timing_uart_rx.rpt"
write_bitstream -force "$base_dir/top_prueba_uart_rx.bit"
puts "BITSTREAM UART RX GENERADO CORRECTAMENTE"
