# Testbenches de la implementación final

| Archivo | Módulo o integración verificada |
|---|---|
| `tb_game_core.sv` | FSM, selección de palabra, letras, intentos y tiempo |
| `tb_game_uart.sv` | Integración de `game_core` con `uart_game_interface` |
| `tb_uart_peripheral.sv` | Recepción y transmisión UART |
| `tb_lcd_peripheral.sv` | Interfaz de registros y transferencias al LCD |
| `tb_lcd_screen_controller.sv` | Contenido de las pantallas del juego |
| `tb_io_controller.sv` | Display de siete segmentos y buzzer |
| `tb_hangman_timing.sv` | Temporización del top original `hangman_top` |
| `tb_hangman_completo.sv` | Verificación integrada del top final |

