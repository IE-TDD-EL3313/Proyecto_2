# Informe técnico: Ahorcado — juego electrónico FPGA / PC por enlace serial

<!--
PLANTILLA — Proyecto 2

Esta plantilla sigue las categorías de la rúbrica "Documentación técnica (informe)":
  - Fundamentación teórica ........................ 20%
  - Presentación de resultados ..................... 30%
  - Análisis e interpretación de resultados ........ 25%
  - Conclusiones y aprendizaje obtenido ............ 15%
  - Calidad y organización del documento ........... 10%

Reglas de formato que deben respetarse en TODO el documento:
  - Un único nivel de encabezado por jerarquía: ## para secciones principales,
    ### para subsecciones, #### para sub-subsecciones (p. ej. "Entradas",
    "Salidas", "Funcionamiento" y "Relación con el sistema" dentro de cada
    módulo). No usar "##" para estos últimos: rompe la estructura del
    documento y afecta "Calidad y organización".
  - Cada figura, tabla o forma de onda debe llevar numeración y una leyenda
    explicando qué muestra y qué se debe observar en ella.
  - La sección de resultados (10) debe ser explícita e independiente del
    análisis: aquí se presentan datos, capturas y mediciones; la
    interpretación crítica va en la sección 11.
  - Los tres integrantes escriben en este mismo archivo. Las marcas
    [INTEGRANTE 1/2/3] indican responsable según DISTRIBUCION_DOCUMENTACION_
    PROYECTO_2.txt y deben eliminarse antes de la entrega final.
-->

## Resumen

Este informe presenta el diseño e implementación de un juego electrónico de Ahorcado en el cual una FPGA Basys 3 concentra la totalidad del control de la partida y una aplicación de computadora personal, desarrollada en Python, actúa como terminal remota del jugador mediante un enlace serial UART a 115200 baudios. El sistema, integrado en el módulo superior `hangman_top`, está compuesto por un módulo de control `game_core` que implementa la máquina de estados `MENU → GAME → RESULT → MENU`, selecciona la palabra secreta mediante un generador pseudoaleatorio LFSR de 8 bits y consulta un banco de 50 palabras (`word_bank`) descrito como una memoria de solo lectura combinacional; un bloque `uart_game_interface` que encapsula un núcleo `uart_peripheral` y define un protocolo de aplicación propio basado en tramas con encabezado `0xA5` para notificar el inicio de partida, el resultado de cada letra y el resultado final; y los periféricos de visualización y retroalimentación local: `lcd_screen_controller`/`lcd_peripheral` para el LCD PmodCLP (HD44780), e `io_controller` para los displays de siete segmentos, el LED de estado y el buzzer. Las simulaciones unitarias e integradas del sistema, así como los procesos de síntesis, implementación y análisis de timing, se completaron satisfactoriamente, y el sistema demostró jugabilidad completa sobre la tarjeta Basys 3: selección de dificultad, recepción y validación de letras, actualización del LCD y de los displays, control del tiempo y de los intentos, y comunicación bidireccional con la aplicación de PC. Como trabajo pendiente queda principalmente la optimización del diseño y la incorporación de patrones sonoros diferenciados en el buzzer para distinguir con mayor claridad entre acierto, error, victoria y derrota.
---

## 1. Introducción

### 1.1 Contexto

Ahorcado (*Hangman*) es un juego clásico de adivinanza de palabras en el que el jugador propone letras, una a la vez, intentando descubrir una palabra secreta antes de agotar un número máximo de intentos fallidos. Este segundo proyecto del curso integra diseño digital secuencial, arquitectura modular de periféricos y comunicación serial para construir una aplicación interactiva completa entre una FPGA y una computadora personal. A diferencia del Proyecto 1, donde el control del juego dependía únicamente de entradas locales (*push buttons*), en este proyecto la FPGA debe coordinar su lógica de control con una aplicación externa ejecutada en la PC, comunicándose con ella mediante un periférico UART y presentando el estado de la partida de forma local en un LCD PmodCLP (compatible HD44780) y en displays de siete segmentos.
 
El proyecto se implementó sobre una tarjeta **Basys 3**, utilizando como periféricos de entrada los pulsadores `btnC`, `btnU` y `btnD`; como periféricos de salida un LCD de 16×2 (PmodCLP), cuatro displays de siete segmentos multiplexados, cuatro LED de estado y un buzzer; y como enlace de comunicación con la PC un puerto serie UART (`RsRx`/`RsTx`) a 115200 baudios.

### 1.2 Solución desarrollada

La solución desarrollada concentra toda la inteligencia y el control de la partida dentro de la FPGA, en el módulo superior `hangman_top`. Este módulo instancia y conecta los siguientes bloques:
 
- `game_core`: máquina de estados y *datapath* principal del juego. Selecciona la palabra secreta mediante un generador pseudoaleatorio LFSR de 8 bits interno, consulta el banco de palabras (`word_bank`), valida cada letra recibida, controla el tiempo restante y los intentos fallidos, y determina el resultado de la partida.
- `word_bank`: memoria de solo lectura combinacional con 50 palabras de longitud fija de 12 caracteres (rellenadas con espacios), junto con su longitud real, indexada de 0 a 49.
- `uart_game_interface`: encapsula un núcleo `uart_peripheral` y expone hacia `game_core` una letra recibida (`letter`, `letter_valid`); además construye y transmite hacia la PC las tramas del protocolo de aplicación (inicio de partida, resultado de letra, resultado final) a partir del estado que le entrega `game_core`.
- `lcd_screen_controller` y `lcd_peripheral`: el primero decide qué texto debe mostrarse en cada momento de la partida y el segundo controla físicamente el LCD PmodCLP a través de la interfaz de registros de 32 bits (`write_enable_i`, `addr_i`, `wdata_i`, `rdata_o`).
- `io_controller`: multiplexa los displays de siete segmentos (tiempo restante y contador de victorias) y genera la retroalimentación sonora del buzzer.
La PC ejecuta una aplicación en Python (`juego_uart.py`) que actúa únicamente como terminal remota: valida que la entrada del usuario sea una sola letra A–Z, la transmite por UART, y en un hilo independiente recibe e interpreta las tramas enviadas por la FPGA (identificadas por el byte de encabezado `0xA5`) para mostrar en consola el estado de la partida.

### 1.3 Alcance y limitaciones

El alcance logrado corresponde a un juego de Ahorcado completamente funcional y jugable de principio a fin sobre la Basys 3: el sistema permite seleccionar el modo de dificultad, inicia una partida con una palabra tomada del banco correspondiente, recibe letras desde la aplicación de PC por UART, valida cada letra como correcta, incorrecta o repetida, actualiza en tiempo real el LCD y los displays de siete segmentos, controla el conteo de intentos fallidos y el tiempo restante, determina victoria o derrota, y regresa automáticamente a la pantalla de selección de modo al finalizar. A nivel de jugabilidad, el sistema cumple con lo solicitado en el enunciado.
 
Dentro de las decisiones de diseño que se apartan del planteamiento inicial (`docs/diseño/diseño.md`) y que deben quedar documentadas como tales, en lugar de considerarse errores, están las siguientes:
 
- **Selección de modo simplificada.** El planteamiento original proponía un botón `BTN_SEL` para alternar cíclicamente entre `FACIL` y `DIFICIL`, confirmado con un botón `BTN_OK` independiente. La implementación final simplifica esta interacción utilizando `btnU` para iniciar directamente en modo fácil y `btnD` para iniciar directamente en modo difícil, detectados por flanco de subida dentro de `game_core`. Esta simplificación reduce la cantidad de pasos que debe realizar el jugador sin afectar la funcionalidad exigida.
- **Antirrebote de botones integrado en `game_core`.** En `hangman_top`, los pulsadores `btnC`, `btnU` y `btnD` se conectan directamente al módulo de control (como `rst`, `btn_easy` y `btn_hard`) sin pasar por un módulo dedicado de sincronización/antirrebote. Dentro de `game_core`, las señales `btn_easy_d`/`btn_hard_d` (un registro de un ciclo de retardo) se utilizan únicamente para detectar el flanco de subida de cada botón y generar un pulso de un solo ciclo; esto evita que una pulsación sostenida se interprete como múltiples eventos, pero no constituye un filtro antirrebote temporizado (de varios milisegundos) como el implementado en el Proyecto 1. En la práctica, el rebote mecánico no generó fallas perceptibles durante las pruebas, pero se documenta como una limitación de robustez del diseño.
- **LFSR interno, no modular.** El generador pseudoaleatorio no se implementó como un módulo independiente, según sugería el diagrama de tercer nivel del planteamiento, sino como un registro de 8 bits interno a `game_core`, con semilla fija (`8'h1`) cargada en cada reset. Esto significa que, tras cada reset general, la secuencia de palabras generada es siempre la misma para una misma serie de pulsaciones, aunque durante una sesión de juego continua el valor del LFSR sigue evolucionando de forma pseudoaleatoria en cada ciclo en que el sistema permanece en `MENU`.
- **Cobertura de longitudes del banco de palabras.** El banco de palabras cubre longitudes de 4 a 11 caracteres (no hasta 12), lo cual cumple igualmente el rango de 4 a 12 exigido por el enunciado, aunque no lo agota en su extremo superior.
Como limitaciones y oportunidades de mejora identificadas al cierre del proyecto se señalan:
 
