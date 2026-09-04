# Planteamiento del diseño
## Proyecto 2 – Ahorcado: juego electrónico FPGA / PC

## 1. Objetivo del diseño

El objetivo del proyecto es implementar un juego electrónico de Ahorcado en el cual la FPGA concentre la lógica principal de la partida y una computadora funcione como interfaz remota para el usuario.

La FPGA será responsable de seleccionar la palabra secreta, administrar la dificultad, recibir y validar las letras ingresadas, controlar los intentos disponibles, gestionar el tiempo de la partida, determinar condiciones de victoria o derrota y actualizar los diferentes dispositivos de visualización.

La computadora utilizará una aplicación desarrollada en **Python** para permitir que el jugador ingrese letras y visualizar la información recibida desde la FPGA mediante comunicación UART.

El sistema se plantea siguiendo una metodología de diseño modular y jerárquica, de forma que cada bloque posea una función específica y pueda ser diseñado y verificado de manera independiente antes de realizar la integración completa.

---

# 2. Arquitectura general

El diseño se organiza mediante diferentes niveles de abstracción.

El primer nivel presenta las entradas y salidas externas del sistema completo. El segundo nivel divide el sistema en sus bloques funcionales principales. A partir del tercer nivel se detallan internamente estos bloques hasta obtener unidades suficientemente simples para su posterior implementación en SystemVerilog o Python.

Los principales bloques funcionales considerados son:

- Gestión de entradas locales.
- Comunicación con la computadora.
- Aplicación de computadora en Python.
- Gestión de palabras.
- Gestión del tiempo.
- Control y coordinación del juego.
- Gestión de visualización y alertas.
- Reloj y señales de habilitación.
- LCD.
- Displays de siete segmentos.
- LED de estado.
- Buzzer.

---

# 3. Diagrama de primer nivel

<!-- INSERTAR AQUÍ LA IMAGEN DEL DIAGRAMA DE PRIMER NIVEL -->

