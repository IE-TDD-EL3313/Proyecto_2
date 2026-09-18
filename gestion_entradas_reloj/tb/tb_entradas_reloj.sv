`timescale 1ns/1ps
// ============================================================================
// tb_entradas_reloj.sv
// Prueba la integracion del reloj, las habilitaciones y los tres botones.
// ============================================================================
module tb_entradas_reloj;

    logic clk = 1'b0;
    logic rst_n;
    logic btn_sel_i;
    logic btn_ok_i;
    logic btn_rst_i;
    logic sel_pulse;
    logic ok_pulse;
    logic rst_pulse;
    logic ce_debounce;
    logic ce_1s;
    logic ce_display;

    int errores = 0;
    int pruebas = 0;
    int pulsos_sel = 0;
    int pulsos_ok = 0;
    int pulsos_rst = 0;
    int pulsos_debounce = 0;
    int pulsos_1s = 0;
    int pulsos_display = 0;

    entradas_reloj #(
        .CLK_HZ            (100),
        .DEBOUNCE_HZ       (10),
        .DISPLAY_HZ        (20),
        .MUESTRAS_ESTABLES (3)
    ) dut (.*);

    always #5 clk = ~clk;

    always @(negedge clk) begin
        if (sel_pulse)   pulsos_sel++;
        if (ok_pulse)    pulsos_ok++;
        if (rst_pulse)   pulsos_rst++;
        if (ce_debounce) pulsos_debounce++;
        if (ce_1s)       pulsos_1s++;
        if (ce_display)  pulsos_display++;
    end

    task automatic check(input bit condicion, input string mensaje);
        pruebas++;
        if (!condicion) begin
            errores++;
            $display("[FALLO] %s (t=%0t)", mensaje, $time);
        end
    endtask

    task automatic esperar_ciclos(input int cantidad);
        repeat (cantidad) @(negedge clk);
    endtask

    initial begin
        rst_n     = 1'b0;
        btn_sel_i = 1'b0;
        btn_ok_i  = 1'b0;
        btn_rst_i = 1'b0;

        esperar_ciclos(3);
        check(!sel_pulse && !ok_pulse && !rst_pulse,
              "Los pulsos no iniciaron en cero");
        check(!ce_debounce && !ce_1s && !ce_display,
              "Las habilitaciones no iniciaron en cero");

        rst_n = 1'b1;

        // Una pulsacion estable debe recorrer toda la cadena.
        @(negedge clk);
        btn_sel_i = 1'b1;
        esperar_ciclos(45);
        check(pulsos_sel == 1,
              "BTN_SEL no produjo exactamente un pulso");

        // Mantener presionado no debe repetir el pulso.
        esperar_ciclos(40);
        check(pulsos_sel == 1,
              "BTN_SEL sostenido produjo pulsos adicionales");

        // Liberar BTN_SEL y esperar a que el filtro acepte la liberacion.
        btn_sel_i = 1'b0;
        esperar_ciclos(45);
        check(pulsos_sel == 1,
              "La liberacion de BTN_SEL produjo un pulso");

        // Los otros dos canales deben funcionar de manera simultanea.
        btn_ok_i  = 1'b1;
        btn_rst_i = 1'b1;
        esperar_ciclos(45);
        check(pulsos_ok == 1 && pulsos_rst == 1,
              "BTN_OK y BTN_RST no produjeron un pulso cada uno");

        // A estas alturas todos los generadores de tiempo deben haber operado.
        check(pulsos_debounce > 0,
              "No se generaron pulsos ce_debounce");
        check(pulsos_display > pulsos_debounce,
              "ce_display no tiene una frecuencia mayor que ce_debounce");
        check(pulsos_1s > 0,
              "No se generaron pulsos ce_1s");

        rst_n = 1'b0;
        #1;
        check(!sel_pulse && !ok_pulse && !rst_pulse,
              "El reset no limpio los pulsos de botones");
        check(!ce_debounce && !ce_1s && !ce_display,
              "El reset no limpio las habilitaciones");

        if (errores == 0)
            $display("\n*** TODAS LAS PRUEBAS PASARON (%0d/%0d) ***\n",
                     pruebas, pruebas);
        else
            $fatal(1, "\n*** %0d DE %0d PRUEBAS FALLARON ***\n",
                   errores, pruebas);

        $finish;
    end

endmodule
