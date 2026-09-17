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

<!-- [INTEGRANTE 1] Resumen ejecutivo del proyecto: qué se construyó, cómo se
dividió el sistema (FPGA / PC), qué se logró demostrar, qué limitaciones
quedaron y una síntesis de los resultados de síntesis/verificación. Máximo
un párrafo o dos, escrito al final, cuando el resto del informe esté listo. -->

---

## 1. Introducción

### 1.1 Contexto

<!-- [INTEGRANTE 1] Descripción del juego de Ahorcado, motivación del
proyecto, diferencia respecto al Proyecto 1 (control local vs. control
coordinado con una aplicación externa por UART). Mencionar la Basys 3 y los
periféricos empleados (LCD PmodCLP, displays de 7 segmentos, LED, buzzer,
botones). -->

### 1.2 Solución desarrollada

<!-- [INTEGRANTE 1] Resumen de alto nivel de la arquitectura implementada:
FPGA concentra la lógica del juego (banco de palabras, LFSR, validación de
letras, tiempo, intentos); la PC actúa como terminal remota en Python vía
UART. Referenciar el nombre real del top-level: `hangman_top_completo`. -->

### 1.3 Alcance y limitaciones

<!-- [INTEGRANTE 1 / INTEGRANTE 3] Qué se implementó completamente, qué
quedó parcial o con limitaciones conocidas (ver también sección 12).
Ejemplos a evaluar según el estado real del proyecto: UART sin FIFO, LFSR
con semilla fija, tiempos de espera conservadores del LCD, buzzer activo
en vez de pasivo. -->

---

## 2. Objetivos

### 2.1 Objetivo general

<!-- [INTEGRANTE 1] Objetivo general del proyecto (adaptar del enunciado). -->

### 2.2 Objetivos específicos

<!-- [INTEGRANTE 1] Lista de objetivos específicos, alineados con los
objetivos de diseño ya definidos en docs/diseño/diseño.md, por ejemplo: -->

- Diseñar un banco de al menos 50 palabras almacenado en ROM sintetizable.
- Implementar un generador pseudoaleatorio LFSR para seleccionar la palabra.
- Diseñar la máquina de estados de control del juego (`game_core`).
- Diseñar el periférico LCD (PmodCLP) con interfaz de 32 bits.
- Diseñar el periférico UART y el protocolo de aplicación sobre UART.
- Implementar la aplicación de PC en Python como terminal remota.
- Verificar el sistema mediante testbenches autoverificables.
- Realizar simulación post-implementación temporizada.
- Comparar resultados teóricos, simulados y experimentales.

---

## 3. Especificaciones

### 3.1 Requisitos funcionales

<!-- [INTEGRANTE 1] Tabla comparando el requisito del enunciado contra la
implementación final, igual que se hizo en el Proyecto 1. Ejemplo de
filas a completar: -->

| Requisito | Valor especificado | Implementación final |
|---|---:|---|
| Tamaño del banco de palabras | ≥ 50 palabras | |
| Longitud de palabra | 4–12 caracteres | |
| Alfabeto permitido | A–Z sin tildes ni Ñ | |
| Intentos fallidos máximos | 6 | |
| Tiempo modo fácil | sugerido 60 s | |
| Tiempo modo difícil | sugerido 45 s | |
| Longitud mínima modo difícil | > 5 letras (6+) | |
| Baudios UART | 115200 | |
| Reloj de la FPGA | 100 MHz | |
| Displays de 7 segmentos | ≥ 4 dígitos | |
| LED de estado | mínimo 1 LED, 3 estados distinguibles | |
| Buzzer | 3 patrones distintos (acierto/error/fin) | |
| Botón de reinicio general | `BTN_RST` | |

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
T_{bit}\approx 8.68\,\mu s
$$

Como cada trama contiene diez bits en total —un bit de inicio, ocho bits de datos y un bit de parada—, el tiempo aproximado requerido para transmitir un byte es:

$$
T_{byte}=10(8.68\,\mu s)\approx86.8\,\mu s
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

<!-- [INTEGRANTE 2] Tabla de señales `clk_i`, `rst_i`, `write_enable_i`,
`addr_i[1:0]`, `wdata_i[31:0]`, `rdata_o[31:0]` y su significado. -->

