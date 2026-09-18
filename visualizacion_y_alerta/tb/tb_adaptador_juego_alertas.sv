`timescale 1ns/1ps

module tb_adaptador_juego_alertas;
    import alertas_pkg::*;

    logic [1:0]  estado_juego_i;
    logic [1:0]  evento_sonido_i;
    logic        resultado_final_i;
    logic [11:0] palabra_revelada_i;
    logic [2:0]  intentos_restantes_i;
    logic [7:0]  partidas_ganadas_bcd_i;
    logic [7:0]  tiempo_restante_bcd_i;
    logic [95:0] palabra_secreta_ascii_i;
    logic [1:0]  fase_o;
    logic        evento_acierto_o, evento_error_o, evento_fin_o, victoria_o;
    logic [95:0] patron_o, palabra_secreta_o;
    logic [2:0]  errores_o;
    logic [6:0]  tiempo_o, victorias_o;

    adaptador_juego_alertas dut (.*);

    initial begin
        estado_juego_i          = 2'b10;
        evento_sonido_i         = 2'b01;
        resultado_final_i       = 1'b0;
        palabra_revelada_i      = 12'b0000_0000_0101;
        intentos_restantes_i    = 3'd4;
        partidas_ganadas_bcd_i  = 8'h12;
        tiempo_restante_bcd_i   = 8'h45;
        palabra_secreta_ascii_i = {"A", "M", "O", "R", " ", " ", " ", " ", " ", " ", " ", " "};
        #1;

        if (fase_o != FASE_PARTIDA || !evento_acierto_o || evento_error_o || evento_fin_o)
            $fatal(1, "Mapeo de fase o evento incorrecto");
        if (errores_o != 3'd2 || tiempo_o != 7'd45 || victorias_o != 7'd12)
            $fatal(1, "Conversion de datos BCD/intentos incorrecta");
        if (patron_o[95:88] != "A" || patron_o[87:80] != "_" ||
            patron_o[79:72] != "O" || patron_o[71:64] != "_")
            $fatal(1, "Formacion de patron incorrecta");

        estado_juego_i = 2'b11;
        evento_sonido_i = 2'b11;
        resultado_final_i = 1'b1;
        #1;
        if (fase_o != FASE_RESULTADO || !evento_fin_o || !victoria_o)
            $fatal(1, "Mapeo de resultado final incorrecto");

        $display("PASS: tb_adaptador_juego_alertas");
        $finish;
    end
endmodule
