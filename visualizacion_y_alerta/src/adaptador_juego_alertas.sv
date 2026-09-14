// Adapta la interfaz de Control y Coordinacion del Juego a la interfaz de
// Gestion y Visualizacion de Alertas. No contiene logica de periféricos.
module adaptador_juego_alertas (
    // Desde control_coordinacion.sv
    input  logic [1:0]  estado_juego_i,
    input  logic [1:0]  evento_sonido_i,
    input  logic        resultado_final_i,
    input  logic [11:0] palabra_revelada_i,
    input  logic [2:0]  intentos_restantes_i,
    input  logic [7:0]  partidas_ganadas_bcd_i,

    // Desde temporizador_partida.sv
    input  logic [7:0]  tiempo_restante_bcd_i,

    // Debe ser expuesta por Gestion de Palabras. Caracter 0 en [95:88].
    input  logic [95:0] palabra_secreta_ascii_i,

    // Hacia gestion_visualizacion_alertas.sv
    output logic [1:0]  fase_o,
    output logic        evento_acierto_o,
    output logic        evento_error_o,
    output logic        evento_fin_o,
    output logic        victoria_o,
    output logic [95:0] patron_o,
    output logic [2:0]  errores_o,
    output logic [6:0]  tiempo_o,
    output logic [6:0]  victorias_o,
    output logic [95:0] palabra_secreta_o
);
    import alertas_pkg::*;

    integer indice;

    // always @(*) se usa aqui por compatibilidad con Icarus Verilog: algunas
    // versiones advierten con always_comb al usar part-selects en el patron.
    always @(*) begin
        // CARGANDO se presenta como seleccion mientras se carga la palabra.
        case (estado_juego_i)
            2'b00,
            2'b01: fase_o = FASE_SELECCION;
            2'b10: fase_o = FASE_PARTIDA;
            default: fase_o = FASE_RESULTADO;
        endcase

        evento_acierto_o = (evento_sonido_i == 2'b01);
        evento_error_o   = (evento_sonido_i == 2'b10);
        evento_fin_o     = (evento_sonido_i == 2'b11);
        victoria_o       = resultado_final_i;

        // Los BCD del compañero representan valores de 00 a 99.
        tiempo_o    = (tiempo_restante_bcd_i[7:4] * 7'd10) + tiempo_restante_bcd_i[3:0];
        victorias_o = (partidas_ganadas_bcd_i[7:4] * 7'd10) + partidas_ganadas_bcd_i[3:0];

        if (intentos_restantes_i <= 3'd6)
            errores_o = 3'd6 - intentos_restantes_i;
        else
            errores_o = 3'd0;

        palabra_secreta_o = palabra_secreta_ascii_i;
        for (indice = 0; indice < 12; indice = indice + 1) begin
            if (palabra_revelada_i[indice])
                patron_o[95 - (indice * 8) -: 8] = palabra_secreta_ascii_i[95 - (indice * 8) -: 8];
            else
                patron_o[95 - (indice * 8) -: 8] = "_";
        end
    end
endmodule
