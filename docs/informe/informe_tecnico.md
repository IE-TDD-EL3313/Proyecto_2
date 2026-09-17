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
