`timescale 1ns/1ps
module tb_codificador_led;
    import alertas_pkg::*;
    logic clk_i = 1'b0;
    logic rst_i;
    logic led_o;
    logic [1:0] led_sel_i;
    codificador_led #(
        .CLK_HZ   (100),
        .BLINK_HZ (2)
    ) dut (.*);

    always #5 clk_i = ~clk_i;
    initial begin
        rst_i     = 1'b1;
        led_sel_i = LED_APAGADO;
        @(posedge clk_i);
        rst_i = 1'b0;
        #1;
        if (led_o) $fatal(1,"LED apagado incorrecto");
        led_sel_i = LED_ENCENDIDO;
        #1;
        if (!led_o) $fatal(1,"LED encendido incorrecto");
        led_sel_i = LED_PARPADEO;
        repeat(25) @(posedge clk_i);
        #1;
        if (!led_o) $fatal(1,"LED no alterno a 2 Hz");
        led_sel_i = LED_APAGADO;
        #1;
        if (led_o) $fatal(1,"LED no se apago");
        $display("PASS: tb_codificador_led");
        $finish;
    end
endmodule
