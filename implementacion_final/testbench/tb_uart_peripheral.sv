`timescale 1ns / 1ps

module tb_uart_peripheral;

    localparam int CLK_FREQ  = 1000;
    localparam int BAUD_RATE = 100;

    localparam int BIT_CLKS  = CLK_FREQ / BAUD_RATE;
    localparam int HALF_CLKS = BIT_CLKS / 2;

    localparam logic [1:0] DATA_TX = 2'b00;
    localparam logic [1:0] DATA_RX = 2'b01;
    localparam logic [1:0] CONTROL = 2'b10;


    logic clk = 0;
    logic rst = 0;

    logic        write_enable;
    logic [1:0]  addr;
    logic [31:0] wdata;
    logic [31:0] rdata;

    logic uart_rx = 1;
    logic uart_tx;

    integer errors = 0;


    // =========================================================
    // DUT
    // =========================================================

    uart_peripheral #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) dut (
        .clk_i          (clk),
        .rst_i          (rst),

        .write_enable_i (write_enable),
        .addr_i         (addr),
        .wdata_i        (wdata),
        .rdata_o        (rdata),

        .uart_rx_i      (uart_rx),
        .uart_tx_o      (uart_tx)
    );


    // Clock
    always #5 clk = ~clk;


    // =========================================================
    // CHECK
    // =========================================================

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


    // =========================================================
    // RESET
    // =========================================================

    task automatic do_reset;

        begin

            rst = 1;

            repeat (3)
                @(posedge clk);

            rst = 0;

            @(negedge clk);

        end

    endtask


    // =========================================================
    // ESCRIBIR REGISTRO
    // =========================================================

    task automatic write_reg(
        input logic [1:0]  address,
        input logic [31:0] data
    );

        begin

            @(negedge clk);

            addr         = address;
            wdata        = data;
            write_enable = 1;

            @(posedge clk);

            @(negedge clk);

            write_enable = 0;
            wdata        = 0;

        end

    endtask


    // =========================================================
    // ENVIAR BYTE DESDE EL TESTBENCH HACIA RX DEL DUT
    //
    // UART 8N1:
    //
    // START
    // 8 bits LSB first
    // STOP
    // =========================================================

    task automatic send_uart_byte(
        input logic [7:0] data
    );

        integer i;

        begin

            // Start bit
            uart_rx = 0;

            repeat (BIT_CLKS)
                @(posedge clk);


            // 8 bits de datos
            for (i = 0; i < 8; i = i + 1) begin

                uart_rx = data[i];

                repeat (BIT_CLKS)
                    @(posedge clk);

            end


            // Stop bit
            uart_rx = 1;

            repeat (BIT_CLKS)
                @(posedge clk);


            // Dejar línea en reposo
            uart_rx = 1;

        end

    endtask


    // =========================================================
    // CAPTURAR UN BYTE TRANSMITIDO POR EL DUT
    // =========================================================

    task automatic capture_tx_byte(
        output logic [7:0] data
    );

        integer i;

        begin

            data = 0;

            // Esperar start bit
            @(negedge uart_tx);


            // Ir al centro del start bit
            repeat (HALF_CLKS)
                @(posedge clk);

            check(
                uart_tx == 0,
                "TX genera start bit"
            );


            // Ir al centro de cada bit de datos
            for (i = 0; i < 8; i = i + 1) begin

                repeat (BIT_CLKS)
                    @(posedge clk);

                data[i] = uart_tx;

            end


            // Ir al centro del stop bit
            repeat (BIT_CLKS)
                @(posedge clk);

            check(
                uart_tx == 1,
                "TX genera stop bit"
            );

        end

    endtask


    // =========================================================
    // TEST PRINCIPAL
    // =========================================================

    initial begin

        logic [7:0] tx_received;


        write_enable = 0;
        addr         = CONTROL;
        wdata        = 0;
        uart_rx      = 1;


        $display("");
        $display("======================================");
        $display("     TESTBENCH UART_PERIPHERAL");
        $display("======================================");
        $display("");


        // =====================================================
        // PRUEBA 1 - RESET
        // =====================================================

        do_reset();

        addr = CONTROL;
        #1;

        check(
            rdata[0] == 0,
            "Reset deja TX libre"
        );

        check(
            rdata[1] == 0,
            "Reset limpia new_rx"
        );

        check(
            uart_tx == 1,
            "TX permanece en reposo alto"
        );


        // =====================================================
        // PRUEBA 2 - REGISTRO DATA_TX
        // =====================================================

        write_reg(
            DATA_TX,
            32'h0000_00A5
        );

        addr = DATA_TX;
        #1;

        check(
            rdata[7:0] == 8'hA5,
            "DATA_TX almacena correctamente el byte"
        );


        // =====================================================
        // PRUEBA 3 - TRANSMITIR 0xA5
        // =====================================================

        fork

            begin

                capture_tx_byte(
                    tx_received
                );

            end


            begin

                // Pequeño margen para que el hilo
                // de captura empiece a esperar.
                repeat (2)
                    @(posedge clk);

                write_reg(
                    CONTROL,
                    32'h0000_0001
                );

                addr = CONTROL;
                #1;

                check(
                    rdata[0] == 1,
                    "CONTROL indica TX busy"
                );

            end

        join


        check(
            tx_received == 8'hA5,
            "TX transmite correctamente 0xA5"
        );


        // Esperar que termine completamente
        addr = CONTROL;

        wait(rdata[0] == 0);

        check(
            rdata[0] == 0,
            "TX busy vuelve a cero"
        );


        // =====================================================
        // PRUEBA 4 - RECEPCION DE 0x5A
        // =====================================================

        fork

            begin

                send_uart_byte(
                    8'h5A
                );

            end


            begin

                addr = CONTROL;

                wait(rdata[1] == 1);

            end

        join


        addr = CONTROL;
        #1;

        check(
            rdata[1] == 1,
            "RX activa new_rx"
        );


        // =====================================================
        // PRUEBA 5 - LEER DATA_RX
        // =====================================================

        addr = DATA_RX;
        #1;

        check(
            rdata[7:0] == 8'h5A,
            "DATA_RX contiene correctamente 0x5A"
        );


        // =====================================================
        // PRUEBA 6 - LIMPIAR new_rx
        //
        // Escribir CONTROL con bit 1 = 0.
        // =====================================================

        write_reg(
            CONTROL,
            32'h0000_0000
        );

        addr = CONTROL;
        #1;

        check(
            rdata[1] == 0,
            "CONTROL limpia new_rx"
        );


        // =====================================================
        // SEGUNDO BYTE DE RECEPCION
        // =====================================================

        send_uart_byte(
            8'h41
        );

        addr = CONTROL;
        wait(rdata[1] == 1);

        addr = DATA_RX;
        #1;

        check(
            rdata[7:0] == 8'h41,
            "RX recibe correctamente el caracter A"
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