![Diagrama de primer nivel](https://github.com/IE-TDD-EL3313/Proyecto_2/blob/main/docs/dise%C3%B1o/figuras/Primer%20Nivel.png)

**Figura 1. Diagrama de primer nivel del sistema.**

El diagrama de primer nivel representa el sistema completo como un único bloque y permite identificar las interfaces externas principales.

Las entradas consideradas son:

- `CLK` de 100 MHz.
- `BTN_SEL`, utilizado para cambiar el modo de dificultad.
- `BTN_OK`, utilizado para confirmar la selección e iniciar una partida.
- `BTN_RST`, utilizado para realizar el reinicio general.
- Entrada UART proveniente de la computadora, utilizada para recibir las letras ingresadas por el jugador.

Las salidas principales son:

- Comunicación UART hacia la computadora.
- LCD externo de 16x2.
- Displays de siete segmentos.
- LED indicador de estado.
- Buzzer.

El LCD permite mostrar información como el modo seleccionado, el patrón actual de la palabra y los intentos disponibles. Los displays de siete segmentos muestran información numérica, principalmente el tiempo restante y las victorias acumuladas. El LED identifica visualmente la etapa actual del juego y el buzzer genera diferentes alertas sonoras.

Este nivel permite definir claramente la frontera del sistema antes de realizar la descomposición interna.

---

# 4. Diagrama de segundo nivel

<!-- INSERTAR AQUÍ LA IMAGEN DEL DIAGRAMA DE SEGUNDO NIVEL -->

![Diagrama de segundo nivel](https://github.com/IE-TDD-EL3313/Proyecto_2/blob/main/docs/dise%C3%B1o/figuras/Segundo%20Nivel.png)

**Figura 2. Diagrama de segundo nivel del sistema.**

El segundo nivel divide el sistema en bloques funcionales de mayor nivel.

## 4.1 Botones integrados

Representa físicamente los pulsadores utilizados para seleccionar dificultad, confirmar una selección y reiniciar el sistema.

Las señales provenientes de estos elementos son enviadas al bloque de gestión de entradas locales.

---

## 4.2 Gestión de entradas locales

Este bloque acondiciona las señales provenientes de los pulsadores antes de entregarlas a la lógica principal.

Sus funciones incluyen:

- Sincronización con el reloj de la FPGA.
- Eliminación del rebote mecánico.
- Detección de nuevas pulsaciones.
- Generación de pulsos de un solo ciclo.

Las señales procesadas son posteriormente utilizadas por el bloque de control y coordinación del juego.

---

## 4.3 Computadora

La computadora ejecuta una aplicación desarrollada en **Python**.

Su función es:

- Recibir una letra ingresada por el usuario.
- Verificar que la entrada sea válida.
- Transmitir la letra mediante UART.
- Recibir información desde la FPGA.
- Mostrar el estado de la partida.

La aplicación de Python funciona únicamente como una interfaz remota. Toda la lógica del juego se mantiene implementada en la FPGA.

---

## 4.4 Comunicación con la PC

Este bloque implementa la comunicación serial bidireccional entre la FPGA y la aplicación de Python.

Su función es recibir letras desde la computadora y transmitir información relacionada con la partida.

La comunicación se implementa mediante UART.

---

## 4.5 Gestión de palabras

Este bloque contiene los elementos relacionados con la selección y manejo de la palabra secreta.

Sus funciones principales son:

- Generar un valor pseudoaleatorio.
- Seleccionar una palabra de acuerdo con el modo de dificultad.
- Almacenar la palabra activa.
- Comparar las letras recibidas.
- Mantener el patrón de letras reveladas.

---

## 4.6 Gestión del tiempo

Este bloque controla la duración de cada partida.

Se encarga de:

- Cargar el tiempo correspondiente al modo seleccionado.
- Realizar la cuenta regresiva.
- Entregar el tiempo restante.
- Detectar cuándo el tiempo llega a cero.

---

## 4.7 Control y coordinación del juego

Este bloque constituye la unidad central de control.

Coordina la operación de:

- Selección de dificultad.
- Selección de palabra.
- Inicio de partida.
- Recepción de letras.
- Validación de letras.
- Actualización de intentos.
- Temporización.
- Condiciones de victoria.
- Condiciones de derrota.
- Actualización de visualización.
- Inicio de una nueva partida.

La implementación se plantea mediante una máquina de estados finitos.

---

## 4.8 Gestión de visualización y alertas

Este bloque recibe el estado actual del juego y genera la información necesaria para los dispositivos de salida.

Controla:

- LCD.
- Displays de siete segmentos.
- LED de estado.
- Buzzer.

---

## 4.9 Reloj integrado

El sistema utiliza como referencia principal el reloj de 100 MHz disponible en la FPGA.

A partir de este reloj se generan señales de habilitación de menor frecuencia para:

- Antirrebote.
- Cuenta regresiva de tiempo.
- Multiplexación de displays.
- Otras temporizaciones del sistema.

---

# 5. Diagrama de tercer nivel

El diagrama de tercer nivel presenta en una **única figura** la descomposición interna de los principales bloques funcionales definidos en el segundo nivel.

<!-- INSERTAR AQUÍ LA ÚNICA IMAGEN DEL DIAGRAMA DE TERCER NIVEL -->

![Diagrama de tercer nivel](imagenes/diagramas/tercer_nivel.png)

**Figura 3. Diagrama de tercer nivel del sistema completo.**

En este nivel se detallan la gestión de entradas locales, distribución del reloj, gestión de palabras, gestión del tiempo, control y coordinación del juego, comunicación con la computadora y gestión de visualización y alertas.

---

## 5.1 Gestión de entradas locales y reloj

### Gestión de entradas locales

Las señales `BTN_SEL`, `BTN_OK` y `BTN_RST` ingresan inicialmente a un banco de sincronizadores.

El banco de sincronizadores permite llevar las señales externas al dominio de reloj de la FPGA.

La salida sincronizada, representada mediante `btn_sync`, es enviada posteriormente a un banco de filtros antirrebote.

Los filtros utilizan una señal periódica de muestreo para comprobar que el estado de cada botón permanezca estable durante el tiempo requerido.

La señal resultante `btn_stable` es enviada a un banco de detectores de flanco.

Los detectores generan pulsos de un ciclo:

- `sel_pulse`
- `ok_pulse`
- `rst_pulse`

Estas señales son utilizadas por la máquina de estados principal.

### Distribución del reloj

El reloj integrado de 100 MHz es recibido por un bloque de distribución temporal encargado de generar diferentes habilitaciones.

Se plantean principalmente:

- `ce_debounce`: señal utilizada para el filtrado de botones.
- `ce_1s`: habilitación de un segundo utilizada por la gestión del tiempo.
- `ce_display`: habilitación utilizada para refrescar los displays multiplexados.

El uso de señales de habilitación permite mantener un único dominio de reloj y evitar la generación innecesaria de relojes derivados.

---

## 5.2 Gestión de palabras

La gestión de palabras incluye un generador LFSR utilizado para producir una secuencia pseudoaleatoria.

El valor generado se utiliza para seleccionar una posición dentro del banco de palabras.

El bloque de ajuste de rango y banco ROM determina qué palabra utilizar según:

- Valor pseudoaleatorio.
- Modo de dificultad seleccionado.
- Restricciones de longitud correspondientes al modo.

La palabra seleccionada se almacena posteriormente en un registro.

El bloque de registro de palabra y comparador permite:

- Mantener la palabra activa.
- Comparar la letra recibida con los caracteres de la palabra.
- Identificar las posiciones coincidentes.
- Actualizar las letras reveladas.
- Detectar cuándo la palabra está completa.

---

## 5.3 Gestión del tiempo

El bloque de gestión del tiempo utiliza un temporizador regresivo.

Al comenzar una nueva partida se carga el valor correspondiente al modo seleccionado.

El contador disminuye utilizando una habilitación temporal de un segundo.

Sus principales resultados son:

- Tiempo restante.
- Indicación de tiempo agotado.
- Estado activo del temporizador.

Cuando el tiempo llega a cero, se genera una condición de derrota que es enviada a la unidad de control.

---

## 5.4 Control y coordinación del juego

El control principal se plantea mediante una máquina de estados finitos.

También se utilizan registros para almacenar información asociada a la partida, como:

- Patrón de palabra.
- Errores acumulados.
- Tiempo.
- Condición de victoria.

El bloque datapath mantiene y procesa la información necesaria para el desarrollo del juego.

La FSM decide cuándo:

- Seleccionar una palabra.
- Iniciar el temporizador.
- Esperar una letra.
- Validar una letra.
- Actualizar el patrón.
- Registrar un error.
- Declarar victoria.
- Declarar derrota.
- Mostrar el resultado final.
- Regresar a la selección de dificultad.

La separación entre FSM y datapath permite mantener diferenciadas la lógica de control y la lógica de procesamiento de datos.

---

## 5.5 Computadora

La computadora ejecuta una aplicación desarrollada en **Python**.

El bloque de computadora se divide en:

- Entrada de usuario.
- Validador de letra.
- Gestor UART.
- Procesamiento y visualización.

La entrada de usuario recibe el carácter ingresado.

El validador verifica que el carácter corresponda a una entrada permitida y genera:

- `letra_ascii[7:0]`
- `letra_valida`

El gestor UART de la aplicación Python administra la transmisión hacia la FPGA y la recepción de mensajes provenientes del sistema.

Los mensajes recibidos son enviados al bloque de procesamiento y visualización.

Este bloque interpreta la información y actualiza:

- `patron_palabra`
- `intentos_restantes`
- `resultado_letra`
- `resultado_final`

La aplicación Python no determina si una letra es correcta o incorrecta, ni controla el tiempo o los intentos. Estas funciones pertenecen a la FPGA.

---

## 5.6 Comunicación con la PC

El bloque de comunicación se divide en:

- UART RX.
- Banco de registros UART.
- Control UART.
- UART TX.

Su función principal es administrar la transferencia serial bidireccional entre la FPGA y la aplicación desarrollada en Python.

### UART RX

Convierte la información serial recibida desde la computadora en un dato paralelo de 8 bits.

Genera:

- `rx_data[7:0]`
- `rx_valid`

### Banco de registros UART

Almacena temporalmente los datos recibidos y los datos que deben transmitirse.

Además, proporciona la interfaz entre el UART y el bloque de control del juego.

### Control UART

Coordina las operaciones de transmisión.

Genera la señal `tx_start` e identifica la finalización de una transmisión mediante `tx_done`.

### UART TX

Convierte `tx_data[7:0]` a una secuencia serial y la transmite hacia la computadora.

La comunicación UART se diseña para permitir intercambio bidireccional confiable entre la FPGA y la aplicación Python.

---

## 5.7 Gestión de visualización y alertas

Este bloque concentra las funciones relacionadas con las salidas físicas del sistema.

Recibe información desde:

- Máquina de estados.
- Registro de partida.
- Reloj del sistema.

La unidad de control de alertas determina qué información debe presentarse dependiendo del estado actual.

### Gestión de LCD

El bloque formateador de pantallas recibe la selección de pantalla y los datos de la partida.

Genera el contenido requerido para las dos líneas del LCD.

El periférico LCD convierte esta información en las señales físicas necesarias para controlar el display externo de 16x2.

### Gestión de sonido

El selector de tono recibe eventos como:

- Acierto.
- Error.
- Fin de partida.

Según el evento ocurrido, selecciona el tono correspondiente.

El generador de tono produce finalmente la señal que controla el buzzer externo.

### Gestión de visualización

El bloque de displays recibe datos como:

- Tiempo restante.
- Victorias acumuladas.

Un multiplexor y decodificador de siete segmentos genera:

- `seg_o[6:0]`
- `an_o`

Estas señales controlan los displays integrados.

El decodificador de LED recibe información sobre la fase actual del juego y genera `led_o`, permitiendo identificar visualmente el estado general del sistema.

---

# 6. Diagramas de cuarto nivel

Los diagramas de cuarto nivel detallan los bloques de la computadora y de la comunicación UART hasta obtener unidades funcionales simples.

---
# 6.1 Gestión de entradas locales y reloj



# 6.2 Cuarto nivel – Gestión de Palabras

La gestión de palabras se detalla en dos sub-bloques: el generador de índice pseudoaleatorio junto con el banco de palabras en ROM, y el registro de la palabra activa junto con el comparador de letras.

## Sub-bloque: LFSR + Ajuste de rango + ROM Banco de Palabras

**a) Nombre del módulo:** Generador de índice y banco de palabras.

**b) Diagrama modular:** *(copiar del diagrama de tercer nivel — sub-bloque "LFSR + Ajuste de rango + ROM Banco de Palabras" dentro de Gestión de Palabras)*

