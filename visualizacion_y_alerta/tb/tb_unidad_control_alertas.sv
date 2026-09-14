`timescale 1ns/1ps
module tb_unidad_control_alertas;
    import alertas_pkg::*;
    logic clk_i = 1'b0;
    logic rst_i;
    logic evento_acierto_i;
    logic evento_error_i;
    logic evento_fin_i;
    logic victoria_i;
    logic [1:0] fase_i;
    logic [1:0] tono_sel_o;
    logic [1:0] led_sel_o;
    logic [2:0] pantalla_sel_o;
    logic actualizar_lcd_o, tono_start_o;
    unidad_control_alertas dut (.*);
    always #5 clk_i = ~clk_i;
    initial begin
        rst_i           = 1'b1;
        fase_i          = FASE_SELECCION;
        evento_acierto_i = 1'b0;
        evento_error_i   = 1'b0;
        evento_fin_i     = 1'b0;
        victoria_i        = 1'b0;

        // Cambiar reset en flanco negativo evita competir con el always_ff.
        @(negedge clk_i);
        rst_i = 1'b0;
        @(posedge clk_i);
        #1;
        if (pantalla_sel_o != PANTALLA_MODO || led_sel_o != LED_APAGADO || !actualizar_lcd_o) $fatal(1,"Seleccion incorrecta");
        @(negedge clk_i);
        fase_i           = FASE_PARTIDA;
        evento_acierto_i = 1'b1;
        @(posedge clk_i);
        #1;
        if (pantalla_sel_o != PANTALLA_PARTIDA || led_sel_o != LED_ENCENDIDO || tono_sel_o != TONO_ACIERTO || !tono_start_o) $fatal(1,"Acierto incorrecto");
        @(negedge clk_i);
        evento_acierto_i = 1'b0;
        evento_error_i   = 1'b1;
        @(posedge clk_i);
        #1;
        if (tono_sel_o != TONO_ERROR || !tono_start_o) $fatal(1,"Error incorrecto");
        @(negedge clk_i);
        evento_error_i = 1'b0;
        evento_fin_i   = 1'b1;
        victoria_i     = 1'b1;
        fase_i         = FASE_RESULTADO;
        @(posedge clk_i);
        #1;
        if (pantalla_sel_o != PANTALLA_VICTORIA || led_sel_o != LED_PARPADEO || tono_sel_o != TONO_FINAL) $fatal(1,"Final victoria incorrecto");
        $display("PASS: tb_unidad_control_alertas");
        $finish;
    end
endmodule
