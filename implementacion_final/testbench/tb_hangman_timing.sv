`timescale 1ns / 1ps

module tb_hangman_timing;

    localparam int BIT_CLKS = 868;
    localparam int BIT_NS   = BIT_CLKS * 10;  // 8680 ns

    logic CLK100MHZ = 0;

    logic btnC = 1;
    logic btnU = 0;
    logic btnD = 0;

    logic RsRx = 1;
    wire  RsTx;

    wire       lcd_rs;
    wire       lcd_rw;
    wire       lcd_e;
    wire [7:0] lcd_data;

    wire [3:0] led;

    wire [6:0] seg;
    wire [3:0] an;
    wire       dp;

    wire buzzer_out;

    logic [7:0] packet [0:17];

    integer errors = 0;
    integer i;


    // =========================================================
    // TOP COMPLETO
    // =========================================================

    hangman_top dut (
        .CLK100MHZ (CLK100MHZ),

        .btnC       (btnC),
        .btnU       (btnU),
        .btnD       (btnD),

        .RsRx       (RsRx),
        .RsTx       (RsTx),

        .lcd_rs     (lcd_rs),
        .lcd_rw     (lcd_rw),
        .lcd_e      (lcd_e),
        .lcd_data   (lcd_data),

        .led        (led),

        .seg        (seg),
        .an         (an),
        .dp         (dp),

        .buzzer_out (buzzer_out)
    );


    // 100 MHz
    always #5 CLK100MHZ = ~CLK100MHZ;


    task automatic check(
        input logic condition,
        input string message
    );
        begin

            if (condition)
                $display("PASS: %s", message);

            else begin
                $display("FAIL: %s", message);
                errors = errors + 1;
            end

        end
    endtask


    // =========================================================
    // ENVIAR BYTE PC -> FPGA
    // =========================================================

    task automatic send_uart_byte(
        input logic [7:0] data
    );

        integer b;

        begin

            // START
            RsRx = 0;
            #(BIT_NS);

            // DATA, LSB primero
            for (b = 0; b < 8; b = b + 1) begin
                RsRx = data[b];
                #(BIT_NS);
            end

            // STOP
            RsRx = 1;
            #(BIT_NS);

        end

    endtask


    // =========================================================
    // RECIBIR BYTE FPGA -> PC
    // =========================================================

    task automatic capture_uart_byte(
        output logic [7:0] data
    );

        integer b;

        begin

            data = 0;

            // Detectar START
            @(negedge RsTx);

            // Centro del START
            #(BIT_NS/2);

            check(
                RsTx == 0,
                "UART TX genera START"
            );

            // Centro de cada bit
            for (b = 0; b < 8; b = b + 1) begin
                #(BIT_NS);
                data[b] = RsTx;
            end

            // STOP
            #(BIT_NS);

            check(
                RsTx == 1,
                "UART TX genera STOP"
            );

        end

    endtask


    task automatic capture_packet(
        input integer length
    );

        integer n;

        begin

            for (n = 0; n < length; n = n + 1)
                capture_uart_byte(packet[n]);

        end

    endtask


    // =========================================================
    // TEST
    // =========================================================

    initial begin

        $display("");
        $display("======================================");
        $display(" POST-IMPLEMENTATION TIMING TEST");
        $display("======================================");
        $display("");


        // Mantener reset durante el arranque
        #1000;
        btnC = 0;

        #500;


        // =====================================================
        // INICIAR MODO FACIL
        // Y CAPTURAR PAQUETE START
        // =====================================================

        fork

            capture_packet(4);

            begin
                #100;
                btnU = 1;
                #100;
                btnU = 0;
            end

        join


        check(
            packet[0] == 8'hA5,
            "START packet inicia con A5"
        );

        check(
            packet[1] == 8'h01,
            "START packet tiene tipo 01"
        );

        check(
            packet[2] == 8'h00,
            "Modo reportado es FACIL"
        );

        check(
            packet[3] >= 4 &&
            packet[3] <= 12,
            "Longitud de palabra valida"
        );


        // =====================================================
        // ENVIAR LETRA A POR UART REAL DEL TOP
        // =====================================================

        $display("");
        $display("Enviando letra A por UART...");


        fork

            // Esperar respuesta completa
            capture_packet(18);

            begin
                #20_000;
                send_uart_byte("A");
            end

        join


        // =====================================================
        // COMPROBAR RESPUESTA
        // =====================================================

        check(
            packet[0] == 8'hA5,
            "Respuesta inicia con A5"
        );

        check(
            packet[1] == 8'h02,
            "Respuesta es paquete de letra"
        );

        check(
            packet[2] == "A",
            "FPGA proceso la letra A"
        );

        check(
            packet[3] == 8'h01 ||
            packet[3] == 8'h02,
            "Letra fue validada como correcta o incorrecta"
        );


        // Si A fue correcta quedan 6 intentos.
        // Si fue incorrecta quedan 5.
        if (packet[3] == 8'h01) begin

            check(
                packet[4] == 6,
                "Correcta conserva 6 intentos"
            );

        end

        else begin

            check(
                packet[4] == 5,
                "Incorrecta deja 5 intentos"
            );

        end


        $display("");
        $display("======================================");

        if (errors == 0)
            $display("          TIMING TEST: PASS");
        else
            $display(
                "      TIMING TEST: FAIL (%0d errores)",
                errors
            );

        $display("======================================");
        $display("");

        $finish;

    end

endmodule