- **Retroalimentación del LED de estado.** Los cuatro LED (`led[0]`–`led[3]`) indican correctamente en qué etapa se encuentra el sistema (menú, partida, resultado, dificultad), pero el esquema es mínimo y podría enriquecerse, por ejemplo, con patrones de parpadeo que refuercen visualmente el resultado de la partida.
- **Banco de palabras fijo.** Las 50 palabras están fijas en tiempo de síntesis dentro de `word_bank`; ampliar o modificar el vocabulario requiere resintetizar el diseño. Se identifica como mejora futura el uso de una memoria inicializable o cargable en tiempo de ejecución.
- **Optimización general del diseño.** Tanto en área/recursos como en la propia lógica de `game_core`, existe margen para optimizar el diseño (por ejemplo, separar con mayor claridad control y datapath, o modularizar el generador LFSR y el antirrebote de botones como bloques independientes, tal como se planteó originalmente).
- **Retroalimentación sonora poco diferenciada.** El buzzer no distingue con patrones claramente diferentes entre acierto, error, victoria y derrota, lo que limita la información que el jugador recibe únicamente por audio.
Estas limitaciones no impidieron demostrar el funcionamiento completo del juego y se retoman como mejoras futuras en la sección de conclusiones.
---

## 2. Objetivos

### 2.1 Objetivo general

Diseñar e implementar un juego electrónico de Ahorcado en el cual una FPGA Basys 3 concentre la selección de la palabra secreta, la validación de letras, el control del tiempo y de los intentos, y la comunicación bidireccional con una aplicación de computadora personal desarrollada en Python, que actúa como terminal remota del jugador mediante un enlace serial UART.

### 2.2 Objetivos específicos

- Diseñar un banco de al menos 50 palabras de longitud variable (4–12 caracteres), almacenado como memoria de solo lectura sintetizable dentro de la FPGA (`word_bank`).
- Implementar un generador pseudoaleatorio tipo LFSR para seleccionar la palabra secreta según el modo de dificultad elegido.
- Diseñar la máquina de estados y el *datapath* de control del juego (`game_core`), incluyendo la validación de letras correctas, incorrectas y repetidas, el conteo de intentos fallidos y el control del tiempo restante.
- Diseñar el periférico LCD para el módulo PmodCLP (HD44780), con interfaz estándar de registros de 32 bits (`lcd_peripheral`), y la lógica que decide el contenido a mostrar en cada pantalla del juego (`lcd_screen_controller`).
- Diseñar el periférico UART (`uart_peripheral`) y un protocolo de aplicación propio sobre UART (`uart_game_interface`) que notifique a la PC el inicio de partida, el resultado de cada letra y el resultado final.
- Implementar la aplicación de PC en Python (`juego_uart.py`) como interfaz de entrada/salida remota del jugador, sin lógica de control del juego.
- Implementar los indicadores locales de salida: displays de siete segmentos multiplexados (tiempo restante y contador de victorias), LED de estado y buzzer (`io_controller`).
- Verificar el sistema mediante testbenches autoverificables, tanto a nivel de módulo como de integración.
- Realizar simulación post-implementación temporizada del sistema completo.
- Comparar los resultados teóricos, simulados y experimentales obtenidos.

---

## 3. Especificaciones

### 3.1 Requisitos funcionales

| Requisito | Valor especificado | Implementación final |
|---|---:|---|
| Tamaño del banco de palabras | ≥ 50 palabras | 50 palabras, `word_bank` (índices 0–49) |
| Longitud de palabra | 4–12 caracteres | 4 a 11 caracteres según tabla `LENGTHS` de `word_bank` |
| Alfabeto permitido | A–Z sin tildes ni Ñ | Palabras almacenadas en mayúsculas A–Z, rellenadas con espacios a 12 caracteres |
| Selección de palabra | Pseudoaleatoria mediante LFSR | LFSR de 8 bits interno a `game_core`, semilla fija `8'h1` tras reset |
| Rango de índices modo fácil | Cualquier palabra ≥ 4 letras | `easy_index = lfsr % 50` (todo el banco, índices 0–49) |
| Rango de índices modo difícil | Solo palabras de 6+ letras | `hard_index = 20 + (lfsr % 30)` (índices 20–49, longitud 6–11) |
| No repetición inmediata | — | Si el índice candidato coincide con `last_index`, se incrementa en 1 (con retorno cíclico dentro del rango del modo) |
| Intentos fallidos máximos | 6 | Partida termina al alcanzar `wrong_count == 6` |
| Tiempo modo fácil | sugerido 60 s | `EASY_TIME = 60` s (parámetro de `game_core`) |
| Tiempo modo difícil | sugerido 45 s | `HARD_TIME = 45` s (parámetro de `game_core`) |
| Tiempo de resultado final | ≥ 3 s | `RESULT_TIME = 3` s antes de regresar a `MENU` |
| Letra repetida | Ignorar sin penalizar | Detectada mediante `used_letters`; no decrementa intentos ni reinicia tiempo |
| Contador de victorias | 00–99 | Saturado con reinicio a 0 al superar 99 (`victories == 99 ? 0 : victories+1`) |
| Baudios UART | 115200 | `BAUD_RATE = 115200` en `uart_peripheral`/`uart_game_interface` |
| Reloj de la FPGA | 100 MHz | `CLK100MHZ`, único reloj de entrada del sistema |
| Displays de 7 segmentos | ≥ 4 dígitos | 4 dígitos multiplexados en `io_controller` (`seg`, `an`, `dp`) — [verificar asignación exacta 2+2] |
| LED de estado | mínimo 1 LED, estados distinguibles | 4 LED: `led[0]` menú, `led[1]` partida, `led[2]` resultado, `led[3]` modo difícil |
| Buzzer | 3 patrones distintos | Generado en `io_controller` a partir de `letter_correct`, `letter_wrong`, `result_active`/`result_win` — [verificar patrones exactos] |
| Botón de reinicio general | Botón central | `btnC`, conectado como `rst` a todos los módulos de `hangman_top` |
| Selección de modo | Botones dedicados | `btnU` = fácil (`btn_easy`), `btnD` = difícil (`btn_hard`), detectados por flanco de subida dentro de `game_core` |
| Comunicación requerida | UART asíncrono | Enlace bidireccional `RsRx`/`RsTx` mediante `uart_peripheral`, encapsulado por `uart_game_interface` |

### 3.2 Protocolo de aplicación sobre UART

La comunicación entre la FPGA y la aplicación ejecutada en la computadora se realiza mediante una interfaz UART configurada a **115200 baudios, 8 bits de datos, sin bit de paridad y un bit de parada (8N1)**. Sobre esta comunicación física se implementó un protocolo de aplicación que permite enviar las letras ingresadas por el usuario hacia la FPGA y transmitir desde la FPGA la información correspondiente al estado y resultado de la partida.

La comunicación es bidireccional. En la dirección **PC → FPGA**, se transmite directamente el carácter ASCII correspondiente a la letra seleccionada por el usuario. En la dirección **FPGA → PC**, se utilizan paquetes estructurados que comienzan con el byte de encabezado `0xA5`, seguido por un byte que identifica el tipo de mensaje y los campos correspondientes.

#### Trama física UART

Cada byte se transmite utilizando el formato **8N1**, por lo que una trama UART está compuesta por un bit de inicio (`START`), ocho bits de datos y un bit de parada (`STOP`). Los bits de datos se transmiten comenzando por el bit menos significativo (**LSB first**).

