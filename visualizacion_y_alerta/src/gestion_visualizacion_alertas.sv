// Nivel 3: integracion de visualizacion y alertas del juego del ahorcado.
module gestion_visualizacion_alertas (
    // Reloj y reinicio
    input  logic        clk_i,
    input  logic        rst_i,

    // Estado y eventos de la FSM principal
    input  logic [1:0]  fase_i,
    input  logic        evento_acierto_i,
    input  logic        evento_error_i,
    input  logic        evento_fin_i,
    input  logic        victoria_i,

    // Registros de la partida
    input  logic [95:0] patron_i,
    input  logic [95:0] palabra_secreta_i,
    input  logic [2:0]  errores_i,
    input  logic [6:0]  tiempo_i,
    input  logic [6:0]  victorias_i,
    input  logic        ce_display_i,

    // Perifericos integrados de la tarjeta
    output logic        buzzer_o,
    output logic        led_o,
    output logic [6:0]  seg_o,
    output logic [3:0]  an_o,

    // PmodCLP: LCD HD44780 paralelo de 8 bits
    output logic        lcd_rs_o,
    output logic        lcd_rw_o,
    output logic        lcd_e_o,
    output logic [7:0]  lcd_data_o
);

    logic [2:0]  pantalla_sel;
    logic        actualizar_lcd;
    logic [1:0]  tono_sel;
    logic        tono_start;
    logic [1:0]  led_sel;
    logic        lcd_write_enable;
    logic [1:0]  lcd_addr;
    logic [31:0] lcd_wdata;
    logic [31:0] lcd_rdata;

    unidad_control_alertas u_control_alertas (
        .clk_i            (clk_i),
        .rst_i            (rst_i),
        .fase_i           (fase_i),
        .evento_acierto_i (evento_acierto_i),
        .evento_error_i   (evento_error_i),
        .evento_fin_i     (evento_fin_i),
        .victoria_i       (victoria_i),
        .pantalla_sel_o   (pantalla_sel),
        .actualizar_lcd_o (actualizar_lcd),
        .tono_sel_o       (tono_sel),
        .tono_start_o     (tono_start),
        .led_sel_o        (led_sel)
    );

    gestion_sonido u_gestion_sonido (
        .clk_i        (clk_i),
        .rst_i        (rst_i),
        .tono_sel_i   (tono_sel),
        .tono_start_i (tono_start),
        .buzzer_o     (buzzer_o)
    );
    codificador_led u_codificador_led (
        .clk_i     (clk_i),
        .rst_i     (rst_i),
        .led_sel_i (led_sel),
        .led_o     (led_o)
    );
    driver_7seg u_driver_7seg (
        .clk_i        (clk_i),
        .rst_i        (rst_i),
        .tiempo_i     (tiempo_i),
        .victorias_i  (victorias_i),
        .ce_display_i (ce_display_i),
        .seg_o        (seg_o),
        .an_o         (an_o)
    );
    gestor_texto_lcd u_gestor_texto_lcd (
        .clk_i             (clk_i),
        .rst_i             (rst_i),
        .pantalla_sel_i    (pantalla_sel),
        .actualizar_i      (actualizar_lcd),
        .patron_i          (patron_i),
        .errores_i         (errores_i),
        .tiempo_i          (tiempo_i),
        .victorias_i       (victorias_i),
        .palabra_secreta_i (palabra_secreta_i),
        .write_enable_o    (lcd_write_enable),
        .addr_o            (lcd_addr),
        .wdata_o           (lcd_wdata),
        .rdata_i           (lcd_rdata)
    );
    lcd_16x2 u_lcd_16x2 (
        .clk_i          (clk_i),
        .rst_i          (rst_i),
        .write_enable_i (lcd_write_enable),
        .addr_i         (lcd_addr),
        .wdata_i        (lcd_wdata),
        .rdata_o        (lcd_rdata),
        .lcd_rs_o       (lcd_rs_o),
        .lcd_rw_o       (lcd_rw_o),
        .lcd_e_o        (lcd_e_o),
        .lcd_data_o     (lcd_data_o)
    );
endmodule
