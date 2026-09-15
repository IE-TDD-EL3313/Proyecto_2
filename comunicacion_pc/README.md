# Comunicación con la PC

Configuración UART: reloj de 100 MHz, 115200 baudios, formato 8N1 y línea en
reposo a nivel alto.

## UART RX

`rtl/UART_rx.vhd` conserva la interfaz del receptor entregado por el profesor,
adapta el divisor a la Nexys 4 y sincroniza la entrada asíncrona. La salida
`rx_data_rdy` produce un pulso de un ciclo cuando `rx_data_out` contiene un
byte completo. El testbench transmite y comprueba las letras ASCII A y R.

## Prueba en la Nexys 4

La computadora envía un carácter por USB-UART y la tarjeta muestra:

- `LED7..LED0`: código ASCII recibido;
- `LED8`: cambia de estado con cada byte;
- `LED9`: se enciende cuando el byte está entre `A` y `Z`.

La terminal se configura a 115200 baudios, 8N1 y sin control de flujo. El pin
`C4` conecta la salida del puente USB-UART con `RsRx`.

## UART TX

`rtl/UART_tx.vhd` convierte un byte paralelo en una trama serial 8N1. Un pulso
en `tx_start` guarda el byte e inicia la transmisión. Al finalizar el bit de
parada, `tx_rdy` produce un pulso de un ciclo. El divisor predeterminado es 868
para trabajar a 115200 baudios con el reloj de 100 MHz de la Nexys 4.

La prueba `top_prueba_uart_tx.vhd` envía una `A` cada vez que se presiona BTNC.
`LED0` cambia de estado al terminar cada transmisión. La terminal de la PC debe
usar 115200 baudios, 8N1 y ningún control de flujo. La salida utiliza `RsTx` en
el pin `D4` de la Nexys 4.

## UART completo y prueba de eco

`rtl/UART.vhd` integra RX y TX con la interfaz entregada por el profesor. La
prueba `top_prueba_uart_eco.vhd` devuelve inmediatamente cada byte recibido.
Así, al escribir `A` en la terminal deben aparecer dos `A`: una corresponde al
eco local de la terminal y otra es la respuesta enviada por la FPGA. Si el eco
local está desactivado, aparece solamente la respuesta de la FPGA.

## Banco de registros UART

El archivo `rtl/banco_registros_uart.sv` implementa la interfaz común de 32
bits solicitada en el instructivo:

| `addr_i` | Registro | Campos utilizados |
|---|---|---|
| `00` | `DATA_TX` | `[7:0]`: byte que se enviará |
| `01` | `DATA_RX` | `[7:0]`: último byte recibido |
| `10` | `CONTROL` | bit 0: `send`, bit 1: `new_rx` |
| `11` | Reservado | lectura igual a cero |

`send` permanece activo hasta recibir `tx_done`. `new_rx` se activa cuando
llega un byte y se limpia escribiendo cero en el bit 1 de `CONTROL`.

## Control UART

`rtl/control_uart.sv` genera un único pulso `tx_start` cuando el registro
`send` solicita una transmisión. Mientras TX trabaja mantiene `busy` activo y
no acepta otra solicitud. Al recibir `tx_done`, genera `tx_complete` para que
el banco limpie `send`. También entrega el pulso de recepción como `rx_event`.

## Periférico UART completo

`rtl/periferico_uart.sv` integra el núcleo VHDL RX/TX, el control y el banco de
registros. Hacia el sistema presenta `clk_i`, `rst_i`, `write_enable_i`,
`addr_i[1:0]`, `wdata_i[31:0]` y `rdata_o[31:0]`; hacia el exterior presenta
las líneas seriales `rx_i` y `tx_o`. También expone `new_rx_o` y `busy_o` para
que el controlador principal conozca el estado sin consultar continuamente el
registro CONTROL.

## Protocolo de aplicación

`rtl/generador_tramas_uart.sv` convierte cada evento del juego en un mensaje
de 19 bytes y lo envía escribiendo en `DATA_TX` y `CONTROL`. El formato completo
está documentado en `docs/protocolo_uart.md`.

`rtl/formador_patron_ascii.sv` prepara los 12 caracteres del patrón: muestra
las letras acertadas, usa `_` en posiciones ocultas y completa con espacios las
posiciones que quedan fuera de la longitud de la palabra.
