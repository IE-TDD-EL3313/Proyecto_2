// ============================================================================
// control_coordinacion.sv
// Integra Registro de Modo + Unidad de Control (FSM) + Datapath del juego.
// ============================================================================
module control_coordinacion (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        tick_1s,
    // --- Gestion de entradas locales ---
    input  logic        sel_pulse,
    input  logic        ok_pulse,
    input  logic        rst_pulse,
    // --- Comunicacion con la PC ---
    input  logic [7:0]  letra_ascii,
    input  logic        nueva_letra,
    // --- Gestion de Palabras ---
    input  logic        palabra_lista,
    input  logic [3:0]  longitud_palabra,
    input  logic [11:0] mask_coincidencia,
    output logic        pedir_palabra,
    output logic [4:0]  letra_in,
    output logic        validar,
    // --- Gestion del Tiempo ---
    input  logic        tiempo_agotado,
    output logic        tiempo_activo,
    // --- Salidas generales ---
    output logic        dificultad,
    output logic [1:0]  estado_juego,
    output logic [11:0] palabra_revelada,
    output logic [2:0]  intentos_restantes,
    output logic        resultado_final,
    output logic [7:0]  partidas_ganadas_bcd,
    output logic        enviar_trama,
    output logic        evento_letra,
    output logic [1:0]  resultado_letra,
    output logic [1:0]  causa_final,
    output logic [1:0]  evento_sonido
);
    logic [2:0] cmd;
    logic [3:0] flags;

    registro_modo u_modo (
        .clk(clk), .rst_n(rst_n),
        .sel_pulse(sel_pulse), .rst_pulse(rst_pulse),
        .dificultad(dificultad)
    );

    unidad_control u_fsm (
        .clk(clk), .rst_n(rst_n),
        .sel_pulse(sel_pulse), .ok_pulse(ok_pulse), .rst_pulse(rst_pulse),
        .nueva_letra(nueva_letra), .palabra_lista(palabra_lista),
        .tiempo_agotado(tiempo_agotado), .flags(flags), .tick_1s(tick_1s),
        .pedir_palabra(pedir_palabra), .validar(validar),
        .tiempo_activo(tiempo_activo), .estado_juego(estado_juego),
        .resultado_final(resultado_final), .enviar_trama(enviar_trama),
        .evento_letra(evento_letra), .resultado_letra(resultado_letra),
        .causa_final(causa_final),
        .evento_sonido(evento_sonido), .cmd(cmd)
    );

    datapath_juego u_datapath (
        .clk(clk), .rst_n(rst_n),
        .letra_ascii(letra_ascii), .mask_coincidencia(mask_coincidencia),
        .longitud_palabra(longitud_palabra), .cmd(cmd),
        .flags(flags), .letra_in(letra_in),
        .palabra_revelada(palabra_revelada),
        .intentos_restantes(intentos_restantes),
        .partidas_ganadas_bcd(partidas_ganadas_bcd)
    );

endmodule
