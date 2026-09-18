`timescale 1ns/1ps

module tb_control_uart;
    logic clk_i = 1'b0;
    logic rst_i = 1'b1;
    logic send_i = 1'b0;
    logic tx_done_i = 1'b0;
    logic rx_valid_i = 1'b0;
    logic tx_start_o, tx_complete_o, rx_event_o, busy_o;
    int pruebas = 0;

    always #5 clk_i = ~clk_i;

    control_uart dut (.*);

    task automatic comprobar(input logic condicion, input string mensaje);
        pruebas++;
        if (!condicion) begin
            $error("FALLO: %s", mensaje);
            $finish;
        end
    endtask

    initial begin
        repeat (2) @(posedge clk_i);
        rst_i = 1'b0;
        @(negedge clk_i);

        send_i = 1'b1;
        #1 comprobar(tx_start_o, "send debe generar tx_start");
        @(posedge clk_i); #1;
        comprobar(busy_o, "debe esperar el final de TX");
        comprobar(!tx_start_o, "tx_start debe durar un ciclo");

        repeat (3) @(posedge clk_i);
        #1 comprobar(!tx_start_o, "send sostenido no debe repetir el envio");

        tx_done_i = 1'b1;
        #1 comprobar(tx_complete_o, "tx_done debe confirmar la transferencia");
        @(posedge clk_i); #1;
        tx_done_i = 1'b0;
        send_i = 1'b0;
        comprobar(!busy_o, "debe regresar a espera");

        rx_valid_i = 1'b1;
        #1 comprobar(rx_event_o, "rx_valid debe producir el evento RX");
        rx_valid_i = 1'b0;
        #1 comprobar(!rx_event_o, "el evento RX debe terminar con rx_valid");

        @(negedge clk_i);
        send_i = 1'b1;
        #1 comprobar(tx_start_o, "debe aceptar una nueva transferencia");

        $display("OK: control UART completo, %0d pruebas superadas", pruebas);
        $finish;
    end
endmodule
