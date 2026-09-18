## ===========================================================================
## Prueba de Gestión de Entradas Locales y Reloj - Nexys 4 Rev. B
## FPGA: xc7a100ticsg324-1L
## ===========================================================================

## Voltaje del banco de configuración de la tarjeta
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

## Reloj de 100 MHz
set_property PACKAGE_PIN E3 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0.000 5.000} [get_ports clk]

## Reinicio electrónico CPU_RESETN, activo en bajo
set_property PACKAGE_PIN C12 [get_ports cpu_reset_n]
set_property IOSTANDARD LVCMOS33 [get_ports cpu_reset_n]

## Botones del juego
## BTNU: seleccionar dificultad
set_property PACKAGE_PIN F15 [get_ports btn_sel_i]
set_property IOSTANDARD LVCMOS33 [get_ports btn_sel_i]

## BTNC: confirmar o iniciar
set_property PACKAGE_PIN E16 [get_ports btn_ok_i]
set_property IOSTANDARD LVCMOS33 [get_ports btn_ok_i]

## BTND: reiniciar el juego
set_property PACKAGE_PIN V10 [get_ports btn_rst_i]
set_property IOSTANDARD LVCMOS33 [get_ports btn_rst_i]

## LED0: BTN_SEL; LED1: BTN_OK; LED2: BTN_RST; LED3: señal de un segundo
set_property PACKAGE_PIN T8 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]

set_property PACKAGE_PIN V9 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]

set_property PACKAGE_PIN R8 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]

set_property PACKAGE_PIN T6 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