```text
         START          8 bits de datos                STOP
           │                    │                        │
           ▼                    ▼                        ▼
Reposo ─── 0 ─── D0 ─ D1 ─ D2 ─ D3 ─ D4 ─ D5 ─ D6 ─ D7 ─── 1 ─── Reposo
                  └────────── LSB → MSB ──────────┘
```

Para una velocidad de transmisión de 115200 baudios, la duración aproximada de cada bit se obtiene mediante:

$$
T_{bit}=\frac{1}{115200}
$$

por lo tanto:

$$
T_{bit}\approx 8.68\mu s
$$

Como cada trama contiene diez bits en total —un bit de inicio, ocho bits de datos y un bit de parada—, el tiempo aproximado requerido para transmitir un byte es:

$$
T_{byte}=10(8.68\mu s)\approx86.8\mu s
$$

La FPGA utiliza un reloj principal de 100 MHz, correspondiente a un período de 10 ns. Por esta razón, el número aproximado de ciclos de reloj disponibles durante la transmisión de cada bit UART es:

$$
N_{ciclos/bit}=
\frac{100\,000\,000}{115200}
\approx868
$$

Este valor es utilizado por el periférico UART para establecer la temporización necesaria durante los procesos de transmisión y recepción.

#### Mensajes PC → FPGA

En la dirección **PC → FPGA**, la computadora transmite un único byte ASCII correspondiente a la letra introducida por el usuario. Los caracteres válidos se encuentran dentro del intervalo ASCII comprendido entre `A` y `Z`, es decir:

$$
'A'=0x41
$$

hasta:

$$
'Z'=0x5A
$$

Algunos ejemplos de los valores transmitidos se muestran en la siguiente tabla:

| Entrada del usuario | Byte ASCII transmitido |
|---|---|
| `A` | `0x41` |
| `B` | `0x42` |
| `C` | `0x43` |
| `Z` | `0x5A` |

La aplicación de PC convierte la entrada del usuario a mayúscula antes de realizar la transmisión. Adicionalmente, la lógica implementada en la FPGA verifica que el byte recibido corresponda a una letra comprendida entre `A` y `Z`. Cualquier byte que se encuentre fuera de este intervalo se descarta sin modificar el estado de la partida.

El proceso de recepción puede representarse de forma general de la siguiente manera:

```text
Usuario introduce una letra
          │
          ▼
Aplicación de PC
          │
Conversión a mayúscula
          │
          ▼
   Byte ASCII A-Z
          │
          ▼
        UART
          │
          ▼
         FPGA
          │
          ▼
Validación del rango A-Z
          │
          ▼
     Lógica del juego
```

#### Mensajes FPGA → PC

Para la comunicación en dirección **FPGA → PC** se definió un protocolo basado en paquetes de longitud conocida. Todos los paquetes comienzan con el byte `0xA5`, utilizado como encabezado o byte de sincronización.

El segundo byte del paquete identifica el tipo de mensaje transmitido:

| Tipo de mensaje | Código | Función |
|---|---|---|
| Inicio de partida | `0x01` | Informa el inicio de una nueva partida |
| Resultado de letra | `0x02` | Informa el resultado de una letra procesada |
| Resultado final | `0x03` | Informa la finalización de la partida |

De esta manera, la aplicación de PC busca inicialmente el encabezado `0xA5` y posteriormente analiza el segundo byte para determinar la estructura y longitud del resto del paquete.

##### Paquete de inicio de partida

Cuando se inicia una nueva partida, la FPGA transmite el siguiente paquete:

```text
A5 01 MODO LONGITUD
```

La estructura byte a byte se muestra en la siguiente tabla:

| Byte | Campo | Significado |
|---:|---|---|
| 0 | `0xA5` | Encabezado del protocolo |
| 1 | `0x01` | Tipo de mensaje: inicio de partida |
| 2 | `MODO` | Modo de dificultad seleccionado |
| 3 | `LONGITUD` | Cantidad de caracteres de la palabra seleccionada |

**Longitud total del paquete: 4 bytes.**

El campo `MODO` permite indicar a la aplicación de PC la dificultad seleccionada para la nueva partida, mientras que el campo `LONGITUD` contiene la cantidad de caracteres de la palabra seleccionada por la FPGA.

##### Paquete de resultado de una letra

Cada vez que una letra válida es procesada por la lógica del juego, la FPGA transmite un paquete con la siguiente estructura:

```text
A5 02 LETRA RESULTADO INTENTOS LONGITUD PATRON[12]
```

La distribución de los bytes es:

| Byte | Campo | Significado |
|---:|---|---|
| 0 | `0xA5` | Encabezado del protocolo |
| 1 | `0x02` | Tipo de mensaje: resultado de una letra |
| 2 | `LETRA` | Código ASCII de la letra procesada |
| 3 | `RESULTADO` | Resultado de la validación de la letra |
| 4 | `INTENTOS` | Cantidad de intentos restantes |
| 5 | `LONGITUD` | Longitud de la palabra seleccionada |
| 6–17 | `PATRON[12]` | Estado actualizado de la palabra |

**Longitud total del paquete: 18 bytes.**

El campo `RESULTADO` utiliza los siguientes códigos:

| Código | Significado |
|---|---|
| `0x01` | Letra correcta |
| `0x02` | Letra incorrecta |
| `0x03` | Letra repetida |

El campo `PATRON[12]` contiene la representación actual de la palabra. Las posiciones que ya fueron descubiertas contienen las letras correspondientes, mientras que las posiciones todavía ocultas se representan mediante el carácter utilizado por la implementación para indicar una letra no revelada.

Por ejemplo, para una palabra como `CASA`, después de procesar correctamente la letra `A`, el patrón representaría:

```text
Palabra:    C A S A
Patrón:     _ A _ A
```

De esta manera, la aplicación de PC puede mostrar el progreso de la partida utilizando directamente la información proporcionada por la FPGA, sin implementar localmente la lógica de validación del juego.

##### Paquete de resultado final

Cuando la partida finaliza, la FPGA transmite el siguiente paquete:

```text
A5 03 GANO CAUSA LONGITUD PALABRA[12]
```

La distribución byte a byte es:

| Byte | Campo | Significado |
|---:|---|---|
| 0 | `0xA5` | Encabezado del protocolo |
| 1 | `0x03` | Tipo de mensaje: resultado final |
| 2 | `GANO` | Indica el resultado de la partida |
| 3 | `CAUSA` | Indica la causa de finalización |
| 4 | `LONGITUD` | Longitud de la palabra |
| 5–16 | `PALABRA[12]` | Palabra completa seleccionada |

**Longitud total del paquete: 17 bytes.**

El campo `CAUSA` permite identificar la condición que produjo la finalización de la partida:

| Código | Significado |
|---|---|
| `0x01` | Victoria |
| `0x02` | Derrota por agotar los seis intentos |
| `0x03` | Derrota por agotamiento del tiempo |

El campo `PALABRA[12]` contiene la palabra completa seleccionada para la partida. Esto permite que la aplicación de PC muestre la solución al finalizar el juego, tanto en caso de victoria como de derrota.

#### Resumen del protocolo de aplicación

La siguiente tabla resume los mensajes utilizados en la comunicación entre la computadora y la FPGA:

| Dirección | Mensaje | Estructura | Longitud |
|---|---|---|---:|
| PC → FPGA | Letra | `LETRA` | 1 byte |
| FPGA → PC | Inicio de partida | `A5 01 MODO LONGITUD` | 4 bytes |
| FPGA → PC | Resultado de letra | `A5 02 LETRA RESULTADO INTENTOS LONGITUD PATRON[12]` | 18 bytes |
| FPGA → PC | Resultado final | `A5 03 GANO CAUSA LONGITUD PALABRA[12]` | 17 bytes |

La estructura propuesta mantiene toda la lógica de control de la partida dentro de la FPGA. La aplicación de PC se limita a transmitir las letras introducidas por el usuario e interpretar los paquetes enviados por la FPGA para presentar el estado de la partida.

### 3.3 Interfaz estándar de periféricos (bus de 32 bits)

Para facilitar la integración entre los diferentes módulos del sistema, los periféricos UART y LCD utilizan una interfaz digital común de **32 bits**. Esta interfaz permite realizar operaciones de lectura y escritura sobre los registros internos de cada periférico mediante un esquema de direccionamiento sencillo.

La interfaz está compuesta por las siguientes señales:

