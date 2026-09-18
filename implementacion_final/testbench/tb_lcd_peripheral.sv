`timescale 1ns / 1ps

module tb_lcd_peripheral;

    localparam int CLK_FREQ = 1_000_000;

    localparam logic [1:0] CONTROL = 2'b00;
    localparam logic [1:0] DATA    = 2'b01;

    logic clk = 0;
    logic rst = 0;

    logic        write_enable = 0;
    logic [1:0]  addr = 0;
    logic [31:0] wdata = 0;
    logic [31:0] rdata;

    logic       lcd_rs;
    logic       lcd_rw;
    logic       lcd_e;
    logic [7:0] lcd_data;

    integer errors = 0;

    logic [7:0] captured_data [0:15];
    logic       captured_rs   [0:15];
    integer capture_count = 0;


    lcd_peripheral #(
        .CLK_FREQ(CLK_FREQ)
    ) dut (
        .clk_i          (clk),
        .rst_i          (rst),

        .write_enable_i (write_enable),
        .addr_i         (addr),
        .wdata_i        (wdata),
        .rdata_o        (rdata),

        .lcd_rs         (lcd_rs),
        .lcd_rw         (lcd_rw),
        .lcd_e          (lcd_e),
        .lcd_data       (lcd_data)
    );


    always #5 clk = ~clk;


    task automatic check(
        input logic condition,
        input string message
    );
        if (condition)
            $display("PASS: %s", message);
        else begin
            $display("FAIL: %s", message);
            errors = errors + 1;
        end
    endtask


    task automatic write_reg(
        input logic [1:0] address,
        input logic [31:0] value
    );
        begin
            @(negedge clk);

            addr         = address;
            wdata        = value;
            write_enable = 1;

            @(negedge clk);

            write_enable = 0;
            wdata        = 0;
        end
    endtask


    // El LCD captura en el flanco descendente de E.
    always @(negedge lcd_e) begin

        if (!rst && capture_count < 16) begin
            captured_data[capture_count] = lcd_data;
            captured_rs[capture_count]   = lcd_rs;
            capture_count = capture_count + 1;
        end

    end


    initial begin

        $display("");
        $display("======================================");
        $display("      TESTBENCH LCD_PERIPHERAL");
        $display("======================================");
        $display("");


        // =====================================================
        // RESET
        // =====================================================

        rst = 1;
        repeat (3) @(posedge clk);
        rst = 0;


        check(
            lcd_rw == 0,
            "LCD permanece siempre en modo escritura"
        );


        // =====================================================
        // INICIALIZACION
        // =====================================================

        // Esperamos a que termine toda la secuencia inicial.
        wait(rdata[8] == 0);

        check(
            capture_count >= 4,
            "Se ejecutaron los cuatro comandos de inicializacion"
        );

        check(
            captured_data[0] == 8'h38,
            "Inicializacion envia 0x38"
        );

        check(
            captured_data[1] == 8'h0C,
            "Inicializacion envia 0x0C"
        );

        check(
            captured_data[2] == 8'h01,
            "Inicializacion envia 0x01"
        );

        check(
            captured_data[3] == 8'h06,
            "Inicializacion envia 0x06"
        );

        check(
            captured_rs[0] == 0 &&
            captured_rs[1] == 0 &&
            captured_rs[2] == 0 &&
            captured_rs[3] == 0,
            "Inicializacion usa RS=0"
        );


        // =====================================================
        // REGISTRO DATA
        // =====================================================

        write_reg(
            DATA,
            32'h0000_0041
        );

        addr = DATA;
        #1;

        check(
            rdata[7:0] == 8'h41,
            "Registro DATA almacena caracter A"
        );


        // =====================================================
        // START CON RS=1
        //
        // Escribir carácter 'A'
        // =====================================================

        write_reg(
            CONTROL,
            32'h0000_0003
        );

        // bit0 = START
        // bit1 = RS = 1

        addr = CONTROL;
        #1;

        check(
            rdata[8] == 1,
            "START activa busy"
        );

        wait(rdata[8] == 0);

        check(
            captured_data[4] == 8'h41,
            "LCD recibe caracter A"
        );

        check(
            captured_rs[4] == 1,
            "Caracter se envia con RS=1"
        );


        // =====================================================
        // DONE
        // =====================================================

        // done es un pulso corto; esperamos su aparición
        wait(rdata[9] == 1);

        check(
            rdata[9] == 1,
            "Peripheral genera done al terminar"
        );

        @(posedge clk);
        #1;

        check(
            rdata[9] == 0,
            "done dura un solo ciclo"
        );


        // =====================================================
        // CLEAR
        //
        // CONTROL bit 2 = 1
        // =====================================================

        write_reg(
            CONTROL,
            32'h0000_0004
        );

        addr = CONTROL;
        #1;

        check(
            rdata[8] == 1,
            "CLEAR activa busy"
        );

        wait(rdata[8] == 0);

        check(
            captured_data[5] == 8'h01,
            "CLEAR envia comando 0x01"
        );

        check(
            captured_rs[5] == 0,
            "CLEAR usa RS=0"
        );


        // =====================================================
        // HOME
        //
        // CONTROL bit 3 = 1
        // =====================================================

        write_reg(
            CONTROL,
            32'h0000_0008
        );

        wait(rdata[8] == 0);

        check(
            captured_data[6] == 8'h02,
            "HOME envia comando 0x02"
        );

        check(
            captured_rs[6] == 0,
            "HOME usa RS=0"
        );


        // =====================================================
        // RESULTADO FINAL
        // =====================================================

        $display("");
        $display("======================================");

        if (errors == 0)
            $display("          TESTBENCH: PASS");
        else
            $display(
                "      TESTBENCH: FAIL (%0d errores)",
                errors
            );

        $display("======================================");
        $display("");

        $finish;

    end

endmodule