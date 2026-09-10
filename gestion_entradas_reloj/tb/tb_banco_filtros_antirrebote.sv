`timescale 1ns/1ps
// ============================================================================
// tb_banco_filtros_antirrebote.sv
// Prueba autoverificable con tres muestras estables por transicion.
// ============================================================================
module tb_banco_filtros_antirrebote;

    localparam int unsigned MUESTRAS_TB = 3;

    logic       clk = 1'b0;
    logic       rst_n;
    logic       ce_debounce;
    logic [2:0] btn_sync;
    logic [2:0] btn_stable;

    int errores = 0;
    int pruebas = 0;

    banco_filtros_antirrebote #(
        .MUESTRAS_ESTABLES(MUESTRAS_TB)
    ) dut (.*);

    always #5 clk = ~clk;

    task automatic check(input bit condicion, input string mensaje);
        pruebas++;
        if (!condicion) begin
            errores++;
            $display("[FALLO] %s (t=%0t)", mensaje, $time);
        end
    endtask

    task automatic muestra();
        ce_debounce = 1'b1;
        @(posedge clk);
        #1;
        ce_debounce = 1'b0;
        @(posedge clk);
        #1;
    endtask

    initial begin
        rst_n       = 1'b0;
        ce_debounce = 1'b0;
        btn_sync    = 3'b000;
        #1;
        check(btn_stable == 3'b000, "Reset no limpio las salidas");

        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        // Sin ce_debounce, un cambio de entrada no debe ser aceptado.
        btn_sync[0] = 1'b1;
        repeat (5) @(posedge clk);
        #1;
        check(btn_stable == 3'b000,
              "BTN_SEL cambio sin habilitacion de muestreo");

        // Dos muestras no son suficientes.
        muestra();
        muestra();
        check(btn_stable == 3'b000,
              "BTN_SEL fue aceptado antes de tres muestras");

        // Un rebote al estado anterior cancela el conteo acumulado.
        btn_sync[0] = 1'b0;
        muestra();
        btn_sync[0] = 1'b1;
        muestra();
        muestra();
        check(btn_stable == 3'b000,
              "El contador no se reinicio despues de un rebote");

        muestra();
        check(btn_stable == 3'b001,
              "BTN_SEL no fue aceptado tras tres muestras consecutivas");

        // Los tres canales deben mantener contadores independientes.
        btn_sync = 3'b111;
        muestra();
        btn_sync[1] = 1'b0; // rebote solo en BTN_OK
        muestra();
        btn_sync[1] = 1'b1;
        muestra();

        check(btn_stable == 3'b101,
              "BTN_RST no se filtro independientemente de BTN_OK");

        muestra();
        muestra();
        check(btn_stable == 3'b111,
              "BTN_OK no completo su propio conteo estable");

        // La liberacion del boton tambien debe filtrarse.
        btn_sync[2] = 1'b0;
        muestra();
        muestra();
        check(btn_stable[2] == 1'b1,
              "BTN_RST se libero antes del numero requerido de muestras");

        muestra();
        check(btn_stable[2] == 1'b0,
              "BTN_RST no se libero tras tres muestras estables");

        rst_n = 1'b0;
        #1;
        check(btn_stable == 3'b000,
              "Reset final no limpio las salidas inmediatamente");

        if (errores == 0)
            $display("\n*** TODAS LAS PRUEBAS PASARON (%0d/%0d) ***\n",
                     pruebas, pruebas);
        else
            $fatal(1, "\n*** %0d DE %0d PRUEBAS FALLARON ***\n",
                   errores, pruebas);

        $finish;
    end

endmodule