| Señal | Dirección | Ancho | Descripción |
|---|---|---:|---|
| `clk_i` | Entrada | 1 bit | Reloj principal utilizado para sincronizar las operaciones del periférico |
| `rst_i` | Entrada | 1 bit | Señal de reinicio del periférico |
| `write_enable_i` | Entrada | 1 bit | Habilita una operación de escritura cuando se encuentra en `1` |
| `addr_i` | Entrada | 2 bits | Selecciona uno de los registros internos del periférico |
| `wdata_i` | Entrada | 32 bits | Contiene el dato que se desea escribir en el registro seleccionado |
| `rdata_o` | Salida | 32 bits | Contiene el dato leído desde el registro seleccionado |

El campo de dirección `addr_i[1:0]` permite seleccionar hasta cuatro registros diferentes:

| `addr_i[1:0]` | Registro seleccionable |
|---|---|
| `2'b00` | Registro 0 |
| `2'b01` | Registro 1 |
| `2'b10` | Registro 2 |
| `2'b11` | Registro 3 |

El funcionamiento general de la interfaz depende del valor de `write_enable_i`.

Cuando:

```text
write_enable_i = 1
```

se realiza una operación de **escritura**, por lo que el periférico utiliza `addr_i` para seleccionar el registro que será modificado y toma la información presente en `wdata_i[31:0]`.

De forma general:

```text
                 addr_i[1:0]
                      │
                      ▼
                ┌───────────┐
wdata_i[31:0] ─►│ Periférico│
                │           │
write_enable=1 ─►│ Registros │
                └───────────┘
```

Cuando:

```text
write_enable_i = 0
```

la operación corresponde a una **lectura**. En este caso, `addr_i` selecciona el registro interno cuyo contenido se coloca en `rdata_o[31:0]`.

```text
                 addr_i[1:0]
                      │
                      ▼
                ┌───────────┐
                │ Periférico│
                │           │────► rdata_o[31:0]
write_enable=0 ─►│ Registros │
                └───────────┘
```

El uso de una interfaz común permite que los módulos encargados de controlar el UART y el LCD accedan a sus respectivos periféricos de una manera uniforme. Aunque los registros internos y la función de cada periférico son diferentes, el mecanismo utilizado para leerlos y escribirlos se mantiene igual.

---

### 3.4 Registros del periférico UART

El periférico UART utiliza tres direcciones de la interfaz estándar para almacenar los datos de transmisión, los datos recibidos y la información de control y estado.

El mapa de registros utilizado se muestra en la siguiente tabla:

| `addr_i[1:0]` | Registro | Función |
|---|---|---|
| `2'b00` | `DATA_TX` | Almacena el byte que será transmitido por UART |
| `2'b01` | `DATA_RX` | Almacena el último byte recibido por UART |
| `2'b10` | `CONTROL/STATUS` | Controla la transmisión e informa el estado de recepción |
| `2'b11` | Reservado | No utilizado |

#### Registro `DATA_TX`

El registro `DATA_TX`, ubicado en la dirección:

```text
addr_i = 2'b00
```

se utiliza para almacenar el dato que será transmitido hacia la computadora.

Aunque la interfaz de periféricos posee un ancho de 32 bits, el protocolo UART transmite datos de 8 bits. Por esta razón, solamente los bits `[7:0]` contienen información útil.

| Bits | Campo | Descripción |
|---|---|---|
| `[7:0]` | `DATA_TX` | Byte que será transmitido |
| `[31:8]` | Reservado | No utilizado para el dato UART |

El proceso general de transmisión es:

```text
wdata_i[7:0]
      │
      ▼
   DATA_TX
      │
      ▼
Transmisor UART
      │
      ▼
    uart_tx
      │
      ▼
      PC
```

Primero se escribe el byte que se desea transmitir en `DATA_TX`. Posteriormente, mediante el registro `CONTROL/STATUS`, se solicita al periférico que inicie la transmisión.

#### Registro `DATA_RX`

El registro `DATA_RX`, ubicado en:

```text
addr_i = 2'b01
```

almacena el último byte recibido desde la computadora.

| Bits | Campo | Descripción |
|---|---|---|
| `[7:0]` | `DATA_RX` | Byte recibido mediante UART |
| `[31:8]` | Reservado | Sin información del dato recibido |

El flujo general de recepción es:

```text
      PC
      │
      ▼
   uart_rx
      │
      ▼
Receptor UART
      │
      ▼
   DATA_RX
      │
      ▼
uart_game_interface
      │
      ▼
 Lógica del juego
```

Cuando el receptor completa correctamente la recepción de un byte, este se almacena en `DATA_RX` y se genera la indicación correspondiente de que existe un nuevo dato disponible.

#### Registro `CONTROL/STATUS`

El registro `CONTROL/STATUS`, ubicado en:

```text
addr_i = 2'b10
```

contiene las señales necesarias para iniciar una transmisión y determinar si existe un nuevo dato recibido.

Los campos principales utilizados son:

| Bit | Campo | Función |
|---:|---|---|
| 0 | `send` / estado de transmisión | Permite iniciar o indicar el estado de una transferencia UART |
| 1 | `new_rx` | Indica que se ha recibido un nuevo byte |
| `[31:2]` | Reservados | Sin uso para las funciones principales |

El campo `send` se relaciona con el proceso de transmisión. Una vez almacenado el byte correspondiente en `DATA_TX`, este campo permite solicitar el inicio de la transferencia.

Durante la transmisión, el periférico mantiene internamente el estado necesario para evitar iniciar una nueva transferencia antes de finalizar la actual.

Por otra parte, `new_rx` indica que el receptor UART ha completado la recepción de un nuevo byte y que este se encuentra disponible en `DATA_RX`.

El controlador que utiliza el periférico debe leer el dato recibido y posteriormente limpiar la indicación `new_rx`, permitiendo identificar correctamente la llegada del siguiente byte.

El procedimiento de recepción puede resumirse como:

```text
Byte recibido
     │
     ▼
 DATA_RX ← byte
     │
     ▼
 new_rx = 1
     │
     ▼
Controlador detecta new_rx
     │
     ▼
Lee DATA_RX
     │
     ▼
Limpia new_rx
```

De esta forma, los registros `DATA_TX`, `DATA_RX` y `CONTROL/STATUS` permiten separar la transferencia física de los datos de la lógica encargada de interpretar el protocolo del juego.

---

### 3.5 Registros del periférico LCD

El periférico LCD también utiliza la interfaz estándar de 32 bits. Para su operación se definieron dos registros principales: `CONTROL/STATUS` y `DATA`.

El mapa de registros es:

| `addr_i[1:0]` | Registro | Función |
|---|---|---|
| `2'b00` | `CONTROL/STATUS` | Control y estado del periférico LCD |
| `2'b01` | `DATA` | Dato o comando que será enviado al LCD |
| `2'b10` | Reservado | No utilizado |
| `2'b11` | Reservado | No utilizado |

#### Registro `CONTROL/STATUS`

El registro `CONTROL/STATUS` permite iniciar operaciones sobre el LCD, seleccionar si la información enviada corresponde a un comando o a un carácter, solicitar operaciones especiales y conocer el estado actual del periférico.

Los campos utilizados son:

| Bit | Campo | Tipo | Función |
|---:|---|---|---|
| 0 | `start` | Control | Inicia una operación con el LCD |
| 1 | `rs` | Control | Selecciona entre comando (`0`) y dato (`1`) |
| 2 | `clear` | Control | Solicita limpiar la pantalla |
| 3 | `home` | Control | Solicita regresar el cursor a la posición inicial |
| 8 | `busy` | Estado | Indica que el periférico se encuentra ocupado |
| 9 | `done` | Estado | Indica la finalización de una operación |
| `[31:10]` | Reservado | — | Sin uso |
| `[7:4]` | Reservado | — | Sin uso |

##### Campo `start`

El bit `start` solicita al periférico iniciar una nueva operación utilizando la información previamente almacenada en el registro `DATA` y la configuración del campo `rs`.

Una vez aceptada la solicitud, el periférico realiza internamente la secuencia temporal requerida por el controlador del LCD.

##### Campo `rs`

El campo `rs` determina la interpretación del byte almacenado en `DATA`:

```text
rs = 0 → comando
rs = 1 → carácter/dato
```

Por ejemplo, un valor como `0x01` con `rs = 0` corresponde a una instrucción para el LCD, mientras que un código ASCII como `0x41` con `rs = 1` corresponde al carácter `A`.

##### Campo `clear`

El campo `clear` solicita una operación de limpieza de pantalla. Esta operación corresponde al comando:

```text
0x01
```

del controlador compatible con HD44780.

