`timescale 1ns/1ps
// ============================================================================
// tb_banco_detectores_flanco.sv
// Verifica pulsos de un ciclo, botones sostenidos y flancos de bajada.
// ============================================================================
module tb_banco_detectores_flanco;

    logic       clk = 1'b0;
    logic       rst_n;
    logic [2:0] btn_stable;
    logic [2:0] btn_pulse;

    int errores = 0;
    int pruebas = 0;

    banco_detectores_flanco dut (.*);

    always #5 clk = ~clk;

    task automatic check(input bit condicion, input string mensaje);
        pruebas++;
        if (!condicion) begin
            errores++;
            $display("[FALLO] %s (t=%0t)", mensaje, $time);
        end
    endtask

    task automatic avanzar_ciclo();
        @(posedge clk);
        #1;
    endtask

    initial begin
        rst_n      = 1'b0;
        btn_stable = 3'b000;
        #1;
        check(btn_pulse == 3'b000, "Reset no limpio los pulsos");

        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        avanzar_ciclo();

        // Pulsacion individual de BTN_SEL.
        @(negedge clk);
        btn_stable[0] = 1'b1;
        avanzar_ciclo();
        check(btn_pulse == 3'b001,
              "BTN_SEL no genero pulso en el flanco de subida");

        avanzar_ciclo();
        check(btn_pulse == 3'b000,
              "BTN_SEL genero un pulso de mas de un ciclo");

        repeat (3) avanzar_ciclo();
        check(btn_pulse == 3'b000,
              "Mantener BTN_SEL presionado genero pulsos adicionales");

        // Soltar el boton no debe generar un pulso.
        @(negedge clk);
        btn_stable[0] = 1'b0;
        avanzar_ciclo();
        check(btn_pulse == 3'b000,
              "El flanco de bajada de BTN_SEL genero un pulso");

        // Dos botones pueden generar pulsos simultaneamente.
        @(negedge clk);
        btn_stable[2:1] = 2'b11;
        avanzar_ciclo();
        check(btn_pulse == 3'b110,
              "BTN_OK y BTN_RST no generaron pulsos simultaneos");

        avanzar_ciclo();
        check(btn_pulse == 3'b000,
              "Los pulsos simultaneos duraron mas de un ciclo");

        // Nueva pulsacion de BTN_SEL despues de haber sido liberado.
        @(negedge clk);
        btn_stable = 3'b001;
        avanzar_ciclo();
        check(btn_pulse == 3'b001,
              "No se detecto una segunda pulsacion de BTN_SEL");

        rst_n = 1'b0;
        #1;
        check(btn_pulse == 3'b000,
              "Reset final no limpio los pulsos inmediatamente");

        if (errores == 0)
            $display("\n*** TODAS LAS PRUEBAS PASARON (%0d/%0d) ***\n",
                     pruebas, pruebas);
        else
            $fatal(1, "\n*** %0d DE %0d PRUEBAS FALLARON ***\n",
                   errores, pruebas);

        $finish;
    end

endmodule
