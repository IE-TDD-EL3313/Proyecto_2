`timescale 1ns/1ps

module tb_generador_tramas_uart;
    logic clk_i = 0, rst_i = 1, evento_i = 0;
    logic [1:0] tipo_i = 0, resultado_i = 0;
    logic modo_i = 0;
    logic [3:0] longitud_i = 4;
    logic [2:0] intentos_i = 6;
    logic [95:0] patron_ascii_i;
    logic [31:0] uart_rdata_i = 0;
    logic uart_write_enable_o, busy_o;
    logic [1:0] uart_addr_o;
    logic [31:0] uart_wdata_o;
    logic [7:0] recibidos [0:18];
    int cantidad = 0;

    always #5 clk_i = ~clk_i;
    generador_tramas_uart dut (.*);

    always @(posedge clk_i) begin
        if (uart_write_enable_o && uart_addr_o == 2'b00) begin
            recibidos[cantidad] <= uart_wdata_o[7:0];
            cantidad <= cantidad + 1;
        end
        if (uart_write_enable_o && uart_addr_o == 2'b10)
            uart_rdata_i[0] <= 1'b1;
        else if (uart_rdata_i[0])
            uart_rdata_i[0] <= 1'b0;
    end

    initial begin
        patron_ascii_i = {{8{" "}}, {4{"_"}}};
        repeat (2) @(posedge clk_i);
        rst_i = 0;
        @(negedge clk_i); evento_i = 1;
        @(negedge clk_i); evento_i = 0;
        wait (!busy_o && cantidad == 19); #1;

        assert(recibidos[0] == 8'h7E && recibidos[1] == "I");
        assert(recibidos[2] == 0 && recibidos[3] == 4);
        assert(recibidos[4] == 0 && recibidos[5] == 6);
        assert(recibidos[6] == "_" && recibidos[9] == "_");
        assert(recibidos[10] == " " && recibidos[17] == " ");
        assert(recibidos[18] == 8'h0A);
        $display("OK: trama de inicio de 19 bytes generada correctamente");
        $finish;
    end
endmodule
