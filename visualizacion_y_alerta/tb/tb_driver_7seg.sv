`timescale 1ns/1ps
module tb_driver_7seg;
    logic clk_i = 1'b0;
    logic rst_i;
    logic ce_display_i;
    logic [6:0] tiempo_i;
    logic [6:0] victorias_i;
    logic [6:0] seg_o;
    logic [3:0] an_o;
    driver_7seg #(.CLK_HZ(1_000_000), .SCAN_HZ(25_000)) dut (.*);
    always #5 clk_i = ~clk_i;
    initial begin
        rst_i = 1; ce_display_i = 0; tiempo_i = 0; victorias_i = 0;
        // Liberar reset y presentar entradas fuera del flanco activo.
        @(negedge clk_i);
        rst_i = 0; tiempo_i = 42; victorias_i = 7; ce_display_i = 1;
        @(posedge clk_i);
        // Esperar las asignaciones no bloqueantes del driver.
        #1;
        ce_display_i = 0;
        // Primer digito: decenas de segundos, 4.
        if (an_o != 4'b0111 || seg_o != 7'b0011001) $fatal(1,"Digito S decenas incorrecto");
        repeat(10) @(posedge clk_i);
        if (an_o != 4'b1011 || seg_o != 7'b0100100) $fatal(1,"Digito S unidades incorrecto");
        repeat(10) @(posedge clk_i);
        if (an_o != 4'b1101 || seg_o != 7'b1000000) $fatal(1,"Digito G decenas incorrecto");
        repeat(10) @(posedge clk_i);
        if (an_o != 4'b1110 || seg_o != 7'b1111000) $fatal(1,"Digito G unidades incorrecto");
        $display("PASS: tb_driver_7seg");
        $finish;
    end
endmodule
