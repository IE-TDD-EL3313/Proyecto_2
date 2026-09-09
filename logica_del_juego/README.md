

Organizado en 3 bloques funcionales + una carpeta de pruebas de integración.

## gestion_palabras/
- `rtl/lfsr8.sv` — LFSR de 8 bits (free-running)
- `rtl/word_bank_rom.sv` — ROM con las 50 palabras
- `rtl/gestion_palabras.sv` — top del bloque (integra LFSR + ROM + registro/comparador)
- `tb/tb_gestion_palabras.sv` — testbench autoverificable (18 pruebas)

> **NOTA — palabra fijada para pruebas manuales:**
> `word_bank_rom.sv` está actualmente **fijado** en la palabra `"AMOR"`, para
> poder probar el flujo completo de una partida en la FPGA (revelar letras,
> ganar, contar partidas) sabiendo de antemano cuál es la palabra secreta.
> Mientras quede así, **siempre sale "AMOR"**, sin importar la dificultad ni
> cuántas veces se reinicie.
>
> Al final del archivo `word_bank_rom.sv` hay dos líneas: una activa (la
> palabra fija) y otra comentada (la selección real por índice/LFSR):
> ```systemverilog
> always_comb palabra_rom = 64'h4000000000093DA1; // "AMOR"
>
> // always_comb palabra_rom = rom[direccion[5:0]]; // <-- version normal
> ```
> **Antes de la entrega/demo final**, hay que comentar la primera línea y
> descomentar la segunda, para regresar a la selección pseudoaleatoria real
> del banco de 50 palabras. El testbench (`tb_gestion_palabras.sv`) espera
> la versión normal (aleatoria) — si se deja la palabra fija, varias de sus
> 18 pruebas van a fallar a propósito, como aviso de que quedó en modo prueba.

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

- `top/boton_pulso.sv` — sustituto provisional de "Gestión de entradas locales"
- `top/clk_div_1s.sv` — sustituto provisional de "Reloj Integrado"
- `top/seg7_mux_driver.sv` — sustituto provisional de "Gestión de Visualización"
- `top/top_test_ahorcado.sv` — top-level del harness de prueba (NO es el top final del proyecto)
- `constraints/ahorcado_test.xdc` — constraints del harness

Cuando el resto del equipo entregue sus bloques reales, esta carpeta se
descarta y se reemplaza por el top-level definitivo del proyecto.

## Cómo simular cada bloque en Vivado
Agregar SOLO los archivos de `rtl/` de un bloque como Design Sources, y su
`tb/` como Simulation Source (fileset `sim_1`). Cada testbench imprime
`TODAS LAS PRUEBAS PASARON` si todo esta correcto.

## Cómo sintetizar / probar en la FPGA
Agregar los `rtl/` de los tres bloques + `pruebas_fpga/top/*.sv` como Design
Sources, poner `top_test_ahorcado` como Top Module, agregar
`pruebas_fpga/constraints/ahorcado_test.xdc`, y generar bitstream.
