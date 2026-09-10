# Gestión de entradas locales y reloj

Este bloque reemplaza los módulos provisionales `boton_pulso.sv` y
`clk_div_1s.sv` utilizados por el arnés de pruebas de la lógica del juego.

## Estructura

- `rtl/generador_ce.sv`: divisor parametrizable que genera un pulso de un ciclo.
- `rtl/reloj_integrado.sv`: genera `ce_debounce`, `ce_1s` y `ce_display`.
- `rtl/banco_sincronizadores.sv`: sincronizador de dos etapas para los botones.
- `tb/tb_reloj_integrado.sv`: prueba autoverificable del bloque de reloj.
- `tb/tb_banco_sincronizadores.sv`: prueba del banco de sincronizadores.

El diseño utiliza exclusivamente el reloj principal `clk`; las salidas `ce_*`
son habilitaciones y no deben conectarse como relojes derivados.

La convención utilizada para los buses de botones es:

- `btn[0]`: `BTN_SEL`.
- `btn[1]`: `BTN_OK`.
- `btn[2]`: `BTN_RST`.
