`timescale 1ns/1ps

module tb_periferico_uart;
    localparam int RX_TICKS = 2;
    localparam int TX_TICKS = 32;
    localparam time BIT_TIME = TX_TICKS * 10ns;
    localparam logic [7:0] BYTE_R = 8'h52;

    logic clk_i = 1'b0;
    logic rst_i = 1'b1;
    logic write_enable_i = 1'b0;
    logic [1:0] addr_i = 2'b00;
    logic [31:0] wdata_i = 32'h0;
    logic [31:0] rdata_o;
    logic rx_i = 1'b1;
    logic tx_o, new_rx_o, busy_o;
    int pruebas = 0;

    always #5 clk_i = ~clk_i;

    periferico_uart #(
        .RX_BAUD_X16_TICKS(RX_TICKS),
        .TX_BAUD_TICKS(TX_TICKS)
    ) dut (.*);

    task automatic comprobar(input logic condicion, input string mensaje);
        pruebas++;
        if (!condicion) begin
            $error("FALLO: %s", mensaje);
            $finish;
        end
    endtask

    task automatic escribir(input logic [1:0] direccion,
                             input logic [31:0] dato);
        @(negedge clk_i);
        addr_i = direccion; wdata_i = dato; write_enable_i = 1'b1;
        @(negedge clk_i);
        write_enable_i = 1'b0;
    endtask

    task automatic enviar_rx(input logic [7:0] dato);
        rx_i = 1'b0; #(BIT_TIME);
        for (int i = 0; i < 8; i++) begin
            rx_i = dato[i]; #(BIT_TIME);
        end
        rx_i = 1'b1; #(BIT_TIME);
    endtask

    initial begin
        repeat (4) @(posedge clk_i);
        rst_i = 1'b0;
        #(BIT_TIME);

        enviar_rx(8'h41);
        wait (new_rx_o); #1;
        addr_i = 2'b01; #1;
        comprobar(rdata_o == 32'h00000041, "DATA_RX debe guardar A");
        addr_i = 2'b10; #1;
        comprobar(rdata_o[1], "CONTROL.new_rx debe activarse");
        escribir(2'b10, 32'h00000000);
        comprobar(!new_rx_o, "debe poder limpiar new_rx");

        escribir(2'b00, {24'h0, BYTE_R});
        escribir(2'b10, 32'h00000001);
        wait (tx_o == 1'b0);
        #(BIT_TIME/2);
        comprobar(tx_o == 1'b0, "TX debe enviar el bit de inicio");
        #(BIT_TIME/2);
        for (int i = 0; i < 8; i++) begin
            #(BIT_TIME/2);
            comprobar(tx_o == BYTE_R[i], "TX debe enviar los bits de R");
            #(BIT_TIME/2);
        end
        #(BIT_TIME/2);
        comprobar(tx_o == 1'b1, "TX debe enviar el bit de parada");
        #(BIT_TIME/2);
        wait (!busy_o);
        addr_i = 2'b10; #1;
        comprobar(!rdata_o[0], "tx_done debe limpiar CONTROL.send");

        $display("OK: periferico UART completo, %0d pruebas superadas", pruebas);
        $finish;
    end
endmodule
