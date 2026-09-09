`timescale 1ns/1ps
// ============================================================================
// tb_gestion_palabras.sv
// Testbench autoverificable para el bloque Gestion de Palabras.
// ============================================================================
module tb_gestion_palabras;

    logic        clk = 0;
    logic        rst_n;
    logic        dificultad;
    logic        pedir_palabra;
    logic [4:0]  letra_in;
    logic        validar;
    logic [3:0]  longitud_palabra;
    logic        palabra_lista;
    logic [11:0] mask_coincidencia;

    int errores = 0;
    int pruebas = 0;

    gestion_palabras dut (.*);

    always #5 clk = ~clk; // 100 MHz

    task automatic pedir_y_esperar();
        pedir_palabra = 1'b1;
        @(posedge clk); #1;
        pedir_palabra = 1'b0;
        // palabra_lista llega 1 ciclo despues de pedir_d (2 ciclos totales)
        wait (palabra_lista == 1'b1);
        @(posedge clk); #1;
    endtask

    task automatic check(input bit cond, input string msg);
        pruebas++;
        if (!cond) begin
            errores++;
            $display("[FALLO] %s (t=%0t)", msg, $time);
        end
    endtask

    initial begin
        rst_n = 0; dificultad = 0; pedir_palabra = 0; letra_in = 0; validar = 0;
        repeat (3) @(posedge clk); #1;
        rst_n = 1;
        @(posedge clk); #1;

        // --- Prueba 1: Facil, longitud debe estar entre 4 y 12 ---
        dificultad = 0;
        pedir_y_esperar();
        check((longitud_palabra >= 4) && (longitud_palabra <= 12),
              "Facil: longitud fuera de rango 4-12");

        // --- Prueba 2: Dificil, longitud debe ser >= 6 ---
        repeat (5) begin
            dificultad = 1;
            pedir_y_esperar();
            check(longitud_palabra >= 4'd6, "Dificil: longitud menor a 6");
        end

        // --- Prueba 3: pedir varias veces en Facil, todas deben ser 4-12 ---
        dificultad = 0;
        repeat (10) begin
            pedir_y_esperar();
            check((longitud_palabra >= 4) && (longitud_palabra <= 12),
                  "Facil (repetido): longitud fuera de rango");
        end

        // --- Prueba 4: comparador - probar que la primera letra de la
        //     palabra actual produce coincidencia en la posicion 0 ---
        // Truco: usamos letra_in = A y solo verificamos que si la mascara
        // resultante no es cero, mask[0] coincide con si la palabra
        // realmente empieza con A (no podemos leer la palabra directo desde
        // afuera, asi que probamos las 26 letras y contamos cuantas dan
        // coincidencia == longitud de aciertos esperado >=0).
        begin
            int total_coincidencias;
            total_coincidencias = 0;
            for (int c = 1; c <= 26; c++) begin
                letra_in = 5'(c);
                validar = 1'b1;
                @(posedge clk); #1;
                validar = 1'b0;
                @(posedge clk); #1; // esperar registro de mask_coincidencia
                total_coincidencias += $countones(mask_coincidencia);
            end
            // La suma de coincidencias de las 26 letras debe ser exactamente
            // igual a la longitud de la palabra (cada posicion coincide con
            // exactamente una letra).
            check(total_coincidencias == longitud_palabra,
                  "Comparador: suma de coincidencias de A-Z no coincide con longitud");
        end

        // --- Prueba 5: letra invalida (codigo 0) no debe producir coincidencia ---
        letra_in = 5'd0;
        validar = 1'b1;
        @(posedge clk); #1;
        validar = 1'b0;
        @(posedge clk); #1;
        check(mask_coincidencia == 12'd0, "Letra invalida (0) produjo coincidencia");

        if (errores == 0)
            $display("\n*** TODAS LAS PRUEBAS PASARON (%0d/%0d) ***\n", pruebas, pruebas);
        else
            $display("\n*** %0d DE %0d PRUEBAS FALLARON ***\n", errores, pruebas);

        $finish;
    end

endmodule
