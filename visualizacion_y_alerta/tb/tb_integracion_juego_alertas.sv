`timescale 1ns/1ps

module tb_integracion_juego_alertas;
    logic clk_i = 1'b0;
    logic rst_n_i;
    logic [1:0] estado_juego_i;
    logic [1:0] evento_sonido_i;
    logic resultado_final_i;
    logic [11:0] palabra_revelada_i;
    logic [2:0] intentos_restantes_i;
    logic [7:0] partidas_ganadas_bcd_i;
    logic [7:0] tiempo_restante_bcd_i;
    logic [95:0] palabra_secreta_ascii_i;
    logic ce_display_i;
    logic buzzer_o, led_o, lcd_rs_o, lcd_rw_o, lcd_e_o;
    logic [6:0] seg_o;
    logic [3:0] an_o;
    logic [7:0] lcd_data_o;

    integracion_juego_alertas dut (.*);

    always #5 clk_i = ~clk_i;

    initial begin
        rst_n_i = 1'b0;
        estado_juego_i = 2'b00;
        evento_sonido_i = 2'b00;
        resultado_final_i = 1'b0;
        palabra_revelada_i = '0;
        intentos_restantes_i = 3'd6;
        partidas_ganadas_bcd_i = 8'h00;
        tiempo_restante_bcd_i = 8'h60;
        palabra_secreta_ascii_i = {"A", "M", "O", "R", " ", " ", " ", " ", " ", " ", " ", " "};
        ce_display_i = 1'b0;

        repeat (2) @(posedge clk_i);
        rst_n_i = 1'b1;

        // Partida: A y O reveladas; 45 s, dos errores y doce victorias.
        estado_juego_i = 2'b10;
        evento_sonido_i = 2'b01;
        palabra_revelada_i = 12'b0000_0000_0101;
        intentos_restantes_i = 3'd4;
        partidas_ganadas_bcd_i = 8'h12;
        tiempo_restante_bcd_i = 8'h45;
        ce_display_i = 1'b1;
        @(posedge clk_i);
        ce_display_i = 1'b0;
        evento_sonido_i = 2'b00;
        #1;

        if (!led_o)
            $fatal(1, "El LED debe estar encendido durante la partida");
        if (an_o == 4'b1111)
            $fatal(1, "El driver de siete segmentos no habilito ningun digito");

        // Resultado ganador: se debe entrar a modo de parpadeo del LED.
        estado_juego_i = 2'b11;
        evento_sonido_i = 2'b11;
        resultado_final_i = 1'b1;
        @(posedge clk_i);
        #1;
        if (led_o !== 1'b0)
            $fatal(1, "El parpadeo inicia apagado despues de reset");

        $display("PASS: tb_integracion_juego_alertas");
        $finish;
    end
endmodule