##### Campo `home`

El campo `home` solicita regresar el cursor a su posición inicial sin utilizarlo como una escritura normal de carácter.

##### Campo `busy`

El bit `busy` indica que el periférico se encuentra realizando una operación.

```text
busy = 0 → periférico disponible
busy = 1 → periférico ocupado
```

Mientras `busy` se encuentra activo, el controlador debe esperar antes de solicitar una nueva operación.

##### Campo `done`

El campo `done` permite indicar que la última operación aceptada por el periférico ha finalizado.

De forma simplificada:

```text
Solicitud
   │
   ▼
start = 1
   │
   ▼
busy = 1
   │
   ▼
Operación LCD
   │
   ▼
busy = 0
done = 1
```

#### Registro `DATA`

El registro `DATA`, ubicado en:

```text
addr_i = 2'b01
```

almacena el byte que será enviado al LCD.

| Bits | Campo | Descripción |
|---|---|---|
| `[7:0]` | `data` | Código ASCII o instrucción del LCD |
| `[31:8]` | Reservado | Sin uso |

El significado de los bits `[7:0]` depende del valor de `rs`.

Por ejemplo:

```text
DATA = 0x41
RS   = 1
```

representa el carácter:

```text
'A'
```

mientras que:

```text
DATA = 0x01
RS   = 0
```

representa el comando para limpiar la pantalla.

El flujo general de una escritura puede representarse como:

```text
        DATA[7:0]
            │
            ▼
     lcd_peripheral
            │
       ┌────┴────┐
       │         │
      RS       DATA[7:0]
       │         │
       └────┬────┘
            ▼
        PmodCLP
```

#### Secuencia de inicialización

Antes de utilizar normalmente la pantalla, el periférico ejecuta una secuencia de inicialización para configurar el controlador LCD.

Los comandos principales utilizados son:

| Comando | Función |
|---|---|
| `0x38` | Configura interfaz de 8 bits y operación con dos líneas |
| `0x0C` | Enciende el display |
| `0x01` | Limpia el contenido de la pantalla |
| `0x06` | Configura el incremento automático del cursor |

La secuencia puede resumirse como:

```text
Encendido
   │
   ▼
  0x38
   │
   ▼
  0x0C
   │
   ▼
  0x01
   │
   ▼
  0x06
   │
   ▼
LCD preparado
```

El periférico también incorpora los tiempos de espera necesarios entre operaciones, debido a que el controlador del LCD no procesa las instrucciones de forma instantánea. La señal `busy` permite que el controlador de pantalla conozca cuándo puede solicitar una nueva operación.

---

### 3.6 Requisitos eléctricos

El sistema se implementa sobre una tarjeta **Basys 3**, utilizando el reloj principal de 100 MHz y los diferentes pines de entrada y salida requeridos por los periféricos del proyecto.

Las señales digitales externas utilizadas por el diseño se configuran con el estándar lógico:

```text
LVCMOS33
```

correspondiente a niveles lógicos de **3.3 V**.

La asignación entre las señales descritas en SystemVerilog y los pines físicos de la FPGA se realiza mediante el archivo de restricciones del proyecto (`.xdc`).

Entre las principales conexiones físicas utilizadas se encuentran:

- reloj principal de 100 MHz;
- señales UART `RsRx` y `RsTx`;
- pulsadores de selección, confirmación y reinicio;
- señales del LCD;
- displays de siete segmentos;
- LEDs de estado;
- salida correspondiente al buzzer.

#### Conexión del LCD

El PmodCLP utiliza una interfaz paralela de 8 bits. Las principales señales de control utilizadas por el diseño son:

| Señal | Función |
|---|---|
| `lcd_data[7:0]` | Bus paralelo de datos/comandos |
| `lcd_rs` | Selección entre comando y dato |
| `lcd_rw` | Selección de lectura/escritura |
| `lcd_e` | Señal de habilitación del LCD |

En la implementación desarrollada, la comunicación con el LCD se utiliza principalmente para realizar operaciones de escritura, por lo que el periférico controla las señales necesarias para enviar comandos y caracteres respetando las temporizaciones correspondientes.

#### Pulsadores

Los pulsadores de la Basys 3 se utilizan como entradas digitales para realizar las funciones de:

- selección del modo de dificultad;
- confirmación de la selección;
- reinicio general del sistema.

Debido a que los pulsadores son dispositivos mecánicos, una única pulsación puede producir múltiples transiciones eléctricas durante un intervalo corto. Por esta razón, las señales asociadas a los botones deben acondicionarse antes de ser utilizadas por la lógica secuencial del sistema.

El acondicionamiento permite obtener una señal estable que pueda ser interpretada correctamente por las máquinas de estados y registros del diseño.

#### UART

La comunicación UART utiliza dos señales independientes:

```text
RsRx → recepción hacia la FPGA
RsTx → transmisión desde la FPGA
```

La comunicación es bidireccional, pero cada dirección posee su propia línea física. Al tratarse de UART, no se requiere una línea de reloj compartida entre la computadora y la FPGA; la sincronización se realiza mediante la configuración común de 115200 baudios y la estructura `START + DATA + STOP`.

En conjunto, las restricciones eléctricas y de pines permiten relacionar la descripción RTL del sistema con los recursos físicos disponibles en la tarjeta FPGA y los periféricos externos conectados.

## 4. Fundamentación teórica

### 4.1 Lógica combinacional y secuencial

La lógica combinacional describe salidas que dependen únicamente de los valores actuales de sus entradas, sin memoria del pasado; en `game_core` este tipo de lógica se utiliza, por ejemplo, en el cálculo de `match_mask` (posiciones de la palabra donde aparece la letra recibida), en `valid_mask` (máscara de bits válidos según la longitud de la palabra) y en la selección del índice candidato (`candidate_index`) según el modo y el último índice usado. Todos estos bloques se describen mediante `always_comb`, cuidando cubrir todos los caminos posibles para evitar la inferencia de *latches* no intencionados.
 
La lógica secuencial, en cambio, almacena información entre flancos de reloj mediante flip-flops. En `game_core` esto se traduce en registros como `state` (estado de la FSM), `selected_word`, `word_length`, `revealed_mask`, `used_letters`, `wrong_count`, `time_left`, `victories`, `lfsr` y `last_index`, todos actualizados de forma síncrona en `always_ff @(posedge clk)` mediante asignaciones no bloqueantes (`<=`), de modo que reflejan el nuevo estado del sistema en el siguiente flanco de reloj.

### 4.2 Máquinas de estados finitos

Una máquina de estados finitos (FSM) describe el comportamiento de un sistema secuencial como un conjunto finito de estados, con condiciones que determinan las transiciones entre ellos y salidas que pueden depender únicamente del estado actual (Moore) o también de las entradas presentes (Mealy). En `game_core` se implementa una FSM de tres estados, `typedef enum logic [1:0] {MENU, GAME, RESULT} state_t`, con las siguientes transiciones:
 
- **`MENU → GAME`**: ocurre cuando se detecta un pulso en `btn_easy` o `btn_hard` (`easy_pulse`/`hard_pulse`); en la misma transición se carga la palabra seleccionada, se reinician los contadores de la partida (`revealed_mask`, `used_letters`, `wrong_count`) y se carga el tiempo correspondiente al modo (`EASY_TIME` o `HARD_TIME`).
- **`GAME → RESULT`**: ocurre por tres condiciones mutuamente excluyentes: (a) todas las posiciones de la palabra quedan reveladas (`(revealed_mask | match_mask) == valid_mask`), lo que produce victoria y aumenta el contador de `victories`; (b) el conteo de letras incorrectas alcanza seis (`wrong_count == 5` antes de incrementar a 6), lo que produce derrota por intentos; o (c) el temporizador de la partida llega a cero (`time_left <= 1` al expirar el conteo de segundos), lo que produce derrota por tiempo.
- **`RESULT → MENU`**: ocurre automáticamente transcurrido el tiempo de resultado configurado (`RESULT_TIME = 3` s), contado con la misma base de un segundo (`sec_count == CLK_FREQ-1`) que se usa durante la partida.
Las señales combinacionales `menu_active`, `game_active` y `result_active` se derivan directamente del estado actual (`state == MENU`, etc.), por lo que corresponden a salidas de tipo Moore.

### 4.3 Registro de desplazamiento con retroalimentación lineal (LFSR)