**c) Objetivo:** Generar de forma pseudoaleatoria un índice válido dentro del banco de palabras, respetando el subrango correspondiente al modo de dificultad, y entregar la palabra almacenada en esa dirección.

**d) Entradas:** `clk`, `rst`, `dificultad` (1 bit, desde Control), `pedir_palabra` (pulso, desde Control)

**e) Salidas:** `palabra_rom[63:0]` (interno, hacia el Registro Palabra + Comparador)

**f) Relación con otros módulos:** Recibe `dificultad` del Registro de Modo (dentro de Control) y `pedir_palabra` de la Unidad de Control. Entrega su salida al sub-bloque "Registro Palabra + Comparador" del mismo bloque de Gestión de Palabras.

**g) Explicación de funcionamiento:** El LFSR avanza en cada flanco de reloj (free-running), generando una secuencia pseudoaleatoria de 8 bits de periodo máximo. Cuando llega `pedir_palabra`, el valor actual del LFSR se transforma en una dirección válida de ROM según el ajuste de rango, y esa dirección se usa para leer la palabra correspondiente.

**h) Diseño — justificación y ecuaciones:**

**LFSR de 8 bits (polinomio y ecuación de realimentación):**

```
Polinomio: x^8 + x^6 + x^5 + x^4 + 1   (LFSR Fibonacci, periodo máximo 255)
Semilla: cualquier valor != 0x00 (fijada por reset, ej. 8'b10110011)

feedback = lfsr[7] XOR lfsr[5] XOR lfsr[4] XOR lfsr[3]
lfsr <= {lfsr[6:0], feedback}     (cada ciclo de clk, free-running: en=1 fijo)
```

