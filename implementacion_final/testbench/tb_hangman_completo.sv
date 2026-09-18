`timescale 1ns / 1ps

// =============================================================================
// TESTBENCH INTEGRADO Y AUTOVERIFICABLE
// =============================================================================
// Prueba hangman_top_completo desde sus puertos externos. Se reducen tiempos
// mediante parámetros únicamente para que la simulación termine rápidamente.
// =============================================================================
module tb_hangman_completo;

    localparam int CLK_FREQ  = 1_000_000;
    localparam int BAUD_RATE = 100_000;
    localparam int BIT_CLKS  = CLK_FREQ / BAUD_RATE;
    localparam time CLK_HALF = 500ns;
    localparam time BIT_TIME = BIT_CLKS * 1us;

    logic CLK100MHZ = 1'b0;
    logic btnC = 1'b1;
    logic btnU = 1'b0;
    logic btnD = 1'b0;
    logic RsRx = 1'b1;

    wire RsTx;
    wire lcd_rs, lcd_rw, lcd_e;
    wire [7:0] lcd_data;
    wire [3:0] led;
    wire [6:0] seg;
    wire [3:0] an;
    wire dp, buzzer_out;

    logic [7:0] packet [0:17];
    logic [25:0] sent_letters;
    logic [7:0] test_letter;
    integer errors = 0;
    integer checks = 0;
    integer i, j;

    hangman_top_completo #(
        .CLK_FREQ    (CLK_FREQ),
        .BAUD_RATE   (BAUD_RATE),
        .EASY_TIME   (2),
        .HARD_TIME   (1),
        .RESULT_TIME (1),
        .DEBOUNCE_MS (1)
    ) dut (
        .CLK100MHZ  (CLK100MHZ),
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

    always #CLK_HALF CLK100MHZ = ~CLK100MHZ;

    task automatic check(input logic condition, input string message);
        begin
            checks = checks + 1;
            if (condition)
                $display("PASS: %s", message);
            else begin
                errors = errors + 1;
                $display("FAIL: %s", message);
            end
        end
    endtask

    task automatic reset_system;
        begin
            btnC = 1'b1;
            btnU = 1'b0;
            btnD = 1'b0;
            RsRx = 1'b1;
            repeat (10) @(posedge CLK100MHZ);
            btnC = 1'b0;
            repeat (10) @(posedge CLK100MHZ);
        end
    endtask

    // Cada pulsación supera el debounce simulado de 1 ms y también deja tiempo
    // para aceptar la liberación antes de la siguiente pulsación.
    task automatic press_sel;
        begin
            btnU = 1'b1;
            #1.2ms;
            btnU = 1'b0;
            #1.2ms;
        end
    endtask

    task automatic press_ok;
        begin
            btnD = 1'b1;
            #1.2ms;
            btnD = 1'b0;
            #1.2ms;
        end
    endtask

    task automatic send_uart_byte(input logic [7:0] data);
        integer b;
        begin
            RsRx = 1'b0;               // start
            #(BIT_TIME);
            for (b = 0; b < 8; b = b + 1) begin
                RsRx = data[b];         // LSB primero
                #(BIT_TIME);
            end
            RsRx = 1'b1;               // stop
            #(BIT_TIME);
        end
    endtask

    task automatic capture_uart_byte(output logic [7:0] data);
        integer b;
        begin
            data = 8'h00;
            @(negedge RsTx);
            #(BIT_TIME/2);
            check(RsTx == 1'b0, "UART TX genera bit START");
            for (b = 0; b < 8; b = b + 1) begin
                #(BIT_TIME);
                data[b] = RsTx;
            end
            #(BIT_TIME);
            check(RsTx == 1'b1, "UART TX genera bit STOP");
        end
    endtask

    task automatic capture_packet(input integer length);
        integer n;
        begin
            for (n = 0; n < length; n = n + 1)
                capture_uart_byte(packet[n]);
        end
    endtask

    task automatic start_selected_game(input logic expected_hard);
        begin
            if (dut.selected_mode != expected_hard)
                press_sel();

            // Se evita usar una expresión ternaria entre strings porque algunas
            // versiones de XSim 2026.1 producen una excepción interna.
            if (expected_hard)
                check(dut.selected_mode == 1'b1, "SEL muestra DIFICIL");
            else
                check(dut.selected_mode == 1'b0, "SEL muestra FACIL");

            fork
                capture_packet(4);
                press_ok();
            join

            check(packet[0] == 8'hA5, "Paquete START inicia con A5");
            check(packet[1] == 8'h01, "Paquete START tiene tipo 01");
            check(packet[2] == expected_hard, "Paquete START informa el modo correcto");
            if (expected_hard)
                check(packet[3] >= 6 && packet[3] <= 12,
                      "Longitud DIFICIL esta entre 6 y 12");
            else
                check(packet[3] >= 4 && packet[3] <= 12,
                      "Longitud FACIL esta entre 4 y 12");
            check(led[1] == 1'b1, "LED1 indica partida activa");
        end
    endtask

    task automatic send_and_capture_letter(input logic [7:0] data);
        begin
            fork
                capture_packet(18);
                begin
                    #20us;
                    send_uart_byte(data);
                end
            join
            check(packet[0] == 8'hA5 && packet[1] == 8'h02,
                  "Respuesta de letra usa paquete A5 02");
            check(packet[2] == data, "Respuesta contiene la letra enviada");
        end
    endtask

    function automatic logic letter_in_word(input logic [7:0] value);
        integer p;
        begin
            letter_in_word = 1'b0;
            for (p = 0; p < 12; p = p + 1)
                if (p < dut.word_length &&
                    dut.selected_word[95-p*8 -: 8] == value)
                    letter_in_word = 1'b1;
        end
    endfunction

    initial begin
        $display("");
        $display("====================================================");
        $display("       TESTBENCH COMPLETO - HANGMAN BASYS 3");
        $display("====================================================");

        // ---------------------------------------------------------------------
        // Reset y selector de modo
        // ---------------------------------------------------------------------
        reset_system();
        check(led[0] == 1'b1, "Reset deja el sistema en MENU");
        check(led[1] == 1'b0 && led[2] == 1'b0,
              "Reset apaga indicadores GAME y RESULT");
        check(dut.selected_mode == 1'b0, "Modo inicial es FACIL");

        press_sel();
        check(dut.selected_mode == 1'b1, "BTN_SEL alterna a DIFICIL");
        check(led[3] == 1'b1, "LED3 muestra selección DIFICIL");
        press_sel();
        check(dut.selected_mode == 1'b0, "BTN_SEL alterna de vuelta a FACIL");

        // ---------------------------------------------------------------------
        // Partida difícil: inválida, correcta, repetida y victoria
        // ---------------------------------------------------------------------
        start_selected_game(1'b1);

        j = dut.wrong_count;
        send_uart_byte("?");
        #300us;
        check(dut.wrong_count == j, "Carácter no A-Z se ignora");
        check(dut.game_active, "Entrada inválida no termina la partida");

        test_letter = dut.selected_word[95 -: 8];
        send_and_capture_letter(test_letter);
        check(packet[3] == 8'h01, "Primera letra de la palabra es CORRECTA");
        check(buzzer_out == 1'b1, "Acierto activa el buzzer");
        j = dut.wrong_count;

        send_and_capture_letter(test_letter);
        check(packet[3] == 8'h03, "La misma letra se reporta REPETIDA");
        check(dut.wrong_count == j, "Letra repetida no consume intento");

        // Enviar una vez cada letra distinta de la palabra para ganar.
        sent_letters = 26'b0;
        sent_letters[test_letter - "A"] = 1'b1;
        for (i = 0; i < dut.word_length; i = i + 1) begin
            test_letter = dut.selected_word[95-i*8 -: 8];
            if (!sent_letters[test_letter - "A"]) begin
                sent_letters[test_letter - "A"] = 1'b1;
                send_and_capture_letter(test_letter);
                check(packet[3] == 8'h01, "Letra necesaria se acepta como correcta");
            end
        end

        capture_packet(17);
        check(packet[0] == 8'hA5 && packet[1] == 8'h03,
              "Victoria genera paquete final A5 03");
        check(packet[2] == 8'h01 && packet[3] == 8'h01,
              "Paquete final informa victoria");
        check(led[2] == 1'b1, "LED2 indica RESULT");
        check(dut.victories == 1, "Victoria incrementa contador acumulado");

        wait (dut.menu_active);
        repeat (5) @(posedge CLK100MHZ);
        check(led[0] == 1'b1, "Tras RESULT el sistema vuelve a MENU");

        // ---------------------------------------------------------------------
        // Partida fácil: seis letras ausentes producen derrota por intentos
        // ---------------------------------------------------------------------
        start_selected_game(1'b0);
        j = 0;
        for (i = 0; i < 26 && j < 6; i = i + 1) begin
            test_letter = "A" + i;
            if (!letter_in_word(test_letter)) begin
                send_and_capture_letter(test_letter);
                check(packet[3] == 8'h02, "Letra ausente se reporta INCORRECTA");
                j = j + 1;
            end
        end

        capture_packet(17);
        check(packet[1] == 8'h03, "Sexto error genera paquete final");
        check(packet[2] == 8'h00 && packet[3] == 8'h02,
              "Paquete informa derrota por intentos");
        check(dut.wrong_count == 6, "Contador llega exactamente a seis errores");

        wait (dut.menu_active);
        repeat (5) @(posedge CLK100MHZ);

        // ---------------------------------------------------------------------
        // Nueva partida sin letras: derrota por tiempo
        // ---------------------------------------------------------------------
        start_selected_game(1'b0);
        capture_packet(17);
        check(packet[1] == 8'h03, "Timeout genera paquete final");
        check(packet[2] == 8'h00 && packet[3] == 8'h03,
              "Paquete informa derrota por tiempo");
        check(dut.result_active, "Timeout lleva la FSM a RESULT");

        wait (dut.menu_active);
        repeat (5) @(posedge CLK100MHZ);
        check(led[0] && !led[1] && !led[2],
              "Después del resultado vuelve a selección");
        check(dp == 1'b1, "Punto decimal permanece apagado");
        check(an != 4'b1111, "Display de siete segmentos está multiplexando");

        $display("");
        $display("====================================================");
        if (errors == 0)
            $display(" TESTBENCH COMPLETO: PASS (%0d comprobaciones)", checks);
        else
            $display(" TESTBENCH COMPLETO: FAIL (%0d de %0d)", errors, checks);
        $display("====================================================");
        $finish;
    end

    // Evita que un bloqueo silencioso deje la simulación corriendo para siempre.
    initial begin
        #12s;
        $display("FAIL: timeout global del testbench");
        $finish;
    end

endmodule
