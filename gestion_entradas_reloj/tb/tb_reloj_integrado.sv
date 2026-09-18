`timescale 1ns/1ps
// ============================================================================
// tb_reloj_integrado.sv
// Prueba autoverificable con frecuencias pequenas para acelerar la simulacion.
// ============================================================================
module tb_reloj_integrado;

    localparam int unsigned CLK_HZ_TB      = 100;
    localparam int unsigned DEBOUNCE_HZ_TB = 10; // pulso cada 10 ciclos
    localparam int unsigned DISPLAY_HZ_TB  = 20; // pulso cada 5 ciclos

    logic clk = 1'b0;
    logic rst_n;
    logic ce_debounce;
    logic ce_1s;
    logic ce_display;

    int errores = 0;
    int pruebas = 0;
    int ciclos_desde_reset;
    int pulsos_debounce;
    int pulsos_1s;
    int pulsos_display;

    reloj_integrado #(
        .CLK_HZ      (CLK_HZ_TB),
        .DEBOUNCE_HZ (DEBOUNCE_HZ_TB),
        .DISPLAY_HZ  (DISPLAY_HZ_TB)
    ) dut (.*);

    always #5 clk = ~clk;

    task automatic check(input bit condicion, input string mensaje);
        pruebas++;
        if (!condicion) begin
            errores++;
            $display("[FALLO] %s (ciclo=%0d, t=%0t)",
                     mensaje, ciclos_desde_reset, $time);
        end
    endtask

    initial begin
        rst_n              = 1'b0;
        ciclos_desde_reset = 0;
        pulsos_debounce    = 0;
        pulsos_1s          = 0;
        pulsos_display     = 0;

        repeat (3) @(posedge clk);
        #1;
        check(!ce_debounce && !ce_1s && !ce_display,
              "Las salidas deben permanecer en cero durante reset");

        rst_n = 1'b1;

        repeat (200) begin
            @(posedge clk);
            #1;
            ciclos_desde_reset++;

            // Cada habilitacion debe aparecer solo en el multiplo esperado.
            check(ce_debounce == ((ciclos_desde_reset % 10) == 0),
                  "Periodo incorrecto de ce_debounce");
            check(ce_display == ((ciclos_desde_reset % 5) == 0),
                  "Periodo incorrecto de ce_display");
            check(ce_1s == ((ciclos_desde_reset % 100) == 0),
                  "Periodo incorrecto de ce_1s");

            if (ce_debounce) pulsos_debounce++;
            if (ce_display)  pulsos_display++;
            if (ce_1s)       pulsos_1s++;
        end

        check(pulsos_debounce == 20,
              "Cantidad incorrecta de pulsos de debounce");
        check(pulsos_display == 40,
              "Cantidad incorrecta de pulsos de display");
        check(pulsos_1s == 2,
              "Cantidad incorrecta de pulsos de un segundo");

        // Verifica que un nuevo reset limpie contadores y salidas.
        rst_n = 1'b0;
        #1;
        check(!ce_debounce && !ce_1s && !ce_display,
              "El reset no limpio inmediatamente las salidas");

        if (errores == 0)
            $display("\n*** TODAS LAS PRUEBAS PASARON (%0d/%0d) ***\n",
                     pruebas, pruebas);
        else
            $fatal(1, "\n*** %0d DE %0d PRUEBAS FALLARON ***\n",
                   errores, pruebas);

        $finish;
    end

endmodule
