// ============================================================================
// top_test_ahorcado.sv
//
// Harness de integracion para probar en la FPGA (Nexys4) los TRES bloques
// ya validados por simulacion: Gestion de Palabras, Gestion del Tiempo, y
// Control y Coordinacion del Juego.
//
// No incluye LCD. Para las entradas y el reloj utiliza el bloque definitivo
// gestion_entradas_reloj. Las letras se reciben por USB-UART desde la PC.
// En este arnes:
//   - BTNU = sel_pulse (cambia dificultad), BTNC = ok_pulse (confirma/inicia)
//   - BTND = rst_pulse (reinicia el juego)
//   - RsRx/RsTx = comunicacion USB-UART a 115200 baudios
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
    input  logic        RsRx,
    output logic        RsTx,
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

    // ---------------- Periferico UART e interfaz de registros --------------
    logic [7:0] letra_ascii;
    logic       uart_new_rx, uart_busy;
    logic       uart_we;
    logic [1:0] uart_addr;
    logic [31:0] uart_wdata, uart_rdata;
    logic       gen_we, gen_busy;
    logic [1:0] gen_addr;
    logic [31:0] gen_wdata;

    periferico_uart u_uart (
        .clk_i(clk), .rst_i(~rst_n),
        .write_enable_i(uart_we), .addr_i(uart_addr),
        .wdata_i(uart_wdata), .rdata_o(uart_rdata),
        .rx_i(RsRx), .tx_o(RsTx),
        .new_rx_o(uart_new_rx), .busy_o(uart_busy)
    );

    // Lee DATA_RX y limpia CONTROL.new_rx. Los bytes que no sean A-Z se
    // descartan sin generar nueva_letra y, por tanto, sin afectar la partida.
    typedef enum logic [1:0] {RX_ESPERA, RX_LEE, RX_LIMPIA} rx_bus_estado_t;
    rx_bus_estado_t rx_bus_estado;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_bus_estado <= RX_ESPERA;
            letra_ascii   <= 8'h00;
            nueva_letra   <= 1'b0;
        end else begin
            nueva_letra <= 1'b0;
            case (rx_bus_estado)
                RX_ESPERA:
                    if (uart_new_rx && !gen_busy) rx_bus_estado <= RX_LEE;
                RX_LEE: begin
                    if (uart_rdata[7:0] >= "A" && uart_rdata[7:0] <= "Z") begin
                        letra_ascii <= uart_rdata[7:0];
                        nueva_letra <= 1'b1;
                    end
                    rx_bus_estado <= RX_LIMPIA;
                end
                default: rx_bus_estado <= RX_ESPERA;
            endcase
        end
    end

    // El generador de tramas tiene prioridad mientras transmite. En reposo,
    // la FSM anterior utiliza el mismo bus para leer y limpiar DATA_RX.
    always_comb begin
        uart_we    = gen_we;
        uart_addr  = gen_addr;
        uart_wdata = gen_wdata;
        if (!gen_busy) begin
            case (rx_bus_estado)
                RX_LEE: begin
                    uart_we = 1'b0; uart_addr = 2'b01; uart_wdata = 32'h0;
                end
                RX_LIMPIA: begin
                    uart_we = 1'b1; uart_addr = 2'b10; uart_wdata = 32'h0;
                end
                default: ;
            endcase
        end
    end

    // ---------------- Gestion de Palabras ----------------
    logic        dificultad;
    logic        pedir_palabra;
    logic [4:0]  letra_in;
    logic        validar;
    logic [3:0]  longitud_palabra;
    logic        palabra_lista;
    logic [11:0] mask_coincidencia;
    logic [59:0] palabra_codificada;

    // La prueba fisica usa siempre AMOR para que el resultado sea repetible.
    // El diseno normal conserva el banco aleatorio porque MODO_PRUEBA vale 0.
    gestion_palabras #(
        .MODO_PRUEBA(1'b1)
    ) u_palabras (
        .clk(clk), .rst_n(rst_n), .dificultad(dificultad),
        .pedir_palabra(pedir_palabra), .letra_in(letra_in), .validar(validar),
        .longitud_palabra(longitud_palabra), .palabra_lista(palabra_lista),
        .mask_coincidencia(mask_coincidencia),
        .palabra_codificada(palabra_codificada)
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
    logic        evento_letra;
    logic [1:0]  resultado_letra, causa_final;
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
        .enviar_trama(enviar_trama), .evento_letra(evento_letra),
        .resultado_letra(resultado_letra), .causa_final(causa_final),
        .evento_sonido(evento_sonido)
    );

    // ---------------- Mensajes del juego hacia la computadora -------------
    logic [11:0] mask_para_mensaje;
    logic [95:0] patron_ascii;
    logic [2:0] intentos_para_mensaje;
    logic evento_generador, pendientes_uart;
    logic [1:0] tipo_mensaje, resultado_mensaje;
    logic modo_mensaje;
    logic [3:0] longitud_mensaje;
    logic [2:0] intentos_mensaje;
    logic [95:0] patron_mensaje;

    assign mask_para_mensaje = evento_letra
                              ? (palabra_revelada | mask_coincidencia)
                              : palabra_revelada;
    assign intentos_para_mensaje = (evento_letra && resultado_letra == 2'b10 &&
                                     intentos_restantes != 3'd0)
                                    ? intentos_restantes - 3'd1
                                    : intentos_restantes;

    formador_patron_ascii u_patron (
        .palabra_codificada_i(palabra_codificada),
        .palabra_revelada_i(mask_para_mensaje),
        .longitud_i(longitud_palabra), .patron_ascii_o(patron_ascii)
    );

    coordinador_eventos_uart u_eventos_uart (
        .clk_i(clk), .rst_i(~rst_n),
        .inicio_i(palabra_lista), .letra_i(evento_letra), .final_i(enviar_trama),
        .modo_i(dificultad), .longitud_i(longitud_palabra),
        .resultado_letra_i(resultado_letra), .causa_final_i(causa_final),
        .intentos_i(intentos_para_mensaje), .patron_ascii_i(patron_ascii),
        .generador_busy_i(gen_busy), .evento_o(evento_generador),
        .tipo_o(tipo_mensaje), .modo_o(modo_mensaje),
        .longitud_o(longitud_mensaje), .resultado_o(resultado_mensaje),
        .intentos_o(intentos_mensaje), .patron_ascii_o(patron_mensaje),
        .pendientes_o(pendientes_uart)
    );

    generador_tramas_uart u_tramas_uart (
        .clk_i(clk), .rst_i(~rst_n), .evento_i(evento_generador),
        .tipo_i(tipo_mensaje), .modo_i(modo_mensaje),
        .longitud_i(longitud_mensaje), .resultado_i(resultado_mensaje),
        .intentos_i(intentos_mensaje), .patron_ascii_i(patron_mensaje),
        .uart_rdata_i(uart_rdata), .uart_write_enable_o(gen_we),
        .uart_addr_o(gen_addr), .uart_wdata_o(gen_wdata), .busy_o(gen_busy)
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
