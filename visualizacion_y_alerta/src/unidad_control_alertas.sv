module unidad_control_alertas (
    input  logic       clk_i,
    input  logic       rst_i,
    input  logic [1:0] fase_i,
    input  logic       evento_acierto_i,
    input  logic       evento_error_i,
    input  logic       evento_fin_i,
    input  logic       victoria_i,
    output logic [2:0] pantalla_sel_o,
    output logic       actualizar_lcd_o,
    output logic [1:0] tono_sel_o,
    output logic       tono_start_o,
    output logic [1:0] led_sel_o
);
    import alertas_pkg::*;

    logic [1:0] fase_anterior_q;

    always_comb begin
        pantalla_sel_o = PANTALLA_MODO;
        led_sel_o      = LED_APAGADO;
        case (fase_i)
            FASE_PARTIDA: begin
                pantalla_sel_o = PANTALLA_PARTIDA;
                led_sel_o      = LED_ENCENDIDO;
            end
            FASE_RESULTADO: begin
                pantalla_sel_o = victoria_i ? PANTALLA_VICTORIA : PANTALLA_DERROTA;
                led_sel_o      = LED_PARPADEO;
            end
            default: begin end
        endcase
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            fase_anterior_q   <= FASE_RESET;
            actualizar_lcd_o  <= 1'b0;
            tono_sel_o        <= TONO_SILENCIO;
            tono_start_o      <= 1'b0;
        end else begin
            fase_anterior_q  <= fase_i;
            // Una sola actualizacion por cambio de fase o por evento de partida.
            actualizar_lcd_o <= (fase_i != fase_anterior_q) || evento_acierto_i ||
                                evento_error_i || evento_fin_i;
            tono_start_o <= 1'b0;
            tono_sel_o   <= TONO_SILENCIO;
            // Prioridad definida para eventos simultaneos.
            if (evento_fin_i) begin
                tono_sel_o   <= TONO_FINAL;
                tono_start_o <= 1'b1;
            end else if (evento_error_i) begin
                tono_sel_o   <= TONO_ERROR;
                tono_start_o <= 1'b1;
            end else if (evento_acierto_i) begin
                tono_sel_o   <= TONO_ACIERTO;
                tono_start_o <= 1'b1;
            end
        end
    end
endmodule