*Justificación:* se eligió operación free-running (sin señal de habilitación externa) para que el valor capturado al momento de `pedir_palabra` sea independiente del tiempo que el jugador tardó en presionar `BTN_OK` — esto evita que la secuencia sea predecible por el usuario.

**Ecuación de ajuste de rango (formato ROM y organización de direcciones):**

| Campo | Bits | Descripción |
|---|---|---|
| `longitud` | `[63:60]` | Longitud real de la palabra (4–12) |
| `letra_1` … `letra_12` | `[59:0]`, 5 bits c/u | Código A=`00001` … Z=`11010`; relleno con `00000` si la palabra es más corta que 12 |

| Dificultad | Direcciones ROM | Contenido |
|---|---|---|
| Fácil (0) | `0–49` | Las 50 palabras completas del banco |
| Difícil (1) | subrango superior, ej. `30–49` | Palabras ≥6 letras, ubicadas contiguas al final de la ROM |

```
indice_valido = dificultad ? (30 + (lfsr[4:0] % 20))   // Difícil: direcciones 30-49
                            : (lfsr[7:0] % 50)          // Fácil: direcciones 0-49
```

*Justificación:* ordenar la ROM con las palabras largas en un bloque contiguo permite resolver la selección por dificultad con una sola operación de rango en vez de una tabla de excepciones o un segundo comparador por palabra.

**Latencia de la ROM (detalle de timing):**

```
Ciclo 1 (pedir_palabra = 1):
  direccion_rom <= indice_valido

Ciclo 2 (automático, un ciclo después — la ROM sintetiza a Block RAM con salida registrada):
  palabra_rom disponible en la salida
```

*Justificación:* una ROM sintetizada como Block RAM en FPGA típicamente registra su salida, por lo que el dato no está disponible en el mismo ciclo en que se presenta la dirección. Esta latencia de 1 ciclo se traslada directamente al sub-bloque "Registro Palabra + Comparador" y es compatible con el diseño de la FSM de Control, que ya espera `palabra_lista` como un pulso, sin asumir que llega instantáneamente.

## Sub-bloque: Registro Palabra + Comparador

**a) Nombre del módulo:** Registro de palabra actual y comparador de letra.

**b) Diagrama modular:** *(copiar del diagrama de tercer nivel — sub-bloque "Registro Palabra + Comparador")*

**c) Objetivo:** Almacenar la palabra secreta seleccionada y comparar cada letra recibida contra sus 12 posiciones, generando la máscara de coincidencia.

**d) Entradas:** `clk`, `rst`, `palabra_rom[63:0]` (desde ROM, disponible 1 ciclo después de `pedir_palabra`), `letra_in[4:0]`, `validar` (pulso, desde Control)

**e) Salidas:** `longitud_palabra[3:0]`, `palabra_lista` (pulso), `mask_coincidencia[11:0]`

**f) Relación con otros módulos:** Recibe la palabra del sub-bloque ROM. Entrega `longitud_palabra` y `palabra_lista` a la Unidad de Control, y `mask_coincidencia` al Datapath de Control (que la reduce a `flags.hay_acierto`).

**g) Explicación de funcionamiento:** Al recibir la palabra de la ROM (un ciclo después de `pedir_palabra`), la deserializa en 12 grupos de 5 bits y guarda la longitud. Al recibir `validar`, compara `letra_in` contra cada una de las 12 posiciones válidas (según `longitud_palabra`) y activa el bit correspondiente de `mask_coincidencia` donde haya coincidencia.

**h) Diseño — ecuaciones de carga:**

```
Evento: 1 ciclo después de pedir_palabra (palabra_rom disponible)
  para i en 0..11:
    letras_palabra[i][4:0] <= palabra_rom[(i*5)+4 : i*5]
  longitud_palabra[3:0]    <= palabra_rom[63:60]
  palabra_lista            <= 1                        (pulso de 1 ciclo)

Evento: validar = 1
  para i en 0..11:
    mask_coincidencia[i] <= (letras_palabra[i] == letra_in) AND (i < longitud_palabra)
```

---

