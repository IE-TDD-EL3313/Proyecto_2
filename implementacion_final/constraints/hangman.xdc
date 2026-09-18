## ============================================================
## P2 AHORCADO - BASYS3
## TOP: hangman_top
## ============================================================


## CLOCK 100 MHz

set_property PACKAGE_PIN W5 [get_ports CLK100MHZ]
set_property IOSTANDARD LVCMOS33 [get_ports CLK100MHZ]

create_clock -add -name sys_clk_pin \
    -period 10.000 \
    -waveform {0 5.000} \
    [get_ports CLK100MHZ]


## ============================================================
## BOTONES
## ============================================================

## BTNC - Reset
set_property PACKAGE_PIN U18 [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

## BTNU - Fácil
set_property PACKAGE_PIN T18 [get_ports btnU]
set_property IOSTANDARD LVCMOS33 [get_ports btnU]

## BTND - Difícil
set_property PACKAGE_PIN U17 [get_ports btnD]
set_property IOSTANDARD LVCMOS33 [get_ports btnD]


## ============================================================
## UART USB
## ============================================================

set_property PACKAGE_PIN B18 [get_ports RsRx]
set_property IOSTANDARD LVCMOS33 [get_ports RsRx]

set_property PACKAGE_PIN A18 [get_ports RsTx]
set_property IOSTANDARD LVCMOS33 [get_ports RsTx]


## ============================================================
## LEDS
## ============================================================

set_property PACKAGE_PIN U16 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]

set_property PACKAGE_PIN E19 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]

set_property PACKAGE_PIN U19 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]

set_property PACKAGE_PIN V19 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]


## ============================================================
## LCD J1 -> JXADC
## ============================================================

## DB0
set_property PACKAGE_PIN J3 [get_ports {lcd_data[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_data[0]}]

## DB1
set_property PACKAGE_PIN L3 [get_ports {lcd_data[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_data[1]}]

## DB2
set_property PACKAGE_PIN M2 [get_ports {lcd_data[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_data[2]}]

## DB3
set_property PACKAGE_PIN N2 [get_ports {lcd_data[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_data[3]}]

## DB4
set_property PACKAGE_PIN K3 [get_ports {lcd_data[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_data[4]}]

## DB5
set_property PACKAGE_PIN M3 [get_ports {lcd_data[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_data[5]}]

## DB6
set_property PACKAGE_PIN M1 [get_ports {lcd_data[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_data[6]}]

## DB7
set_property PACKAGE_PIN N1 [get_ports {lcd_data[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_data[7]}]


## ============================================================
## LCD J2 -> FILA INFERIOR JA
##
## J2-1 RS  -> JA7
## J2-2 RW  -> JA8
## J2-3 E   -> JA9
## J2-4 NC  -> JA10
## J2-5 GND -> GND
## J2-6 VCC -> 3V3
## ============================================================

set_property PACKAGE_PIN H1 [get_ports lcd_rs]
set_property IOSTANDARD LVCMOS33 [get_ports lcd_rs]

set_property PACKAGE_PIN K2 [get_ports lcd_rw]
set_property IOSTANDARD LVCMOS33 [get_ports lcd_rw]

set_property PACKAGE_PIN H2 [get_ports lcd_e]
set_property IOSTANDARD LVCMOS33 [get_ports lcd_e]


## ============================================================
## DISPLAY 7 SEGMENTOS
## ============================================================

## A
set_property PACKAGE_PIN W7 [get_ports {seg[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[0]}]

## B
set_property PACKAGE_PIN W6 [get_ports {seg[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[1]}]

## C
set_property PACKAGE_PIN U8 [get_ports {seg[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[2]}]

## D
set_property PACKAGE_PIN V8 [get_ports {seg[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[3]}]

## E
set_property PACKAGE_PIN U5 [get_ports {seg[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[4]}]

## F
set_property PACKAGE_PIN V5 [get_ports {seg[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[5]}]

## G
set_property PACKAGE_PIN U7 [get_ports {seg[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[6]}]


## Punto decimal

set_property PACKAGE_PIN V7 [get_ports dp]
set_property IOSTANDARD LVCMOS33 [get_ports dp]


## Ánodos

set_property PACKAGE_PIN U2 [get_ports {an[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[0]}]

set_property PACKAGE_PIN U4 [get_ports {an[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[1]}]

set_property PACKAGE_PIN V4 [get_ports {an[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[2]}]

set_property PACKAGE_PIN W4 [get_ports {an[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[3]}]


## ============================================================
## BUZZER ACTIVO -> JB1
## ============================================================

set_property PACKAGE_PIN A14 [get_ports buzzer_out]
set_property IOSTANDARD LVCMOS33 [get_ports buzzer_out]