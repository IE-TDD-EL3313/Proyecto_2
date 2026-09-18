`timescale 1ns/1ps

module tb_banco_registros_uart;
    logic clk_i = 1'b0;
    logic rst_i = 1'b1;
    logic write_enable_i = 1'b0;
    logic [1:0] addr_i = 2'b00;
    logic [31:0] wdata_i = 32'h0;
    logic [31:0] rdata_o;
    logic [7:0] rx_data_i = 8'h00;
    logic rx_valid_i = 1'b0;
    logic tx_done_i = 1'b0;
    logic [7:0] tx_data_o;
    logic send_o, new_rx_o;
    int pruebas = 0;

    always #5 clk_i = ~clk_i;

    banco_registros_uart dut (.*);

    task automatic comprobar(input logic condicion, input string mensaje);
        pruebas++;
        if (!condicion) begin
            $error("FALLO: %s", mensaje);
            $finish;
        end
    endtask

    task automatic escribir(input logic [1:0] direccion,
                             input logic [31:0] dato);
        addr_i = direccion;
        wdata_i = dato;
        write_enable_i = 1'b1;
        @(posedge clk_i); #1;
        write_enable_i = 1'b0;
    endtask

    initial begin
        repeat (2) @(posedge clk_i);
        rst_i = 1'b0;

        escribir(2'b00, 32'h00000041);
        comprobar(tx_data_o == 8'h41, "DATA_TX debe guardar A");

        escribir(2'b10, 32'h00000001);
        comprobar(send_o, "CONTROL.send debe activarse");
        tx_done_i = 1'b1;
        @(posedge clk_i); #1;
        tx_done_i = 1'b0;
        comprobar(!send_o, "tx_done debe limpiar send");

        rx_data_i = 8'h52;
        rx_valid_i = 1'b1;
        @(posedge clk_i); #1;
        rx_valid_i = 1'b0;
        comprobar(new_rx_o, "una recepcion debe activar new_rx");
        addr_i = 2'b01; #1;
        comprobar(rdata_o == 32'h00000052, "DATA_RX debe contener R");

        escribir(2'b10, 32'h00000000);
        comprobar(!new_rx_o, "escribir cero debe limpiar new_rx");
        addr_i = 2'b10; #1;
        comprobar(rdata_o[1:0] == 2'b00, "CONTROL debe quedar limpio");
        addr_i = 2'b11; #1;
        comprobar(rdata_o == 32'h0, "la direccion reservada debe leer cero");

        $display("OK: banco UART completo, %0d pruebas superadas", pruebas);
        $finish;
    end
endmodule
