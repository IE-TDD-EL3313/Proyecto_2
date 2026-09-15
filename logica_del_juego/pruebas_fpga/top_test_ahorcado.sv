// ============================================================================
// top_test_ahorcado.sv
//
// Harness de integracion para probar en la FPGA (Nexys4) los TRES bloques
// ya validados por simulacion: Gestion de Palabras, Gestion del Tiempo, y
// Control y Coordinacion del Juego.
//
// No incluye UART ni LCD. Para las entradas y el reloj utiliza el bloque
// definitivo gestion_entradas_reloj. En este arnes:
//   - "letra" a adivinar: se ingresa con sw[4:0] (codigo 1-26, A=00001) y
//     se envia con BTNR (pulso "nueva_letra").
//   - BTNU = sel_pulse (cambia dificultad), BTNC = ok_pulse (confirma/inicia)
//   - BTND = rst_pulse (reinicia el juego)
//   - CPU_RESETN = reset electronico activo en bajo
//   - LEDs: ver mapeo abajo.
//   - 7 segmentos: 2 digitos de tiempo restante + 2 digitos de partidas
//     ganadas (igual que pide la especificacion final del proyecto).
// ============================================================================
module top_test_ahorcado (
    input  logic        clk,          // 100 MHz (E3)
    input  logic        btnCpuReset,  // CPU_RESETN: activo en BAJO
    input  logic        btnC,
    input  logic        btnU,
    input  logic        btnD,
    input  logic        btnR,
    input  logic [4:0]  sw,           // sw[4:0]: codigo de letra 1-26
    output logic [9:0]  led,
    output logic [6:0]  seg,
    output logic [7:0]  an,
    output logic        dp
);
    logic rst_n;
    assign rst_n = btnCpuReset;
    assign dp    = 1'b1; // apagado (activo en bajo)

    // ---------------- Entradas locales y reloj definitivos --------------
    logic ok_pulse, sel_pulse, rst_pulse, nueva_letra;
    logic tick_1s, ce_debounce, ce_display;

    entradas_reloj u_entradas_reloj (
        .clk         (clk),
        .rst_n       (rst_n),
        .btn_sel_i   (btnU),
        .btn_ok_i    (btnC),
        .btn_rst_i   (btnD),
        .sel_pulse   (sel_pulse),
        .ok_pulse    (ok_pulse),
        .rst_pulse   (rst_pulse),
        .ce_debounce (ce_debounce),
        .ce_1s       (tick_1s),
        .ce_display  (ce_display)
    );

    // BTNR solo sustituye la futura recepcion UART durante esta prueba.
    boton_pulso u_btn_let (.clk(clk), .rst_n(rst_n), .boton_raw(btnR), .pulso(nueva_letra));

    // codigo de switch (1-26) -> ASCII, para alimentar letra_ascii
    logic [7:0] letra_ascii;
    assign letra_ascii = (sw != 5'd0 && sw <= 5'd26) ? (8'd64 + {3'b000, sw}) : 8'd0;

    // ---------------- Gestion de Palabras ----------------
    logic        dificultad;
    logic        pedir_palabra;
    logic [4:0]  letra_in;
    logic        validar;
    logic [3:0]  longitud_palabra;
    logic        palabra_lista;
    logic [11:0] mask_coincidencia;

    // La prueba fisica usa siempre AMOR para que el resultado sea repetible.
    // El diseno normal conserva el banco aleatorio porque MODO_PRUEBA vale 0.
    gestion_palabras #(
        .MODO_PRUEBA(1'b1)
    ) u_palabras (
        .clk(clk), .rst_n(rst_n), .dificultad(dificultad),
        .pedir_palabra(pedir_palabra), .letra_in(letra_in), .validar(validar),
        .longitud_palabra(longitud_palabra), .palabra_lista(palabra_lista),
        .mask_coincidencia(mask_coincidencia)
    );

    // ---------------- Gestion del Tiempo ----------------
    logic       tiempo_activo;
    logic [7:0] tiempo_restante_bcd;
    logic       tiempo_agotado;

    temporizador_partida u_tiempo (
        .clk(clk), .rst_n(rst_n), .tick_1s(tick_1s), .dificultad(dificultad),
        .tiempo_activo(tiempo_activo),
        .tiempo_restante_bcd(tiempo_restante_bcd), .tiempo_agotado(tiempo_agotado)
    );

    // ---------------- Control y Coordinacion ----------------
    logic [1:0]  estado_juego;
    logic [11:0] palabra_revelada;
    logic [2:0]  intentos_restantes;
    logic        resultado_final;
    logic [7:0]  partidas_ganadas_bcd;
    logic        enviar_trama;
    logic [1:0]  evento_sonido;

    control_coordinacion u_control (
        .clk(clk), .rst_n(rst_n), .tick_1s(tick_1s),
        .sel_pulse(sel_pulse), .ok_pulse(ok_pulse), .rst_pulse(rst_pulse),
        .letra_ascii(letra_ascii), .nueva_letra(nueva_letra),
        .palabra_lista(palabra_lista), .longitud_palabra(longitud_palabra),
        .mask_coincidencia(mask_coincidencia),
        .pedir_palabra(pedir_palabra), .letra_in(letra_in), .validar(validar),
        .tiempo_agotado(tiempo_agotado), .tiempo_activo(tiempo_activo),
        .dificultad(dificultad), .estado_juego(estado_juego),
        .palabra_revelada(palabra_revelada),
        .intentos_restantes(intentos_restantes),
        .resultado_final(resultado_final),
        .partidas_ganadas_bcd(partidas_ganadas_bcd),
        .enviar_trama(enviar_trama), .evento_sonido(evento_sonido)
    );

    // ---------------- LEDs de diagnostico ----------------
    assign led[1:0] = estado_juego;             // 00 sel,01 carga,10 juega,11 fin
    assign led[2]   = dificultad;                // 0 facil, 1 dificil
    assign led[3]   = palabra_lista;
    assign led[4]   = tiempo_agotado;
    assign led[5]   = resultado_final;
    assign led[6]   = enviar_trama;
    assign led[8:7] = evento_sonido;
    assign led[9]   = |mask_coincidencia;         // hay_acierto de la ultima letra

    // ---------------- 7 segmentos: tiempo + partidas ganadas ----------------
    logic [3:0] digitos [0:3];
    assign digitos[0] = tiempo_restante_bcd[3:0];
    assign digitos[1] = tiempo_restante_bcd[7:4];
    assign digitos[2] = partidas_ganadas_bcd[3:0];
    assign digitos[3] = partidas_ganadas_bcd[7:4];

    seg7_mux_driver u_seg (.clk(clk), .rst_n(rst_n), .digitos(digitos), .seg(seg), .an(an));

endmodule