# 6.3 Cuarto nivel – Gestión del Tiempo

## Sub-bloque: Temporizador de Partida

**a) Nombre del módulo:** Temporizador de partida.

**b) Diagrama modular:** *(copiar del diagrama de tercer nivel — bloque completo "Gestión del Tiempo")*

**c) Objetivo:** Contar de forma regresiva el tiempo disponible de la partida según el modo de dificultad, y notificar a Control cuando el tiempo se agota.

**d) Entradas:** `clk`, `rst`, `tick_1s` (desde Reloj Integrado), `dificultad`, `tiempo_activo` (desde Control)

**e) Salidas:** `tiempo_restante_bcd[7:0]` (hacia Visualización, directo), `tiempo_agotado` (hacia Control)

**f) Relación con otros módulos:** Recibe `tick_1s` del Reloj Integrado y `dificultad`/`tiempo_activo` de Control. Su salida `tiempo_restante_bcd` va directo a Gestión de Visualización (no pasa por Control); `tiempo_agotado` sí va a la Unidad de Control.

**g) Explicación de funcionamiento:** Mientras `tiempo_activo=0`, el temporizador permanece en reposo (`IDLE`). Al activarse `tiempo_activo`, carga el límite correspondiente al modo (60 s Fácil / 45 s Difícil) y decrementa 1 unidad por cada `tick_1s` recibido, hasta llegar a 0, momento en el cual activa `tiempo_agotado` mientras permanece en el mismo estado hasta que Control decida desactivar `tiempo_activo`.

**h) Diseño — diagrama de estados y ecuaciones:**

<!-- INSERTAR AQUÍ LA IMAGEN DEL DIAGRAMA DE ESTADOS DEL TEMPORIZADOR -->

![Diagrama de estados del Temporizador de Partida](figuras/dg1.jpg)

**Figura 4. Diagrama de estados del Temporizador de Partida (dibujado a mano por el equipo).**

El diagrama contempla dos estados, `IDLE` y `CONTANDO`. La transición `IDLE → CONTANDO` ocurre con `tiempo_activo=1`, momento en el cual se carga el límite según la dificultad. La transición de regreso `CONTANDO → IDLE` ocurre con la única condición `tiempo_activo=0`.

**Nota de diseño:** `tiempo_restante == 0` **no** regresa el temporizador a `IDLE` por sí solo — solo activa la bandera `tiempo_agotado=1`, permaneciendo en `CONTANDO` hasta que Control decida bajar `tiempo_activo` (por ejemplo, al pasar a `FIN_PARTIDA`). El Temporizador solo cuenta y reporta; la decisión de terminar la partida le corresponde a la Unidad de Control.

| Registro | Ancho | Carga | Actualización |
|---|---|---|---|
| `tiempo_restante` | 7 bits (0–99) | Al entrar a `CONTANDO`: `60` si `dificultad=0`, `45` si `dificultad=1` | `tiempo_restante <= tiempo_restante - 1` cada `tick_1s`, solo en estado `CONTANDO` |
| `tiempo_restante_bcd[7:0]` | combinacional | — | Conversión binario→BCD (decenas en `[7:4]`, unidades en `[3:0]`) |
| `tiempo_agotado` | 1 bit | — | `= (tiempo_restante == 0)` en estado `CONTANDO` |

---

# 6.4 Cuarto nivel – Control y Coordinación del Juego

## Sub-bloque: Registro de Modo

**a) Nombre del módulo:** Registro de modo de dificultad.

**b) Diagrama modular:** *(copiar del diagrama de tercer nivel — sub-bloque "Registro de Modo")*

**c) Objetivo:** Mantener el valor de dificultad seleccionado, alternando entre Fácil y Difícil mientras el sistema está en `SEL_MODO`.

**d) Entradas:** `clk`, `rst`, `sel_pulse`, `rst_pulse`

**e) Salidas:** `dificultad` (1 bit)

**f) Relación con otros módulos:** Su salida alimenta a Gestión de Palabras (ajuste de rango) y Gestión del Tiempo (límite de tiempo). Recibe `sel_pulse` directo desde Gestión de entradas locales, sin pasar por la Unidad de Control.

**g) Explicación de funcionamiento:** Cada `sel_pulse` invierte el valor de `dificultad`. `rst_pulse` lo regresa a 0 (Fácil) como valor por defecto.

**h) Diseño:**

```
Evento: sel_pulse = 1
  dificultad <= ~dificultad
Evento: rst_pulse = 1 (o rst)
  dificultad <= 0   (Fácil, por defecto)
```

## Sub-bloque: Unidad de Control (FSM) + Datapath

**a) Nombre del módulo:** Unidad de Control y Datapath del juego.

**b) Diagrama modular:** *(copiar del diagrama de tercer nivel — sub-bloques "Unidad de Control" y "Datapath")*

**c) Objetivo:** Coordinar el flujo completo de una partida (selección de modo, carga de palabra, juego, validación de letras, resultado final), decidiendo en cada estado qué acción ordenar al Datapath y qué señales enviar al resto de bloques del sistema.

**d) Entradas:**

