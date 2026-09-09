`timescale 1ns/1ps
// ============================================================================
// tb_temporizador_partida.sv
// ============================================================================
module tb_temporizador_partida;

    logic       clk = 0;
    logic       rst_n;
    logic       tick_1s;
    logic       dificultad;
    logic       tiempo_activo;
    logic [7:0] tiempo_restante_bcd;
    logic       tiempo_agotado;

    int errores = 0, pruebas = 0;

    temporizador_partida dut (.*);

    always #5 clk = ~clk; // 100 MHz

    task automatic check(input bit cond, input string msg);
        pruebas++;
        if (!cond) begin
            errores++;
            $display("[FALLO] %s (t=%0t)", msg, $time);
        end
    endtask

    task automatic pulso_tick();
        tick_1s = 1'b1;
        @(posedge clk); #1;
        tick_1s = 1'b0;
        @(posedge clk); #1;
    endtask

    initial begin
        rst_n = 0; tick_1s = 0; dificultad = 0; tiempo_activo = 0;
        repeat (3) @(posedge clk); #1;
        rst_n = 1;
        @(posedge clk); #1;

        // --- Prueba 1: Facil carga 60 ---
        dificultad = 0;
        tiempo_activo = 1'b1;
        @(posedge clk); #1;
        check(tiempo_restante_bcd == 8'h60, "Facil no cargo 60 al activar");

        // Decrementa 5 veces
        repeat (5) pulso_tick();
        check(tiempo_restante_bcd == 8'h55, "Facil: despues de 5 ticks deberia estar en 55");

        // Apagar y reactivar en Dificil
        tiempo_activo = 1'b0;
        @(posedge clk); #1;
        check(tiempo_agotado == 1'b0, "tiempo_agotado no deberia estar activo aun");

        dificultad = 1;
        tiempo_activo = 1'b1;
        @(posedge clk); #1;
        check(tiempo_restante_bcd == 8'h45, "Dificil no cargo 45 al activar");

        // --- Prueba 2: llegar a 0 y verificar que se queda en 0 y no regresa
        //     a IDLE por si solo ---
        repeat (45) pulso_tick();
        check(tiempo_restante_bcd == 8'h00, "No llego a 0 tras 45 ticks en Dificil");
        check(tiempo_agotado == 1'b1, "tiempo_agotado no se activo al llegar a 0");

        // Un tick mas no debe hacer nada raro (se queda en 0)
        pulso_tick();
        check(tiempo_restante_bcd == 8'h00, "Se salio de 0 tras un tick adicional");
        check(tiempo_agotado == 1'b1, "tiempo_agotado se desactivo estando en 0");

        // Solo tiempo_activo=0 debe regresar a IDLE
        tiempo_activo = 1'b0;
        @(posedge clk); #1;
        check(tiempo_agotado == 1'b0, "tiempo_agotado sigue activo tras bajar tiempo_activo");

        if (errores == 0)
            $display("\n*** TODAS LAS PRUEBAS PASARON (%0d/%0d) ***\n", pruebas, pruebas);
        else
            $display("\n*** %0d DE %0d PRUEBAS FALLARON ***\n", errores, pruebas);

        $finish;
    end
endmodule
