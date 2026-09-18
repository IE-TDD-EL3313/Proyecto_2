`timescale 1ns/1ps
// ============================================================================
// tb_gestion_entradas_locales.sv
// Prueba la cadena completa desde el boton asincrono hasta el pulso de salida.
// ============================================================================
module tb_gestion_entradas_locales;

    localparam int unsigned MUESTRAS_TB = 3;

    logic clk = 1'b0;
    logic rst_n;
    logic ce_debounce;
    logic btn_sel_i;
    logic btn_ok_i;
    logic btn_rst_i;
    logic sel_pulse;
    logic ok_pulse;
    logic rst_pulse;

    int errores = 0;
    int pruebas = 0;
    int pulsos_sel = 0;
    int pulsos_ok  = 0;
    int pulsos_rst = 0;

    gestion_entradas_locales #(
        .MUESTRAS_ESTABLES(MUESTRAS_TB)
    ) dut (.*);

    always #5 clk = ~clk;

    // Se cuentan en el flanco opuesto para observar las salidas ya registradas.
    always @(negedge clk) begin
        if (sel_pulse) pulsos_sel++;
        if (ok_pulse)  pulsos_ok++;
        if (rst_pulse) pulsos_rst++;
    end

    task automatic check(input bit condicion, input string mensaje);
        pruebas++;
        if (!condicion) begin
            errores++;
            $display("[FALLO] %s (t=%0t)", mensaje, $time);
        end
    endtask

    task automatic esperar_sincronizacion();
        repeat (3) @(posedge clk);
        #1;
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
        btn_sel_i   = 1'b0;
        btn_ok_i    = 1'b0;
        btn_rst_i   = 1'b0;

        repeat (3) @(posedge clk);
        #1;
        check(!sel_pulse && !ok_pulse && !rst_pulse,
              "Las salidas no iniciaron en cero");
        rst_n = 1'b1;

        // BTN_SEL presenta dos muestras altas, rebota a cero y vuelve a subir.
        @(negedge clk);
        btn_sel_i = 1'b1;
        esperar_sincronizacion();
        muestra();
        muestra();

        @(negedge clk);
        btn_sel_i = 1'b0;
        esperar_sincronizacion();
        muestra();
        check(pulsos_sel == 0,
              "El rebote parcial de BTN_SEL genero un pulso");

        @(negedge clk);
        btn_sel_i = 1'b1;
        esperar_sincronizacion();
        repeat (3) muestra();
        repeat (2) @(posedge clk);
        check(pulsos_sel == 1,
              "Una pulsacion estable de BTN_SEL no genero un solo pulso");

        // Mantener el boton presionado no debe repetir el evento.
        repeat (5) muestra();
        check(pulsos_sel == 1,
              "BTN_SEL sostenido genero pulsos adicionales");

        // La liberacion estable tampoco genera eventos.
        @(negedge clk);
        btn_sel_i = 1'b0;
        esperar_sincronizacion();
        repeat (3) muestra();
        check(pulsos_sel == 1,
              "La liberacion de BTN_SEL genero un pulso");

        // BTN_OK y BTN_RST deben funcionar en paralelo.
        @(negedge clk);
        btn_ok_i  = 1'b1;
        btn_rst_i = 1'b1;
        esperar_sincronizacion();
        repeat (3) muestra();
        repeat (2) @(posedge clk);
        check(pulsos_ok == 1 && pulsos_rst == 1,
              "BTN_OK y BTN_RST no generaron un pulso cada uno");
        check(pulsos_sel == 1,
              "La actividad de otros botones altero BTN_SEL");

        rst_n = 1'b0;
        #1;
        check(!sel_pulse && !ok_pulse && !rst_pulse,
              "El reset final no limpio las salidas");

        if (errores == 0)
            $display("\n*** TODAS LAS PRUEBAS PASARON (%0d/%0d) ***\n",
                     pruebas, pruebas);
        else
            $fatal(1, "\n*** %0d DE %0d PRUEBAS FALLARON ***\n",
                   errores, pruebas);

        $finish;
    end

endmodule
