// ============================================================================
// unidad_control.sv
//
// FSM principal de 5 estados: SEL_MODO, CARGANDO, JUGANDO, VALIDANDO,
// FIN_PARTIDA. Decide UNICAMENTE con base en condiciones de 1 bit (pulsos y
// "flags"); nunca examina un bus de datos directamente.
//
// AJUSTES respecto al documento de nivel 4 (necesarios al bajar a RTL):
//
// 1) "enviar_trama" se separa de "cmd": en el ciclo en que la partida
//    termina, la Unidad de Control necesita a la vez (a) confirmar el
//    ultimo acierto/error en el datapath (cmd=carga_letra o
//    incrementa_intento) y (b) avisar que hay que transmitir el resultado.
//    Con un solo bus "cmd" de 3 bits no se pueden codificar ambas acciones
//    en el mismo ciclo, asi que "enviar_trama" pasa a ser una salida
//    independiente de 1 bit.
//
// 2) Se agrega una transicion directa JUGANDO -> FIN_PARTIDA cuando
//    tiempo_agotado=1, sin esperar a que llegue una letra. En el diagrama
//    de nivel 4 solo se revisaba tiempo_agotado dentro de VALIDANDO, lo cual
//    dejaria la FSM atascada en JUGANDO si el tiempo se agota mientras nadie
//    envia una letra.
//
// 3) cmd=incrementa_ganadas se emite exactamente 1 ciclo (usando el registro
//    "ganancia_pendiente"), evitando incrementar el contador de partidas
//    ganadas mas de una vez mientras se permanece en FIN_PARTIDA.
// ============================================================================
module unidad_control (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       sel_pulse,
    input  logic       ok_pulse,
    input  logic       rst_pulse,
    input  logic       nueva_letra,
    input  logic       palabra_lista,
    input  logic       tiempo_agotado,
    input  logic [3:0] flags,          // {agotados, completa, repetida, acierto}
    input  logic       tick_1s,
    output logic       pedir_palabra,
    output logic       validar,
    output logic       tiempo_activo,
    output logic [1:0] estado_juego,
    output logic       resultado_final,   // 1=victoria, 0=derrota (valido en FIN_PARTIDA)
    output logic       enviar_trama,
    output logic       evento_letra,
    output logic [1:0] resultado_letra,   // 01 acierto, 10 error, 11 repetida
    output logic [1:0] causa_final,       // 01 victoria, 10 intentos, 11 tiempo
    output logic [1:0] evento_sonido,     // 00 nada, 01 acierto, 10 error, 11 fin
    output logic [2:0] cmd
);
    typedef enum logic [2:0] {SEL_MODO, CARGANDO, JUGANDO, VALIDANDO, FIN_PARTIDA} estado_t;
    estado_t estado, estado_next;

    localparam logic [2:0]
        CMD_NADA    = 3'b000,
        CMD_CARGA   = 3'b001,
        CMD_INTENTO = 3'b010,
        CMD_GANADAS = 3'b011,
        CMD_LIMPIA  = 3'b100;

    wire hay_acierto       = flags[0];
    wire letra_repetida    = flags[1];
    wire palabra_completa  = flags[2];
    wire intentos_agotados = flags[3];

    logic [1:0] contador_despliegue;
    logic       ganancia_pendiente;

    // ---------------- Registro de estado ----------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)          estado <= SEL_MODO;
        else if (rst_pulse)  estado <= SEL_MODO;      // prioridad maxima
        else                 estado <= estado_next;
    end

    // ---------------- Contador de despliegue (3 s en FIN_PARTIDA) --------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || rst_pulse)
            contador_despliegue <= 2'd0;
        else if (estado != FIN_PARTIDA)
            contador_despliegue <= 2'd0;
        else if (tick_1s && contador_despliegue != 2'd3)
            contador_despliegue <= contador_despliegue + 2'd1;
    end

    // ---------------- Registro de resultado (para LCD / Visualizacion) ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            resultado_final    <= 1'b0;
            ganancia_pendiente <= 1'b0;
        end else if (estado == VALIDANDO && palabra_completa) begin
            resultado_final    <= 1'b1;
            ganancia_pendiente <= 1'b1;
        end else if (estado == VALIDANDO && !hay_acierto && !letra_repetida &&
                     (intentos_agotados || tiempo_agotado)) begin
            resultado_final <= 1'b0;
        end else if (estado == JUGANDO && tiempo_agotado) begin
            resultado_final <= 1'b0;
        end else if (estado == FIN_PARTIDA) begin
            ganancia_pendiente <= 1'b0; // se consume 1 ciclo despues de entrar
        end
    end

    // ---------------- Logica de proximo estado y salidas ------------------
    always_comb begin
        // valores por defecto
        estado_next    = estado;
        pedir_palabra   = 1'b0;
        validar         = 1'b0;
        tiempo_activo   = (estado == JUGANDO) || (estado == VALIDANDO);
        evento_sonido   = 2'b00;
        cmd             = CMD_NADA;
        enviar_trama    = 1'b0;
        evento_letra    = 1'b0;
        resultado_letra = 2'b00;
        causa_final     = 2'b00;

        case (estado)
            SEL_MODO: begin
                if (ok_pulse) begin
                    estado_next = CARGANDO;
                    cmd         = CMD_LIMPIA;
                end
            end

            CARGANDO: begin
                pedir_palabra = 1'b1;
                if (palabra_lista)
                    estado_next = JUGANDO;
            end

            JUGANDO: begin
                if (tiempo_agotado) begin
                    // ajuste (2): el tiempo puede agotarse sin que llegue letra
                    estado_next   = FIN_PARTIDA;
                    evento_sonido = 2'b11;
                    enviar_trama  = 1'b1;
                    causa_final   = 2'b11;
                end else if (nueva_letra) begin
                    validar     = 1'b1;
                    estado_next = VALIDANDO;
                end
            end

            VALIDANDO: begin
                evento_letra = 1'b1;
                if (palabra_completa) begin
                    cmd           = CMD_CARGA;    // revela la ultima letra
                    evento_sonido = 2'b11;
                    enviar_trama  = 1'b1;
                    resultado_letra = 2'b01;
                    causa_final     = 2'b01;
                    estado_next   = FIN_PARTIDA;
                end else if (letra_repetida) begin
                    cmd           = CMD_NADA;      // se ignora, sin penalizar
                    evento_sonido = 2'b00;
                    resultado_letra = 2'b11;
                    estado_next   = JUGANDO;
                end else if (hay_acierto) begin
                    cmd           = CMD_CARGA;
                    evento_sonido = 2'b01;
                    resultado_letra = 2'b01;
                    estado_next   = JUGANDO;
                end else begin
                    // error: se comete siempre (cmd=CMD_INTENTO), y ademas
                    // termina la partida si intentos_agotados o tiempo_agotado
                    cmd = CMD_INTENTO;
                    resultado_letra = 2'b10;
                    if (intentos_agotados || tiempo_agotado) begin
                        evento_sonido = 2'b11;
                        enviar_trama  = 1'b1;
                        causa_final   = tiempo_agotado ? 2'b11 : 2'b10;
                        estado_next   = FIN_PARTIDA;
                    end else begin
                        evento_sonido = 2'b10;
                        estado_next   = JUGANDO;
                    end
                end
            end

            FIN_PARTIDA: begin
                if (ganancia_pendiente)
                    cmd = CMD_GANADAS; // exactamente 1 ciclo (ver ajuste 3)
                if (contador_despliegue == 2'd3)
                    estado_next = SEL_MODO;
            end

            default: estado_next = SEL_MODO;
        endcase
    end

    // ---------------- Codificacion de estado_juego (2 bits, nivel 3/4) ----
    // VALIDANDO se reporta externamente como JUGANDO (10): es un estado
    // interno de 1 ciclo, no visible para Visualizacion.
    always_comb begin
        case (estado)
            SEL_MODO:    estado_juego = 2'b00;
            CARGANDO:    estado_juego = 2'b01;
            FIN_PARTIDA: estado_juego = 2'b11;
            default:     estado_juego = 2'b10; // JUGANDO o VALIDANDO
        endcase
    end

endmodule
