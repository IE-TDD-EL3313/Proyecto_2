`timescale 1ns/1ps

module tb_coordinador_eventos_uart;
    logic clk_i = 0, rst_i = 1;
    logic inicio_i = 0, letra_i = 0, final_i = 0;
    logic modo_i = 0, generador_busy_i = 0;
    logic [3:0] longitud_i = 4;
    logic [1:0] resultado_letra_i = 1, causa_final_i = 1;
    logic [2:0] intentos_i = 6;
    logic [95:0] patron_ascii_i = '0;
    logic evento_o, modo_o, pendientes_o;
    logic [1:0] tipo_o, resultado_o;
    logic [3:0] longitud_o;
    logic [2:0] intentos_o;
    logic [95:0] patron_ascii_o;
    int pruebas = 0;

    always #5 clk_i = ~clk_i;
    coordinador_eventos_uart dut (.*);

    task automatic comprobar(input logic condicion, input string mensaje);
        pruebas++;
        if (!condicion) begin $error("FALLO: %s", mensaje); $finish; end
    endtask

    initial begin
        repeat (2) @(posedge clk_i); rst_i = 0;

        @(negedge clk_i); inicio_i = 1;
        @(negedge clk_i); inicio_i = 0;
        #1 comprobar(evento_o && tipo_o == 2'b00, "debe entregar inicio");
        @(posedge clk_i); #1;

        generador_busy_i = 1;
        @(negedge clk_i); letra_i = 1; final_i = 1;
        patron_ascii_i = {{8{" "}}, "AMOR"};
        @(negedge clk_i); letra_i = 0; final_i = 0;
        comprobar(pendientes_o && !evento_o, "debe guardar letra y final mientras esta ocupado");

        generador_busy_i = 0; #1;
        comprobar(evento_o && tipo_o == 2'b01 && resultado_o == 2'b01,
                  "la letra debe salir primero");
        @(posedge clk_i); #1;
        generador_busy_i = 1;
        @(posedge clk_i); generador_busy_i = 0; #1;
        comprobar(evento_o && tipo_o == 2'b10 && resultado_o == 2'b01,
                  "el resultado final debe salir despues");
        @(posedge clk_i); #1;
        comprobar(!pendientes_o, "no deben quedar mensajes pendientes");

        $display("OK: coordinador UART completo, %0d pruebas superadas", pruebas);
        $finish;
    end
endmodule
