

Organizado en 3 bloques funcionales + una carpeta de pruebas de integración.

## gestion_palabras/
- `rtl/lfsr8.sv` — LFSR de 8 bits (free-running)
- `rtl/word_bank_rom.sv` — ROM con las 50 palabras
- `rtl/gestion_palabras.sv` — top del bloque (integra LFSR + ROM + registro/comparador)
- `tb/tb_gestion_palabras.sv` — testbench autoverificable (18 pruebas)

> **NOTA — palabra fijada para pruebas manuales:**
> El diseño normal mantiene la selección de las 50 palabras mediante el LFSR.
> El arnés `pruebas_fpga/top_test_ahorcado.sv` activa `MODO_PRUEBA`, por lo que
> en esa prueba física la palabra siempre es `"AMOR"`. Esto permite comprobar
> aciertos, victoria y conteo de partidas con una palabra conocida.
>
> Para cambiar la palabra de prueba se puede modificar el parámetro
> `PALABRA_PRUEBA`; no es necesario alterar ni comentar la ROM normal. El
> testbench `tb_gestion_palabras.sv` usa los parámetros por defecto y, por
> tanto, comprueba la selección normal del banco de 50 palabras.

## gestion_tiempo/
- `rtl/temporizador_partida.sv` — FSM de 2 estados (IDLE/CONTANDO) + registros
- `tb/tb_temporizador_partida.sv` — testbench autoverificable (9 pruebas)

## control_coordinacion/
- `rtl/registro_modo.sv`
- `rtl/unidad_control.sv` — FSM principal de 5 estados
- `rtl/datapath_juego.sv`
- `rtl/control_coordinacion.sv` — top del bloque (integra los tres anteriores)
- `tb/tb_control_coordinacion.sv` — testbench autoverificable (25 pruebas)

## pruebas_fpga/
Harness de integración SOLO para probar los tres bloques anteriores en la
Nexys4 antes de la integración final con el resto del equipo. Ninguno de
estos archivos pertenece a los bloques anteriores — son sustitutos mínimos
de bloques que le corresponden a otro sub-equipo:

  - la entrada de letras ya utiliza `comunicacion_pc/rtl/` mediante USB-UART
- `top/seg7_mux_driver.sv` — sustituto provisional de "Gestión de Visualización"
- `top/top_test_ahorcado.sv` — top-level del harness de prueba (NO es el top final del proyecto)
- `constraints/ahorcado_test.xdc` — constraints del harness

El arnés ya utiliza `gestion_entradas_reloj/rtl/entradas_reloj.sv` para BTNU,
BTNC, BTND y la habilitación de un segundo. Las letras se reciben desde la PC
por el periférico UART. La FPGA devuelve mensajes de inicio, resultado de cada
letra y final de partida según `comunicacion_pc/docs/protocolo_uart.md`. La
visualización sigue siendo provisional hasta integrar su bloque definitivo.

## Cómo simular cada bloque en Vivado
Agregar SOLO los archivos de `rtl/` de un bloque como Design Sources, y su
`tb/` como Simulation Source (fileset `sim_1`). Cada testbench imprime
`TODAS LAS PRUEBAS PASARON` si todo esta correcto.

## Cómo sintetizar / probar en la FPGA
Agregar los `rtl/` de los tres bloques + `pruebas_fpga/top/*.sv` como Design
Sources, poner `top_test_ahorcado` como Top Module, agregar
`pruebas_fpga/constraints/ahorcado_test.xdc`, y generar bitstream.