*Unidad de Control (solo bits de condición):* `clk`, `rst`, `sel_pulse`, `ok_pulse`, `rst_pulse`, `nueva_letra`, `palabra_lista`, `tiempo_agotado`, `flags[3:0]`

*Datapath (buses de datos + comando):* `letra_ascii[7:0]`, `mask_coincidencia[11:0]`, `longitud_palabra[3:0]`, `palabra_lista`, `cmd[2:0]`

**e) Salidas:**

*Unidad de Control:* `pedir_palabra`, `validar`, `tiempo_activo`, `estado_juego[1:0]`, `evento_sonido[1:0]`, `cmd[2:0]`

*Datapath:* `flags[3:0]`, `letra_in[4:0]`, `palabra_revelada[11:0]`, `intentos_restantes[2:0]`, `partidas_ganadas_bcd[7:0]`, `trama_estado`

**f) Relación con otros módulos:** Es el nodo central del sistema — se conecta con Gestión de entradas locales, Comunicación con la PC, Gestión de Palabras, Gestión del Tiempo, Gestión de Visualización y Alertas, y Buzzer Externo. La Unidad de Control y el Datapath se retroalimentan entre sí mediante `cmd[2:0]` (control→datos) y `flags[3:0]` (datos→control).

**g) Explicación de funcionamiento:** La Unidad de Control es una FSM de 5 estados (`SEL_MODO`, `CARGANDO`, `JUGANDO`, `VALIDANDO`, `FIN_PARTIDA`) que decide únicamente con base en condiciones booleanas de 1 bit. Nunca examina directamente un bus de datos: toda comparación de magnitudes (longitud de palabra, máscara de coincidencia, conteo de intentos) ocurre en el Datapath, que reduce esos buses a las 4 banderas de `flags[3:0]`. La FSM ordena acciones al Datapath mediante `cmd[2:0]`, y este ejecuta la actualización de registros correspondiente.

**h) Diseño — codificación de señales y diagrama de estados:**

**Codificación `cmd[2:0]` (Unidad de Control → Datapath):**

| cmd | Acción |
|---|---|
| `000` | Ninguna (reposo) |
| `001` | `carga_letra` |
| `010` | `incrementa_intento` |
| `011` | `incrementa_ganadas` |
| `100` | `limpia_todo` |
| `101` | `enviar_trama` |

**Codificación `flags[3:0]` (Datapath → Unidad de Control):**

| bit | Nombre | Se activa cuando |
|---|---|---|
| `flags[0]` | `hay_acierto` | `mask_coincidencia != 0` |
| `flags[1]` | `letra_repetida` | la letra ya estaba marcada en `letras_usadas` |
| `flags[2]` | `palabra_completa` | todas las posiciones de `palabra_revelada` están reveladas |
| `flags[3]` | `intentos_agotados` | `intentos_fallidos == 6` |

**Codificación `estado_juego[1:0]`:**

| Código | Estado |
|---|---|
| `00` | SEL_MODO |
| `01` | CARGANDO |
| `10` | JUGANDO |
| `11` | FIN_PARTIDA |

**Diagrama de estados:**

<!-- INSERTAR AQUÍ LA IMAGEN DEL DIAGRAMA DE ESTADOS DE LA UNIDAD DE CONTROL -->

![Diagrama de estados de la Unidad de Control](figuras/dg2.jpg)

**Figura 5. Diagrama de estados de la Unidad de Control (dibujado a mano por el equipo).**

El diagrama contempla cinco estados — `SEL_MODO`, `CARGANDO`, `JUGANDO`, `VALIDANDO`, `FIN_PARTIDA` — con las transiciones principales `ok_pulse`, `palabra_lista`, `nueva_letra=1`, `continúa`, `fin_partida`, `contador_despliegue==3`. El detalle de cada transición agrupada se documenta en las tablas siguientes.

**Nota de diseño — `rst_pulse`:** no se dibuja en el diagrama para no saturarlo, pero `rst_pulse` regresa la FSM a `SEL_MODO` desde **cualquier estado**, con prioridad máxima sobre cualquier otra transición.

**Tabla de transición — desde `VALIDANDO`:**

| Condición | Acción (`cmd`) | `evento_sonido` | Hacia |
|---|---|---|---|
| `flags.palabra_completa` | `enviar_trama` | victoria | FIN_PARTIDA |
| `flags.intentos_agotados` OR `tiempo_agotado` | `enviar_trama` | derrota | FIN_PARTIDA |
| `flags.letra_repetida` | ninguno | nada | JUGANDO *(se ignora, no consume intento ni resetea tiempo)* |
| letra válida no repetida, `flags.hay_acierto=1` | `carga_letra` | acierto | JUGANDO |
| letra válida no repetida, `flags.hay_acierto=0` | `incrementa_intento` | error | JUGANDO *(o FIN_PARTIDA si con este error se activa `flags.intentos_agotados`)* |

**Tabla de transición — desde `FIN_PARTIDA`:**

| Evento | Efecto |
|---|---|
| Al entrar al estado | Muestra `GANÓ`/`PERDIÓ` en LCD; `cmd=incrementa_ganadas` solo si el resultado fue victoria; `tiempo_activo=0` |
| `contador_despliegue == 3` | Regresa a `SEL_MODO` |

