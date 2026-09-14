// Puente de nivel 2 entre los bloques del juego y Gestion y Visualizacion
// de Alertas. rst_n_i respeta la convencion de control_coordinacion.
module integracion_juego_alertas (
    input  logic        clk_i,
    input  logic        rst_n_i,
    input  logic [1:0]  estado_juego_i,
    input  logic [1:0]  evento_sonido_i,
    input  logic        resultado_final_i,
    input  logic [11:0] palabra_revelada_i,
    input  logic [2:0]  intentos_restantes_i,
    input  logic [7:0]  partidas_ganadas_bcd_i,
    input  logic [7:0]  tiempo_restante_bcd_i,
    input  logic [95:0] palabra_secreta_ascii_i,
    input  logic        ce_display_i,

    output logic        buzzer_o,
    output logic        led_o,
    output logic [6:0]  seg_o,
    output logic [3:0]  an_o,
    output logic        lcd_rs_o,
    output logic        lcd_rw_o,
    output logic        lcd_e_o,
    output logic [7:0]  lcd_data_o
);
    logic rst_alertas;
    logic [1:0] fase_alertas;
    logic evento_acierto, evento_error, evento_fin, victoria;
    logic [95:0] patron, palabra_secreta;
    logic [2:0] errores;
    logic [6:0] tiempo, victorias;

    assign rst_alertas = ~rst_n_i;

    adaptador_juego_alertas u_adaptador_juego_alertas (
        .estado_juego_i         (estado_juego_i),
        .evento_sonido_i        (evento_sonido_i),
        .resultado_final_i      (resultado_final_i),
        .palabra_revelada_i     (palabra_revelada_i),
        .intentos_restantes_i   (intentos_restantes_i),
        .partidas_ganadas_bcd_i (partidas_ganadas_bcd_i),
        .tiempo_restante_bcd_i  (tiempo_restante_bcd_i),
        .palabra_secreta_ascii_i(palabra_secreta_ascii_i),
        .fase_o                 (fase_alertas),
        .evento_acierto_o       (evento_acierto),
        .evento_error_o         (evento_error),
        .evento_fin_o           (evento_fin),
        .victoria_o             (victoria),
        .patron_o               (patron),
        .errores_o              (errores),
        .tiempo_o               (tiempo),
        .victorias_o            (victorias),
        .palabra_secreta_o      (palabra_secreta)
    );

    gestion_visualizacion_alertas u_gestion_visualizacion_alertas (
        .clk_i             (clk_i),
        .rst_i             (rst_alertas),
        .fase_i            (fase_alertas),
        .evento_acierto_i  (evento_acierto),
        .evento_error_i    (evento_error),
        .evento_fin_i      (evento_fin),
        .victoria_i        (victoria),
        .patron_i          (patron),
        .palabra_secreta_i (palabra_secreta),
        .errores_i         (errores),
        .tiempo_i          (tiempo),
        .victorias_i       (victorias),
        .ce_display_i      (ce_display_i),
        .buzzer_o          (buzzer_o),
        .led_o             (led_o),
        .seg_o             (seg_o),
        .an_o              (an_o),
        .lcd_rs_o          (lcd_rs_o),
        .lcd_rw_o          (lcd_rw_o),
        .lcd_e_o           (lcd_e_o),
        .lcd_data_o        (lcd_data_o)
    );
endmodule