Un registro de desplazamiento con retroalimentación lineal (LFSR) genera una secuencia pseudoaleatoria desplazando sus bits en cada ciclo de reloj e insertando en el bit menos significativo el resultado de una función XOR aplicada sobre un subconjunto fijo de bits internos (los llamados *taps*). En `game_core` se implementó un LFSR de configuración Fibonacci de 8 bits:
 
```systemverilog
lfsr <= { lfsr[6:0], lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3] };
```
 
Los *taps* utilizados (bits 7, 5, 4 y 3) corresponden al polinomio primitivo x⁸+x⁶+x⁵+x⁴+1, que produce una secuencia de longitud máxima de 255 estados (2⁸−1) para cualquier semilla distinta de cero. Precisamente por esto la semilla no puede ser `8'h0`: con esa semilla la retroalimentación XOR siempre produce cero y el registro queda permanentemente bloqueado en el estado absorbente `00000000`. En la implementación, el registro se inicializa con la semilla `8'h1` en cada reset, y avanza un paso en cada ciclo de reloj mientras el sistema permanece en el estado `MENU`, lo que en la práctica produce una posición diferente del LFSR en el instante exacto en que el jugador presiona `btnU` o `btnD`.
 
El valor del LFSR se mapea a un índice del banco de palabras mediante una operación de módulo, distinta según el modo:
 
- **Modo fácil**: `easy_index = lfsr % 50`, cubriendo la totalidad de las 50 palabras del banco.
- **Modo difícil**: `hard_index = 20 + (lfsr % 30)`, restringiendo la selección al subrango de índices 20 a 49, que corresponden en `word_bank` a las palabras de 6 o más caracteres.
Adicionalmente, si el índice candidato coincide con el índice de la última palabra utilizada (`last_index`), se incrementa en uno (con retorno cíclico dentro del rango del modo correspondiente), como estrategia simple para evitar repetir la misma palabra en dos partidas consecutivas.

### 4.4 Memorias de solo lectura (ROM) sintetizables

Una memoria de solo lectura (ROM) sintetizable puede describirse en SystemVerilog como un arreglo constante (`localparam`) indexado mediante una señal de entrada, resuelto en tiempo de síntesis mediante lógica combinacional o bloques de memoria de la FPGA, según el tamaño y las herramientas de síntesis. En este proyecto, `word_bank` implementa dos arreglos constantes paralelos e indexados de 0 a 49:
 
- `WORDS[0:49]`, de tipo `logic [95:0]`, donde cada palabra se almacena como una cadena de 12 caracteres ASCII (96 bits), rellenando con espacios los caracteres sobrantes cuando la palabra es más corta que 12 letras. Esto permite representar palabras de longitud variable con un ancho de bus fijo, sin necesidad de codificar la longitud dentro de la misma palabra.
- `LENGTHS[0:49]`, de tipo `logic [3:0]`, con la longitud real (sin el relleno de espacios) de cada palabra, usada por `game_core` para saber cuántas de las 12 posiciones son válidas (`valid_mask`) y para truncar la palabra al desplegarla.
El acceso se resuelve con un bloque combinacional (`always_comb`) que verifica que el índice sea menor que 50 antes de leer el arreglo, devolviendo la primera palabra del banco como valor por defecto en caso de un índice fuera de rango, lo cual evita la inferencia de un *latch* al cubrir explícitamente todos los caminos de la asignación.

### 4.5 Protocolo UART asíncrono

<!-- [INTEGRANTE 2] Estructura de trama (start, datos, stop), relación
entre reloj, baud rate y sobremuestreo, y consideraciones de validación
para recepción confiable. -->

### 4.6 Controlador LCD HD44780 / PmodCLP

<!-- [INTEGRANTE 2] Funcionamiento general del controlador HD44780,
interfaz paralela, secuencia de inicialización y temporización. -->

### 4.7 Metaestabilidad y sincronización de señales asíncronas

<!-- [INTEGRANTE 1 o 2] Aplicado a las entradas de botones y a la
recepción UART. -->

### 4.8 Antirrebote de pulsadores (debouncing)

El rebote mecánico ocurre porque, al presionar o soltar un pulsador físico, el contacto no cambia de estado de forma limpia, sino que oscila brevemente entre 0 y 1 durante algunos milisegundos antes de estabilizarse. Una técnica de antirrebote completa (como la usada en el Proyecto 1) muestrea la entrada periódicamente y solo acepta el nuevo valor cuando se ha mantenido estable durante una ventana de tiempo suficiente, generando además un pulso de un solo ciclo para cada pulsación válida.
 
En este proyecto, `btnC`, `btnU` y `btnD` se conectan directamente desde `hangman_top` hacia `game_core` como `rst`, `btn_easy` y `btn_hard`, respectivamente, sin pasar por un módulo antirrebote dedicado. Dentro de `game_core`, únicamente se implementa **detección de flanco de subida**: los registros `btn_easy_d` y `btn_hard_d` retrasan la señal un ciclo de reloj, y las señales combinacionales `easy_pulse = btn_easy & ~btn_easy_d` y `hard_pulse = btn_hard & ~btn_hard_d` generan un pulso de un ciclo en la transición de 0 a 1. Esto evita que una pulsación sostenida sea interpretada como múltiples eventos consecutivos mientras el botón permanece presionado, pero **no filtra el rebote mecánico real** de los primeros milisegundos de la pulsación: si el rebote ocurriera dentro de esa ventana, en principio podría generar más de un pulso espurio. En la práctica, esto no se observó como una falla evidente durante las pruebas físicas, pero se documenta como una simplificación respecto al antirrebote temporizado del Proyecto 1 (ver sección 1.3).

### 4.9 Multiplexación de displays de siete segmentos

<!-- [INTEGRANTE 2] Aplicado a los 4 dígitos (tiempo y victorias). -->

---

## 5. Metodología

### 5.1 Diseño modular

El proyecto se desarrolló siguiendo la metodología de diseño modular planteada en `docs/diseño/diseño.md`, dividiendo el sistema en niveles de abstracción sucesivos: un primer nivel que define las entradas y salidas externas del sistema completo (`hangman_top`), un segundo nivel que separa los bloques funcionales principales (gestión de entradas, comunicación con la PC, gestión de palabras, control del juego, visualización y alertas), y niveles posteriores que detallan internamente cada bloque hasta llegar a unidades describibles directamente en SystemVerilog. Dentro del bloque de control se mantuvo, en la medida de lo posible, una separación conceptual entre la máquina de estados (FSM) y el *datapath* (registros de la partida), de forma que la FSM decide "cuándo" ocurre cada transición y el *datapath* administra "qué" datos se actualizan en cada una.

### 5.2 Flujo de desarrollo

El desarrollo se realizó siguiendo, en términos generales, el orden planteado en el plan de implementación del diseño: primero los bloques de entrada (lectura de botones) y el núcleo de comunicación (`uart_peripheral`); luego el banco de palabras (`word_bank`) y el generador pseudoaleatorio LFSR; a continuación la máquina de estados y el *datapath* principal del juego (`game_core`); posteriormente el periférico y el controlador de pantallas del LCD (`lcd_peripheral`, `lcd_screen_controller`); después los indicadores locales (displays de siete segmentos, LED y buzzer) agrupados en `io_controller`; y finalmente la aplicación de PC en Python (`juego_uart.py`). Cada módulo se verificó de forma individual antes de integrarse en `hangman_top`, y la integración completa se validó tanto en simulación como en la tarjeta física.


### 5.3 Herramientas

<!-- [INTEGRANTE 1] Vivado (versión), simulador utilizado, lenguaje
(SystemVerilog), Python y librería `pyserial`, tarjeta Basys 3. -->

---

## 6. Arquitectura general

### 6.1 Jerarquía de módulos

El árbol de módulos real, tomado directamente del código fuente (`hangman_top.sv`), es el siguiente:
 
```text
hangman_top
  game_core
    word_bank
  uart_game_interface
    uart_peripheral
  lcd_screen_controller
  lcd_peripheral
  io_controller
```
 
A diferencia del árbol propuesto en el planteamiento del diseño, no existe un módulo `button_conditioner` independiente: los pulsadores `btnC`, `btnU` y `btnD` se conectan directamente desde `hangman_top` hacia `game_core`, que internamente realiza únicamente la detección de flanco descrita en la sección 4.8. De igual forma, `uart_peripheral` no es instanciado directamente por `hangman_top`, sino encapsulado dentro de `uart_game_interface`, que es el módulo que efectivamente se conecta al top-level.

### 6.2 Diagrama de bloques

