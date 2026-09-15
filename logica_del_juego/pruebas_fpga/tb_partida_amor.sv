`timescale 1ns/1ps

module tb_partida_amor;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    always #5 clk = ~clk;

    logic sel_pulse = 1'b0;
    logic ok_pulse = 1'b0;
    logic rst_pulse = 1'b0;
    logic tick_1s = 1'b0;
    logic [7:0] letra_ascii = 8'd0;
    logic nueva_letra = 1'b0;
    logic palabra_lista;
    logic [3:0] longitud_palabra;
    logic [11:0] mask_coincidencia;
    logic pedir_palabra;
    logic [4:0] letra_in;
    logic validar;
    logic tiempo_activo;
    logic dificultad;
    logic [1:0] estado_juego;
    logic [11:0] palabra_revelada;
    logic [2:0] intentos_restantes;
    logic resultado_final;
    logic [7:0] partidas_ganadas_bcd;
    logic enviar_trama;
    logic [1:0] evento_sonido;

    gestion_palabras #(.MODO_PRUEBA(1'b1)) u_palabras (
        .clk(clk), .rst_n(rst_n), .dificultad(dificultad),
        .pedir_palabra(pedir_palabra), .letra_in(letra_in), .validar(validar),
        .longitud_palabra(longitud_palabra), .palabra_lista(palabra_lista),
        .mask_coincidencia(mask_coincidencia)
    );

    control_coordinacion u_control (
        .clk(clk), .rst_n(rst_n), .tick_1s(tick_1s),
        .sel_pulse(sel_pulse), .ok_pulse(ok_pulse), .rst_pulse(rst_pulse),
        .letra_ascii(letra_ascii), .nueva_letra(nueva_letra),
        .palabra_lista(palabra_lista), .longitud_palabra(longitud_palabra),
        .mask_coincidencia(mask_coincidencia),
        .pedir_palabra(pedir_palabra), .letra_in(letra_in), .validar(validar),
        .tiempo_agotado(1'b0), .tiempo_activo(tiempo_activo),
        .dificultad(dificultad), .estado_juego(estado_juego),
        .palabra_revelada(palabra_revelada),
        .intentos_restantes(intentos_restantes), .resultado_final(resultado_final),
        .partidas_ganadas_bcd(partidas_ganadas_bcd),
        .enviar_trama(enviar_trama), .evento_sonido(evento_sonido)
    );

    task automatic enviar(input logic [7:0] letra);
        begin
            letra_ascii = letra;
            nueva_letra = 1'b1;
            @(posedge clk); #1;
            nueva_letra = 1'b0;
            @(posedge clk); #1;
        end
    endtask

    task automatic comprobar(input logic condicion, input string mensaje);
        if (!condicion) begin
            $error("FALLO: %s", mensaje);
            $finish;
        end
    endtask

    initial begin
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk); #1;

        ok_pulse = 1'b1;
        @(posedge clk); #1;
        ok_pulse = 1'b0;
        wait (estado_juego == 2'b10);
        #1;
        comprobar(longitud_palabra == 4'd4, "AMOR debe tener cuatro letras");

        enviar("A");
        comprobar(palabra_revelada == 12'h001, "debe revelar A");
        enviar("M");
        comprobar(palabra_revelada == 12'h003, "debe revelar M");
        enviar("O");
        comprobar(palabra_revelada == 12'h007, "debe revelar O");
        enviar("R");
        comprobar(palabra_revelada == 12'h00F, "debe revelar R");
        comprobar(estado_juego == 2'b11, "debe terminar la partida");
        comprobar(resultado_final == 1'b1, "el resultado debe ser victoria");

        @(posedge clk); #1;
        comprobar(partidas_ganadas_bcd == 8'h01, "debe contar una victoria");
        $display("OK: AMOR termina la partida y registra la victoria");
        $finish;
    end
endmodule
