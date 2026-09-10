# Gestión de entradas locales y reloj

Este bloque reemplaza los módulos provisionales `boton_pulso.sv` y
`clk_div_1s.sv` utilizados por el arnés de pruebas de la lógica del juego.

## Estructura

- `rtl/generador_ce.sv`: divisor parametrizable que genera un pulso de un ciclo.
- `rtl/reloj_integrado.sv`: genera `ce_debounce`, `ce_1s` y `ce_display`.
- `rtl/banco_sincronizadores.sv`: sincronizador de dos etapas para los botones.
- `rtl/filtro_antirrebote.sv`: exige muestras consecutivas antes de aceptar
  una transición.
- `rtl/banco_filtros_antirrebote.sv`: aplica el filtro a los tres botones.
- `rtl/detector_flanco_subida.sv`: genera un pulso al detectar una transición
  estable de 0 a 1.
- `rtl/banco_detectores_flanco.sv`: genera los pulsos de los tres botones.
- `rtl/gestion_entradas_locales.sv`: integra la cadena completa y entrega
  `sel_pulse`, `ok_pulse` y `rst_pulse`.
- `tb/tb_reloj_integrado.sv`: prueba autoverificable del bloque de reloj.
- `tb/tb_banco_sincronizadores.sv`: prueba del banco de sincronizadores.
- `tb/tb_banco_filtros_antirrebote.sv`: prueba rebotes, pulsación, liberación
  e independencia entre canales.
- `tb/tb_banco_detectores_flanco.sv`: comprueba pulsos individuales,
  simultáneos y botones mantenidos.
- `tb/tb_gestion_entradas_locales.sv`: inyecta rebotes en los botones físicos
  y verifica la cadena completa.

El diseño utiliza exclusivamente el reloj principal `clk`; las salidas `ce_*`
son habilitaciones y no deben conectarse como relojes derivados.

La convención utilizada para los buses de botones es:

- `btn[0]`: `BTN_SEL`.
- `btn[1]`: `BTN_OK`.
- `btn[2]`: `BTN_RST`.

Con la configuración definitiva, el antirrebote toma 20 muestras a 1 kHz, por
lo que una transición debe permanecer estable durante 20 ms para ser aceptada.