<!-- [INTEGRANTE 1] Insertar y referenciar el diagrama de primer/segundo
nivel definido en docs/diseño/diseño.md. -->

![Diagrama general de bloques](Imagenes/diagrama_bloques.png)

**Figura 1.** Diagrama de bloques del sistema completo `hangman_top_completo`.

### 6.3 Flujo de una partida

<!-- [INTEGRANTE 1] Diagrama de flujo o descripción textual: selección de
modo → selección de palabra → recepción de letra → validación → repetición
→ fin de partida → regreso al menú. -->

1. El sistema inicia (o retorna tras un reset) en el estado `MENU`, mientras el LFSR interno de `game_core` avanza continuamente en cada ciclo de reloj.
2. El jugador presiona `btnU` (modo fácil) o `btnD` (modo difícil). Se detecta el flanco de subida correspondiente y se calcula el índice candidato de palabra (`easy_index` o `hard_index`), ajustado si coincide con la última palabra usada.
3. `word_bank` entrega la palabra y su longitud real; `game_core` las almacena en `selected_word`/`word_length`, reinicia `revealed_mask`, `used_letters` y `wrong_count`, carga el tiempo correspondiente al modo (`EASY_TIME` o `HARD_TIME`) y transita a `GAME`.
4. `lcd_screen_controller` actualiza el LCD para mostrar la palabra oculta y el número de intentos disponibles; `io_controller` inicia la cuenta regresiva en los displays de siete segmentos.
5. La PC transmite una letra por UART; `uart_game_interface` la recibe, la valida como carácter A–Z y la entrega a `game_core` mediante `letter`/`letter_valid`.
6. `game_core` compara la letra contra la palabra secreta:
   - Si ya fue usada antes, se marca como **repetida** y se ignora sin penalización.
   - Si coincide con una o más posiciones, se marca como **correcta**, se actualiza `revealed_mask` y, si la palabra queda completa, la partida pasa a **victoria**.
   - Si no coincide, se marca como **incorrecta**, se incrementa `wrong_count` y, si se alcanza el sexto error, la partida pasa a **derrota por intentos**.
   - Si el tiempo llega a cero antes de que ocurra cualquiera de los casos anteriores, la partida pasa a **derrota por tiempo**.
7. `uart_game_interface` notifica a la PC el resultado de la letra procesada (y, si aplica, el resultado final de la partida) mediante las tramas del protocolo definido en la sección 3.2.
8. Al finalizar la partida, el sistema permanece en `RESULT` durante `RESULT_TIME` (3 s) mostrando el resultado en el LCD y, si hubo victoria, incrementando el contador de `victories`; transcurrido ese tiempo, el sistema regresa automáticamente a `MENU`.

---

## 7. Subsistema FPGA

