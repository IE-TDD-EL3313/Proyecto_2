set pruebas_dir [file dirname [file normalize [info script]]]
set bloque_dir [file dirname $pruebas_dir]
set build_dir "$pruebas_dir/build"

file mkdir $build_dir

read_verilog -sv [glob "$bloque_dir/rtl/*.sv"]
read_verilog -sv "$pruebas_dir/top/top_prueba_entradas_reloj.sv"
read_xdc "$pruebas_dir/constraints/entradas_reloj_nexys4.xdc"

synth_design -top top_prueba_entradas_reloj -part xc7a100ticsg324-1L
opt_design
place_design
route_design

report_drc -file "$build_dir/drc.rpt"
report_timing_summary -file "$build_dir/timing.rpt"
write_bitstream -force "$build_dir/top_prueba_entradas_reloj.bit"

puts "BITSTREAM GENERADO EN: $build_dir/top_prueba_entradas_reloj.bit"
