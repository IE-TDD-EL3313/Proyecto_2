`timescale 1ns/1ps
// ============================================================================
// tb_banco_sincronizadores.sv
// Verifica reset, independencia de canales y latencia de dos etapas.
// ============================================================================
module tb_banco_sincronizadores;

    logic       clk = 1'b0;
    logic       rst_n;
    logic [2:0] btn_async;
    logic [2:0] btn_sync;

    int errores = 0;
    int pruebas = 0;

    banco_sincronizadores dut (.*);

    always #5 clk = ~clk;

    task automatic check(input bit condicion, input string mensaje);
        pruebas++;
        if (!condicion) begin
            errores++;
            $display("[FALLO] %s (t=%0t)", mensaje, $time);
        end
    endtask

    task automatic esperar_flanco();
        @(posedge clk);
        #1;
    endtask

    initial begin
        rst_n     = 1'b0;
        btn_async = 3'b111;
        #1;
        check(btn_sync == 3'b000,
              "El reset asincrono no limpio la salida");

        // La entrada se deja estable antes de liberar el reset.
        rst_n = 1'b1;

        esperar_flanco();
        check(btn_sync == 3'b000,
              "La salida cambio despues de una sola etapa");

        esperar_flanco();
        check(btn_sync == 3'b111,
              "Los tres botones no aparecieron tras dos etapas");

        // Cambia solamente BTN_OK (bit 1), fuera del flanco activo.
        @(negedge clk);
        btn_async[1] = 1'b0;

        esperar_flanco();
        check(btn_sync == 3'b111,
              "BTN_OK atraveso el sincronizador demasiado pronto");

        esperar_flanco();
        check(btn_sync == 3'b101,
              "BTN_OK no se sincronizo o altero otro canal");

        // Comprueba que los canales pueden cambiar en sentidos distintos.
        @(negedge clk);
        btn_async = 3'b010;

        esperar_flanco();
        check(btn_sync == 3'b101,
              "El bus atraveso el sincronizador en una sola etapa");

        esperar_flanco();
        check(btn_sync == 3'b010,
              "El bus sincronizado no coincide con la entrada estable");

        // El reset debe dominar sin esperar un flanco de reloj.
        @(negedge clk);
        rst_n = 1'b0;
        #1;
        check(btn_sync == 3'b000,
              "El reset asincrono final no limpio la salida");

        if (errores == 0)
            $display("\n*** TODAS LAS PRUEBAS PASARON (%0d/%0d) ***\n",
                     pruebas, pruebas);
        else
            $fatal(1, "\n*** %0d DE %0d PRUEBAS FALLARON ***\n",
                   errores, pruebas);

        $finish;
    end

endmodule
