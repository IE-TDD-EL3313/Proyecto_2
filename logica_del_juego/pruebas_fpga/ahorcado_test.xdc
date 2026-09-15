## ============================================================================

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
## ahorcado_test.xdc
## Constraints para top_test_ahorcado.sv en el Nexys4 (rev B).
## Basado en Nexys-4-Master.xdc; solo se descomentan y renombran los pines
## realmente usados por este harness de prueba (Gestion de Palabras,
## Gestion del Tiempo, Control y Coordinacion).
## ============================================================================

## ---------------- Reloj ----------------
set_property PACKAGE_PIN E3 [get_ports clk]
    set_property IOSTANDARD LVCMOS33 [get_ports clk]
    create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## ---------------- Botones ----------------
## CPU RESET: activo en BAJO; se conecta directamente a rst_n
set_property PACKAGE_PIN C12 [get_ports btnCpuReset]
    set_property IOSTANDARD LVCMOS33 [get_ports btnCpuReset]

## BTNC = ok_pulse (confirmar modo / iniciar partida)
set_property PACKAGE_PIN E16 [get_ports btnC]
    set_property IOSTANDARD LVCMOS33 [get_ports btnC]

## BTNU = sel_pulse (alternar dificultad)
set_property PACKAGE_PIN F15 [get_ports btnU]
    set_property IOSTANDARD LVCMOS33 [get_ports btnU]

## BTND = rst_pulse (reiniciar el juego sin reiniciar la electronica)
set_property PACKAGE_PIN V10 [get_ports btnD]
    set_property IOSTANDARD LVCMOS33 [get_ports btnD]

## ---------------- USB-UART ----------------
set_property PACKAGE_PIN C4 [get_ports RsRx]
    set_property IOSTANDARD LVCMOS33 [get_ports RsRx]
set_property PACKAGE_PIN D4 [get_ports RsTx]
    set_property IOSTANDARD LVCMOS33 [get_ports RsTx]

## ---------------- LEDs de diagnostico: led[9:0] ----------------
set_property PACKAGE_PIN T8 [get_ports {led[0]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property PACKAGE_PIN V9 [get_ports {led[1]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property PACKAGE_PIN R8 [get_ports {led[2]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property PACKAGE_PIN T6 [get_ports {led[3]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
set_property PACKAGE_PIN T5 [get_ports {led[4]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]
set_property PACKAGE_PIN T4 [get_ports {led[5]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]
set_property PACKAGE_PIN U7 [get_ports {led[6]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]
set_property PACKAGE_PIN U6 [get_ports {led[7]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]
set_property PACKAGE_PIN V4 [get_ports {led[8]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {led[8]}]
set_property PACKAGE_PIN U3 [get_ports {led[9]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {led[9]}]

## ---------------- Display de 7 segmentos ----------------
set_property PACKAGE_PIN L3 [get_ports {seg[0]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {seg[0]}]
set_property PACKAGE_PIN N1 [get_ports {seg[1]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {seg[1]}]
set_property PACKAGE_PIN L5 [get_ports {seg[2]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {seg[2]}]
set_property PACKAGE_PIN L4 [get_ports {seg[3]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {seg[3]}]
set_property PACKAGE_PIN K3 [get_ports {seg[4]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {seg[4]}]
set_property PACKAGE_PIN M2 [get_ports {seg[5]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {seg[5]}]
set_property PACKAGE_PIN L6 [get_ports {seg[6]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {seg[6]}]

set_property PACKAGE_PIN M4 [get_ports dp]
    set_property IOSTANDARD LVCMOS33 [get_ports dp]

set_property PACKAGE_PIN N6 [get_ports {an[0]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {an[0]}]
set_property PACKAGE_PIN M6 [get_ports {an[1]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {an[1]}]
set_property PACKAGE_PIN M3 [get_ports {an[2]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {an[2]}]
set_property PACKAGE_PIN N5 [get_ports {an[3]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {an[3]}]
set_property PACKAGE_PIN N2 [get_ports {an[4]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {an[4]}]
set_property PACKAGE_PIN N4 [get_ports {an[5]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {an[5]}]
set_property PACKAGE_PIN L1 [get_ports {an[6]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {an[6]}]
set_property PACKAGE_PIN M1 [get_ports {an[7]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {an[7]}]

## ============================================================================
## NOTA: los switches y el resto de conectores (Pmod, VGA, etc.) no se usan en
## este harness de prueba y se dejan sin declarar (Vivado los ignora si no
## aparecen como puertos del top). Antes de la integracion final con UART y
## LCD, este archivo debe fusionarse con los constraints de esos bloques.
## ============================================================================
