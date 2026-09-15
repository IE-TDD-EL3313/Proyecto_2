# Protocolo de aplicación UART

La comunicación usa 115200 baudios, 8N1. La PC envía un único byte ASCII
mayúsculo (`A`–`Z`) por intento. La FPGA descarta cualquier otro byte.

## Mensajes FPGA → PC

Todos los mensajes tienen 19 bytes:

| Byte | Campo | Codificación |
|---:|---|---|
| 0 | Inicio | `0x7E` |
| 1 | Tipo | `I` inicio, `L` letra, `F` final |
| 2 | Modo | `0` fácil, `1` difícil |
| 3 | Longitud | valor binario de 4 a 12 |
| 4 | Resultado | depende del tipo de mensaje |
| 5 | Intentos | cantidad restante, de 0 a 6 |
| 6–17 | Patrón | 12 bytes ASCII: letra revelada, `_` oculta o espacio fuera de la palabra |
| 18 | Fin | salto de línea `0x0A` |

En mensajes tipo `L`, resultado vale `1` para acierto, `2` para error y `3`
para letra repetida. En mensajes tipo `F`, vale `1` para victoria, `2` para
derrota por intentos y `3` para derrota por tiempo. En el mensaje `I` vale 0.

Ejemplo al iniciar una partida fácil con una palabra de cuatro letras:

```text
7E 49 00 04 00 06 5F 5F 5F 5F 20 20 20 20 20 20 20 20 0A
```

El tamaño fijo simplifica la recepción en Python. `0x7E` permite recuperar la
sincronización si la aplicación empieza a leer en medio de un mensaje.