<!-- [INTEGRANTE 1 para game_core/word_bank; INTEGRANTE 2 para UART y LCD]
Un apartado por módulo, todos con el MISMO nivel de encabezado para las
subsecciones internas (####), para no repetir el error de estructura del
informe anterior. -->

### 7.1 `hangman_top_completo`

#### Entradas y salidas

<!-- Tabla de puertos del top-level. -->

#### Funcionamiento

<!-- Interconexión de todos los módulos, señales `selected_mode`,
`start_easy`, `start_hard`. -->

#### Relación con el sistema

<!-- Rol como integrador de todos los bloques. -->

### 7.2 `button_conditioner`

#### Entradas y salidas

#### Funcionamiento

<!-- Sincronización, antirrebote, generación de pulso único. -->

#### Relación con el sistema

### 7.3 `game_core`

#### Entradas y salidas

#### Registros principales

<!-- selected_word[95:0], word_length[3:0], revealed_mask[11:0],
used_letters[25:0], wrong_count[2:0], time_left[6:0], victories[6:0]. -->

#### Diagrama de estados

<!-- MENU -> GAME -> RESULT -> MENU. Insertar figura y describir
condiciones de transición: confirmación de modo, letra correcta/incorrecta/
repetida, sexto error, tiempo agotado, palabra completa, timeout de
resultado (3 s). -->

![Diagrama de estados de game_core](Imagenes/fsm_game_core.png)

**Figura 2.** Diagrama de estados de `game_core`.

#### Funcionamiento

#### Relación con el sistema

### 7.4 `word_bank`

#### Entradas y salidas

#### Funcionamiento

<!-- Banco de 50 palabras, selección por modo (fácil: cualquiera ≥4;
difícil: solo ≥6), uso del LFSR de 8 bits, estrategia para evitar repetir
la palabra inmediatamente anterior. -->

#### Relación con el sistema

### 7.5 `uart_peripheral`

#### Entradas y salidas

#### Mapa de registros

#### Funcionamiento

<!-- RX/TX, registros de desplazamiento internos, generación de baud rate
a 115200. -->

#### Relación con el sistema

### 7.6 `uart_game_interface`

#### Entradas y salidas

#### Diagrama de estados

<!-- IDLE, RX_READ, RX_CLEAR, TX_LOAD, TX_START, TX_WAIT. -->

#### Funcionamiento

<!-- Eventos pendientes: pending_start, pending_letter, pending_end. -->

#### Relación con el sistema

### 7.7 `lcd_peripheral`

#### Entradas y salidas

#### Mapa de registros

#### Diagrama de estados

<!-- POWER, IDLE, SETUP, ENABLE, WAIT. -->

#### Funcionamiento

#### Relación con el sistema

### 7.8 `lcd_screen_controller_completo`

#### Entradas y salidas

#### Funcionamiento

<!-- Pantallas: selección fácil/difícil, partida activa, victoria,
derrota+palabra completa. Uso de snapshots para evitar cambios de
contenido durante una actualización. -->

#### Relación con el sistema

### 7.9 `io_controller`

#### Entradas y salidas

#### Funcionamiento

<!-- Multiplexado de 4 displays (2 dígitos tiempo, 2 dígitos victorias),
frecuencia de refresco, segmentos/ánodos activos en bajo; LED0–LED3;
patrones del buzzer. -->

#### Relación con el sistema

---

## 8. Aplicación de PC en Python

<!-- [INTEGRANTE 2] -->

### 8.1 Arquitectura de la aplicación

<!-- Uso de pyserial, configuración del puerto, hilo principal de entrada
del usuario, hilo receptor de mensajes de la FPGA. -->

### 8.2 Validación de entrada

<!-- Validación de una sola letra A–Z antes de transmitir. -->

### 8.3 Interpretación de paquetes

<!-- Búsqueda del encabezado 0xA5 e interpretación de los tres tipos de
paquete (inicio, resultado de letra, resultado final). -->

### 8.4 Manejo de errores

<!-- Entradas inválidas, pérdida de conexión, cierre del puerto. -->

### 8.5 Instrucciones de ejecución

<!-- Cómo instalar dependencias y ejecutar la aplicación. -->

---

## 9. Asignación de pines

<!-- [INTEGRANTE 1] Tabla de constraints (.xdc) de la Basys 3: reloj,
botones, UART, LCD (PmodCLP), displays, LED, buzzer. -->

---

## 10. Presentación de resultados

<!--
Peso 30% de la rúbrica — la sección más pesada del informe. Debe ser
EXPLÍCITA, autocontenida y solo describir/mostrar evidencia (sin análisis
crítico todavía; eso va en la sección 11). Con base en la retroalimentación
recibida en el Proyecto 1, esta sección DEBE incluir como mínimo:
  (a) evidencias de simulación (formas de onda, consola de testbench),
  (b) evidencia física funcional (capturas/fotos de LCD, displays, LED),
  (c) al menos una fotografía del sistema completo montado en la Basys 3,
  (d) el reporte de utilización de recursos de la FPGA (LUT, FF, slices,
      BRAM, DSP, pines de E/S) y el análisis de timing (WNS, TNS, hold slack).
No basta con mencionar que "la síntesis fue exitosa": los valores deben
copiarse literalmente del reporte de Vivado.
-->

### 10.1 Verificación por simulación

<!-- [INTEGRANTE 3] -->

#### Testbenches unitarios

<!-- Tabla o lista: tb_game_core, tb_uart_peripheral, tb_game_uart,
tb_lcd_peripheral, tb_lcd_screen_controller, tb_io_controller,
tb_hangman_timing, tb_hangman_completo. Para cada uno: qué verifica y
resultado (PASS/FAIL). -->

| Testbench | Qué verifica | Resultado |
|---|---|---|
| `tb_game_core` | FSM, letras, errores, victoria, tiempo | |
| `tb_uart_peripheral` | Registros, RX, TX | |
| `tb_game_uart` | Integración del juego con UART | |
| `tb_lcd_peripheral` | Comandos, datos, busy, done | |
| `tb_lcd_screen_controller` | Pantallas del LCD | |
| `tb_io_controller` | Siete segmentos y buzzer | |
| `tb_hangman_timing` | Prueba temporizada del top anterior | |
| `tb_hangman_completo` | Prueba integrada del top final | |

#### Resultado del testbench integrado

<!-- Insertar captura de consola con el resultado final, por ejemplo: -->

```text
TESTBENCH COMPLETO: PASS (753 comprobaciones)
```

![Consola del testbench integrado](Imagenes/consola_testbench_completo.png)

**Figura 3.** Resultado del testbench integrado `tb_hangman_completo`.

#### Formas de onda relevantes

<!-- Insertar y numerar las formas de onda de: reset, selección de modo,
confirmación BTN_OK, antirrebote, paquete UART de inicio, carácter
inválido, letra correcta, letra repetida sin consumir intento, victoria,
incremento de victorias, seis letras incorrectas, derrota por intentos,
derrota por tiempo, paquetes UART de letra y resultado. -->

![Simulación de game_core](Imagenes/tb_game_core.png)

**Figura 4.** Forma de onda de `tb_game_core` mostrando una partida completa.

#### Tabla de casos de prueba

| Caso de prueba | Estímulo | Resultado esperado | Resultado obtenido |
|---|---|---|---|
| Reset general | `BTN_RST` | Estado `MENU` | |
| Selección fácil/difícil | `BTN_SEL` | Alterna `selected_mode` | |
| Confirmación | `BTN_OK` | Inicio de partida | |
| Letra correcta | ASCII válido en palabra | Revela todas las posiciones | |
| Letra incorrecta | ASCII válido, no en palabra | `wrong_count++` | |
| Letra repetida | Letra ya usada | Se ignora, sin penalización | |
| Sexto error | 6ª letra incorrecta | Derrota por intentos | |
| Tiempo en cero | `time_left = 0` | Derrota por tiempo | |
| Palabra completa | Todas las letras reveladas | Victoria, `victories++` | |
| Carácter inválido | Byte fuera de A–Z | Se descarta sin afectar partida | |

### 10.2 Resultados físicos y funcionales

<!-- [INTEGRANTE 3, con apoyo de INTEGRANTE 1 y 2 según el módulo] -->

#### Pantalla de selección de modo

![Menú fácil y difícil en LCD](Imagenes/lcd_menu.jpg)

**Figura 5.** Pantalla de selección de modo mostrando fácil/difícil en el LCD.

#### Partida en curso

![Palabra oculta y letras reveladas](Imagenes/lcd_partida.jpg)

**Figura 6.** LCD mostrando la palabra parcialmente revelada, los intentos
restantes y el tiempo en los displays de siete segmentos.

#### Victoria y derrota

![Resultado final en LCD](Imagenes/lcd_resultado.jpg)

**Figura 7.** Pantalla de resultado final (victoria / derrota) y contador
acumulado de victorias en los displays.

#### Comunicación con la aplicación de PC

![Terminal Python durante una partida](Imagenes/python_terminal.png)

**Figura 8.** Consola de la aplicación de Python mostrando el envío de
letras y la recepción del estado de la partida.

#### Indicadores locales

<!-- LED de estado (menú/partida/resultado/dificultad) y buzzer. Puede
describirse el patrón sonoro medido con osciloscopio si se dispone de esa
evidencia. -->

#### Fotografía del sistema completo

<!-- OBLIGATORIO: fotografía del montaje físico completo en la Basys 3,
mostrando LCD, displays encendidos, LED y conexión al buzzer/PC. -->

![Sistema completo montado en la Basys 3](Imagenes/foto_sistema_fpga.jpg)

**Figura 9.** Sistema completo implementado sobre la tarjeta Basys 3,
incluyendo el módulo LCD PmodCLP, displays de siete segmentos y conexión
UART a la computadora.

### 10.3 Síntesis, implementación y utilización de recursos

<!-- [INTEGRANTE 3] Regenerar todos los reportes usando el top final
`hangman_top_completo`. -->

#### Resumen de utilización de recursos

<!-- Copiar literalmente del "Utilization Report" de Vivado. -->

| Recurso | Utilizado | Disponible | % Utilización |
|---|---:|---:|---:|
| Slice LUTs | | | |
| Slice Registers (FF) | | | |
| Slices | | | |
| Block RAM (BRAM) | | | |
| DSP | | | |
| Pines de E/S (IO) | | | |

#### Análisis de timing

<!-- Copiar literalmente del "Timing Summary" de Vivado. -->

```text
WNS = ___ ns
TNS = ___ ns
WHS (hold slack) = ___ ns
```

<!-- Confirmar explícitamente si se cumple el timing a 100 MHz (WNS ≥ 0 y
TNS = 0) y adjuntar la captura del reporte. -->

![Reporte de timing de Vivado](Imagenes/timing_summary.png)

**Figura 10.** Resumen de timing post-implementación para `hangman_top_completo`.

#### Evidencia de síntesis e implementación

![RTL elaborado](Imagenes/rtl_elaborado.png)

**Figura 11.** Esquemático RTL elaborado de `hangman_top_completo`.

![Diseño implementado en el dispositivo](Imagenes/device_implementado.png)

**Figura 12.** Vista del diseño implementado sobre el dispositivo FPGA
(Device view de Vivado).

#### FPGA y frecuencia de reloj

<!-- Especificar el modelo exacto de FPGA de la Basys 3 y confirmar que
el sistema opera con el único reloj de entrada de 100 MHz. -->

---

## 11. Análisis e interpretación de resultados

<!--
Peso 25% de la rúbrica. Aquí sí corresponde comparar valores teóricos,
simulados y experimentales, e identificar causas de diferencias o errores.
No repetir datos ya mostrados en la sección 10: referenciarlos por número
de figura/tabla y discutirlos.
-->

### 11.1 Análisis de la lógica del juego

<!-- [INTEGRANTE 1] Comparar el comportamiento esperado de `game_core`
(sección 3 y 7.3) contra lo observado en simulación (10.1) y en pruebas
físicas (10.2). Discutir, por ejemplo, la distribución del LFSR y la
estrategia de no repetición de palabra. -->

### 11.2 Análisis de la comunicación UART

<!-- [INTEGRANTE 2] Comparar el protocolo especificado (3.2) contra las
tramas observadas realmente, confiabilidad, manejo de caracteres
inválidos, limitaciones (p. ej. ausencia de FIFO). -->

### 11.3 Análisis del LCD

<!-- [INTEGRANTE 2] Tiempos de inicialización y actualización observados
frente a lo esperado por el datasheet HD44780; problemas de parpadeo o
retardo si existieron y su causa. -->

### 11.4 Análisis de síntesis, timing y recursos

<!-- [INTEGRANTE 3] Interpretar el WNS/TNS y el porcentaje de utilización
de recursos: ¿hay margen de timing?, ¿qué módulo consume más recursos y
por qué?, ¿el diseño sería escalable a un banco de palabras más grande? -->

### 11.5 Problemas y soluciones

<!-- [INTEGRANTE 3, con aportes de 1 y 2] Igual que en el Proyecto 1, usar
una tabla: Problema | Causa probable | Diagnóstico realizado | Solución
aplicada o recomendada. Incluir explícitamente, si aplica: UART sin FIFO,
LFSR con semilla fija, tiempos de espera conservadores del LCD, buzzer
activo en vez de pasivo. -->

| Problema | Causa probable | Diagnóstico realizado | Solución aplicada o recomendada |
|---|---|---|---|
| | | | |

---

## 12. Conclusiones

<!--
Peso 15% de la rúbrica. Conclusiones numeradas, claras, fundamentadas y
ligadas directamente a los objetivos y resultados del proyecto (no genéricas).
Incluir reflexiones o lecciones aprendidas, y las limitaciones/mejoras
futuras conocidas del equipo:
  - UART sin FIFO.
  - LFSR con semilla fija.
  - LCD con tiempos de espera conservadores.
  - Buzzer activo en lugar de pasivo.
-->

1. [INTEGRANTE 1/2/3, en conjunto]
2. …

---

## Anexos (opcional)

<!-- Código relevante, tablas extensas de asignación de pines, o cualquier
material de soporte que no encaje bien en el cuerpo del informe. -->