**Notas de diseño (casos de borde):**

> **`nueva_letra` fuera de `JUGANDO`:** la señal `nueva_letra` solo produce una transición de estado cuando el sistema está en `JUGANDO` (transición hacia `VALIDANDO`). Si `nueva_letra` llega estando en `SEL_MODO`, `CARGANDO` o `FIN_PARTIDA`, la FSM permanece en su estado actual y la letra se descarta sin efecto sobre la partida — no se requiere lógica adicional, es consecuencia directa de que solo existe una transición que consume `nueva_letra`.

> **Prioridad `ok_pulse` vs `sel_pulse`:** si ambos pulsos llegan activos en el mismo ciclo de reloj (poco probable pero posible), `ok_pulse` tiene prioridad: la FSM confirma el modo actualmente mostrado e inicia la partida, ignorando el cambio de modo solicitado por `sel_pulse` en ese ciclo.

> **Despliegue de resultado (3 s):** el estado `FIN_PARTIDA` permanece activo mientras `contador_despliegue < 3`. Este contador se incrementa con cada `tick_1s` y se reinicia a 0 al entrar al estado. Al alcanzar 3, la FSM regresa a `SEL_MODO`.

**Tabla de registros del Datapath:**

| Registro | Ancho | Se actualiza con | Detalle |
|---|---|---|---|
| `letras_usadas` | 26 bits | `cmd=carga_letra` | `letras_usadas[letra_ascii-'A'] <= 1` |
| `palabra_revelada` | 12 bits | `cmd=carga_letra` (si `hay_acierto`) | `palabra_revelada <= palabra_revelada OR mask_coincidencia` |
| `intentos_fallidos` | 3 bits | `cmd=incrementa_intento` | `intentos_fallidos <= intentos_fallidos + 1` |
| `partidas_ganadas_bcd` | 8 bits | `cmd=incrementa_ganadas` | Incrementa en BCD, satura en 99 |
| `intentos_restantes` | 3 bits (salida) | combinacional | `= 6 - intentos_fallidos` |
| `contador_despliegue` | 2 bits | `tick_1s`, mientras `estado_juego==FIN_PARTIDA` | Se reinicia a 0 al entrar al estado; cuenta hasta 3, dispara el regreso a `SEL_MODO` |

# 6.5 Cuarto nivel – Computadora

<!-- INSERTAR AQUÍ LA IMAGEN DEL CUARTO NIVEL DE COMPUTADORA -->

![Cuarto nivel de computadora](imagenes/diagramas/cuarto_nivel_computadora.png)

**Figura 4. Diagrama de cuarto nivel de la aplicación desarrollada en Python.**

La aplicación de computadora se divide con mayor detalle en cuatro secciones.

## Entrada de usuario

Incluye:

- Captura de teclado.
- Registro de carácter.
- Generador de evento.

Su función es detectar una nueva entrada del usuario y almacenarla para su procesamiento.

## Validador de letra

Incluye:

- Comparador ASCII.
- Filtro de caracteres.
- Generador de `letra_valida`.

El comparador verifica el rango del carácter recibido.

El filtro descarta entradas no permitidas y el generador de validación indica cuándo existe una letra lista para transmisión.

## Gestor UART

Incluye:

- Control de transmisión.
- Formador de mensaje TX.
- Control de recepción.
- Decodificador de mensaje RX.

El formador de mensajes prepara la información antes de transmitirla.

El control de recepción administra los datos provenientes de la FPGA y el decodificador interpreta el mensaje recibido.

## Procesamiento y visualización

Incluye:

- Decodificador de respuesta.
- Actualizador de patrón.
- Control de intentos.
- Resultado de letra.
- Resultado final.

Su función es convertir los mensajes recibidos en información comprensible para el usuario.

---

# 6.6 Cuarto nivel – Comunicación con la PC

<!-- INSERTAR AQUÍ LA IMAGEN DEL CUARTO NIVEL DE UART -->

![Cuarto nivel de comunicación UART](imagenes/diagramas/cuarto_nivel_uart.png)

**Figura 5. Diagrama de cuarto nivel de la comunicación con la computadora.**

## UART RX

El receptor se divide en:

- Sincronizador RX.
- Detector de start.
- Contador de bits.
- Registro de desplazamiento.
- Lógica de recepción.

La señal serial primero es sincronizada.

Posteriormente se detecta el bit de inicio y comienza el proceso de muestreo de los bits correspondientes al dato.

El registro de desplazamiento almacena los bits recibidos hasta formar `rx_data[7:0]`.

Cuando el byte se encuentra completo se genera `rx_valid`.

## Banco de registros UART

Se divide en:

- Registro RX.
- Registro TX.
- Decodificador de dirección.
- Multiplexor de lectura.
- Lógica de escritura.

Este bloque implementa la interfaz entre el controlador del juego y los núcleos UART.

La dirección `addr_i[1:0]` selecciona el registro que será leído o escrito.

`wdata_i[31:0]` proporciona los datos de escritura y `rdata_o[31:0]` devuelve el contenido seleccionado.

## Control UART

Incluye:

