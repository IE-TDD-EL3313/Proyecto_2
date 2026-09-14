`timescale 1ns/1ps

module tb_lcd_16x2;
    logic clk_i = 1'b0;
    logic rst_i;
    logic write_enable_i;
    logic [1:0] addr_i;
    logic [31:0] wdata_i;
    logic [31:0] rdata_o;
    logic lcd_rs_o;
    logic lcd_rw_o;
    logic lcd_e_o;
    logic [7:0] lcd_data_o;
    int pulse_count;
    logic [7:0] expected_data [0:7];
    logic expected_rs [0:7];

    // Tiempos reducidos para simulacion. CLK_HZ=1 MHz hace un ciclo por us.
    lcd_16x2 #(
        .CLK_HZ        (1_000_000),
        .POWER_ON_US   (3),
        .E_PULSE_US    (2),
        .CMD_WAIT_US   (3),
        .CLEAR_WAIT_US (5)
    ) dut (.*);

    always #5 clk_i = ~clk_i;

    always @(posedge lcd_e_o) begin
        if (lcd_rw_o !== 1'b0) $fatal(1, "El LCD debe operar en escritura");
        if ((pulse_count < 8) &&
            ((lcd_data_o !== expected_data[pulse_count]) ||
             (lcd_rs_o !== expected_rs[pulse_count])))
            $fatal(1, "Transferencia LCD %0d incorrecta: rs=%b data=%h", pulse_count, lcd_rs_o, lcd_data_o);
        pulse_count++;
    end

    task automatic write_reg(input logic [1:0] address, input logic [31:0] value);
        @(negedge clk_i);
        write_enable_i = 1'b1;
        addr_i = address;
        wdata_i = value;
        @(negedge clk_i);
        write_enable_i = 1'b0;
        addr_i = '0;
        wdata_i = '0;
    endtask

    task automatic wait_idle;
        while (rdata_o[8]) @(posedge clk_i);
    endtask

    initial begin
        expected_data[0] = 8'h38; expected_rs[0] = 0;
        expected_data[1] = 8'h0C; expected_rs[1] = 0;
        expected_data[2] = 8'h06; expected_rs[2] = 0;
        expected_data[3] = 8'h01; expected_rs[3] = 0;
        expected_data[4] = 8'h41; expected_rs[4] = 1;
        expected_data[5] = 8'h01; expected_rs[5] = 0;
        expected_data[6] = 8'h02; expected_rs[6] = 0;
        pulse_count = 0;
        rst_i          = 1;
        write_enable_i = 0;
        addr_i         = 0;
        wdata_i        = 0;
        repeat (2) @(posedge clk_i);
        rst_i = 0;

        wait_idle();
        if (pulse_count != 4) $fatal(1, "Inicializacion incompleta");
        if (rdata_o[9]) $fatal(1, "done no debe activarse durante inicializacion");

        write_reg(2'b01, 32'h00000041);
        write_reg(2'b00, 32'h00000003); // start y rs para escribir 'A'
        if (!rdata_o[8]) $fatal(1, "busy no se activo con start");
        wait_idle();
        if (!rdata_o[9]) $fatal(1, "done no se activo al terminar escritura");

        write_reg(2'b00, 32'h00000004); // clear W1P
        wait_idle();
        write_reg(2'b00, 32'h00000008); // home W1P
        wait_idle();
        if (pulse_count != 7) $fatal(1, "Numero de pulsos inesperado: %0d", pulse_count);
        $display("PASS: tb_lcd_16x2");
        $finish;
    end
endmodule
