# Comunicación con la PC

Configuración UART: reloj de 100 MHz, 115200 baudios, formato 8N1 y línea en
reposo a nivel alto.

## UART RX

`rtl/UART_rx.vhd` conserva la interfaz del receptor entregado por el profesor,
adapta el divisor a la Nexys 4 y sincroniza la entrada asíncrona. La salida
`rx_data_rdy` produce un pulso de un ciclo cuando `rx_data_out` contiene un
byte completo. El testbench transmite y comprueba las letras ASCII A y R.
