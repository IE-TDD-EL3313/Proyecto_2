# Gestión de entradas locales y reloj

Este bloque reemplaza los módulos provisionales `boton_pulso.sv` y
`clk_div_1s.sv` utilizados por el arnés de pruebas de la lógica del juego.

## Estructura

- `rtl/generador_ce.sv`: divisor parametrizable que genera un pulso de un ciclo.
- `rtl/reloj_integrado.sv`: genera `ce_debounce`, `ce_1s` y `ce_display`.
- `tb/tb_reloj_integrado.sv`: prueba autoverificable del bloque de reloj.

El diseño utiliza exclusivamente el reloj principal `clk`; las salidas `ce_*`
son habilitaciones y no deben conectarse como relojes derivados.