### 3.4 Registros del periférico UART

<!-- [INTEGRANTE 2] Mapa de registros: DATA_TX (00), DATA_RX (01),
CONTROL/STATUS (10), con bits `send`/`tx_busy`, `new_rx`, campos de datos. -->

### 3.5 Registros del periférico LCD

<!-- [INTEGRANTE 2] Mapa de registros CONTROL/STATUS (00) y DATA (01):
bits start, rs, clear, home, busy, done. Secuencia de inicialización del
HD44780 (38h, 0Ch, 01h, 06h). -->

### 3.6 Requisitos eléctricos

<!-- [INTEGRANTE 1 o 2] Niveles lógicos utilizados (LVCMOS33 de la Basys 3),
conexión del PmodCLP y de los pulsadores, y cualquier consideración
eléctrica relevante. -->

---

## 4. Fundamentación teórica

<!-- Peso 20% de la rúbrica. Debe integrarse explícitamente con el trabajo
realizado, no solo describir teoría en abstracto. -->

### 4.1 Lógica combinacional y secuencial

<!-- [INTEGRANTE 1] Repaso breve aplicado a los registros y FSM del
proyecto (`game_core`, contadores, registros de estado). -->

### 4.2 Máquinas de estados finitos

<!-- [INTEGRANTE 1] Concepto de FSM de Moore/Mealy aplicado a la FSM
`MENU -> GAME -> RESULT -> MENU` de `game_core`. -->

### 4.3 Registro de desplazamiento con retroalimentación lineal (LFSR)

<!-- [INTEGRANTE 1] Teoría del LFSR, polinomio utilizado, por qué la
semilla no puede ser cero, y cómo se mapea la salida del LFSR de 8 bits a
un índice del banco de palabras. -->

### 4.4 Memorias de solo lectura (ROM) sintetizables

<!-- [INTEGRANTE 1] Cómo se codifica el banco de 50 palabras de longitud
variable en una ROM sintetizable en SystemVerilog. -->

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

<!-- [INTEGRANTE 1] Aplicado a `BTN_SEL`, `BTN_OK`, `BTN_RST`. -->

### 4.9 Multiplexación de displays de siete segmentos

<!-- [INTEGRANTE 2] Aplicado a los 4 dígitos (tiempo y victorias). -->

---

## 5. Metodología

### 5.1 Diseño modular

<!-- [INTEGRANTE 1] Referencia explícita al planteamiento del diseño
(docs/diseño/diseño.md): niveles de abstracción, separación control/datapath. -->

### 5.2 Flujo de desarrollo

<!-- [INTEGRANTE 1] Orden de implementación seguido (igual al plan de
implementación del diseño): habilitaciones temporales → botones → UART →
LFSR/ROM → FSM → datapath → LCD → displays/LED/buzzer → Python →
integración → simulación → implementación física. -->

### 5.3 Herramientas

<!-- [INTEGRANTE 1] Vivado (versión), simulador utilizado, lenguaje
(SystemVerilog), Python y librería `pyserial`, tarjeta Basys 3. -->

---

## 6. Arquitectura general

### 6.1 Jerarquía de módulos

<!-- [INTEGRANTE 1] Reproducir/actualizar el árbol de módulos real: -->

```text
hangman_top_completo
  button_conditioner x2
  game_core
    word_bank
  uart_game_interface
    uart_peripheral
  lcd_screen_controller_completo
  lcd_peripheral
  io_controller
```

### 6.2 Diagrama de bloques

<!-- [INTEGRANTE 1] Insertar y referenciar el diagrama de primer/segundo
nivel definido en docs/diseño/diseño.md. -->

![Diagrama general de bloques](Imagenes/diagrama_bloques.png)

**Figura 1.** Diagrama de bloques del sistema completo `hangman_top_completo`.

### 6.3 Flujo de una partida

<!-- [INTEGRANTE 1] Diagrama de flujo o descripción textual: selección de
modo → selección de palabra → recepción de letra → validación → repetición
→ fin de partida → regreso al menú. -->

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