- FSM UART.
- Generador de `tx_start`.
- Control de sincronización.
- Detección de nueva recepción.

La FSM coordina las operaciones del periférico.

El control de sincronización administra las señales utilizadas para iniciar y finalizar transmisiones.

La señal `tx_start` inicia una nueva transmisión y `tx_done` informa que esta ha finalizado.

## UART TX

El transmisor se divide en:

- Registro paralelo.
- Generador de baud rate / contador.
- FSM TX.
- Registro serial.
- Lógica de stop.

El dato paralelo `tx_data[7:0]` se carga inicialmente en el transmisor.

Posteriormente la FSM controla la transmisión serial de:

1. Bit de inicio.
2. Bits de datos.
3. Bit de parada.

El generador de baud rate determina la duración de cada bit y el registro serial entrega finalmente la señal `uart_tx`.

---

# 7. Decisiones principales de diseño

## 7.1 Arquitectura modular

Se seleccionó una arquitectura jerárquica para separar claramente las funciones del sistema.

Esto permite:

- Diseñar cada módulo de manera independiente.
- Facilitar la simulación.
- Simplificar la detección de errores.
- Reutilizar módulos.
- Mantener una estructura clara en SystemVerilog y Python.

---

## 7.2 FPGA como controlador principal

La lógica del juego se mantiene dentro de la FPGA.

La computadora, mediante la aplicación Python, funciona únicamente como interfaz remota.

Por lo tanto, decisiones como:

- Determinar si una letra pertenece a la palabra.
- Restar intentos.
- Detectar victoria.
- Detectar derrota.
- Seleccionar la palabra.
- Administrar el tiempo.

son realizadas por la FPGA.

---

## 7.3 Separación entre control y datapath

La unidad principal se divide conceptualmente entre:

- FSM de control.
- Datapath.

La FSM administra la secuencia de operaciones mientras el datapath mantiene y modifica los datos de la partida.

Esta separación facilita el diseño RTL.

---

## 7.4 Uso de habilitaciones temporales

El diseño mantiene un único reloj principal de 100 MHz.

Las funciones que requieren menor frecuencia utilizan señales de habilitación como:

- `ce_debounce`
- `ce_1s`
- `ce_display`

Esto evita la creación de múltiples dominios de reloj.

---

## 7.5 Comunicación UART

La comunicación entre la FPGA y la computadora utiliza UART bidireccional.

La separación entre:

- UART RX.
- Banco de registros.
- Control UART.
- UART TX.

permite desacoplar la comunicación serial de la lógica principal del juego.

La aplicación Python utilizará el enlace UART únicamente para enviar las letras del jugador y mostrar la información enviada por la FPGA.

---

# 8. Estrategia de verificación

Cada módulo será validado inicialmente mediante simulación independiente.

Posteriormente se realizarán pruebas de integración entre módulos relacionados.

Se consideran principalmente las siguientes verificaciones:

| Prueba | Resultado esperado |
|---|---|
| Pulsación de `BTN_SEL` | Cambio de dificultad |
| Pulsación de `BTN_OK` | Inicio de nueva partida |
| Reset | Regreso al estado inicial |
| Selección pseudoaleatoria | Obtención de palabra válida |
| Letra correcta | Revelar todas sus apariciones |
| Letra incorrecta | Incrementar errores |
| Letra repetida | Ignorar sin penalización |
| Sexto error | Derrota |
| Tiempo igual a cero | Derrota |
| Palabra completa | Victoria |
| UART RX | Recepción correcta de letra ASCII |
| UART TX | Transmisión correcta del estado |
| Aplicación Python | Envío de letras y recepción correcta del estado |
| LCD | Presentación correcta del patrón |
| Displays | Presentación correcta del tiempo |
| Buzzer | Tono correspondiente al evento |
| LED | Indicación correcta del estado |

Los bancos de prueba deben incluir mecanismos de autoverificación para comparar automáticamente el resultado obtenido con el resultado esperado.

---

# 9. Plan de implementación

La implementación se realizará progresivamente siguiendo el orden jerárquico del diseño:

1. Generadores de habilitación temporal.
2. Sincronización y antirrebote de botones.
3. UART RX y UART TX.
4. Banco de registros UART.
5. Generador LFSR.
6. Banco ROM de palabras.
7. Registro y comparador de palabra.
8. Temporizador de partida.
9. FSM principal.
10. Datapath del juego.
11. Control de LCD.
12. Displays de siete segmentos.
13. LED de estado.
14. Generador de sonido.
15. Aplicación Python.
16. Integración del sistema completo.
17. Simulación integral.
18. Implementación y pruebas físicas.

---

# 10. Resultado esperado del planteamiento

La arquitectura propuesta busca permitir una implementación ordenada y escalable del juego de Ahorcado.

La división jerárquica mostrada en los diagramas permite pasar progresivamente desde una representación general del sistema hasta bloques suficientemente simples para ser descritos mediante SystemVerilog o implementados mediante Python en el caso de la aplicación de computadora.

La separación de funciones facilita tanto la implementación como la verificación y permite que los diferentes integrantes del equipo desarrollen módulos en paralelo manteniendo interfaces claramente definidas.
