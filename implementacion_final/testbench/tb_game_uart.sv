`timescale 1ns / 1ps

module tb_game_uart;

    localparam int CLK_FREQ  = 1000;
    localparam int BAUD_RATE = 100;
    localparam int BIT_CLKS  = CLK_FREQ / BAUD_RATE;
    localparam int HALF_CLKS = BIT_CLKS / 2;

    logic clk = 0;
    logic rst = 0;

    logic btn_easy = 0;
    logic btn_hard = 0;

    // PC -> FPGA
    logic pc_tx = 1;

    // FPGA -> PC
    logic fpga_tx;

    logic [7:0] letter;
    logic       letter_valid;

    logic hard_mode;
    logic menu_active;
    logic game_active;
    logic result_active;
    logic result_win;

    logic [95:0] selected_word;
    logic [3:0]  word_length;
    logic [11:0] revealed_mask;
    logic [2:0]  wrong_count;
    logic [6:0]  time_left;
    logic [6:0]  victories;

    logic letter_processed;
    logic letter_correct;
    logic letter_wrong;
    logic letter_repeated;

    logic [7:0] packet [0:17];

    integer errors = 0;
    integer i;


    // =========================================================
    // GAME CORE
    // =========================================================

    game_core #(
        .CLK_FREQ    (CLK_FREQ),
        .EASY_TIME   (30),
        .HARD_TIME   (20),
        .RESULT_TIME (2)
    ) game (
        .clk              (clk),
        .rst              (rst),

        .btn_easy         (btn_easy),
        .btn_hard         (btn_hard),

        .letter           (letter),
        .letter_valid     (letter_valid),

        .hard_mode        (hard_mode),
        .menu_active      (menu_active),
        .game_active      (game_active),
        .result_active    (result_active),
        .result_win       (result_win),

        .selected_word    (selected_word),
        .word_length      (word_length),
        .revealed_mask    (revealed_mask),
        .wrong_count      (wrong_count),
        .time_left        (time_left),
        .victories        (victories),

        .letter_processed (letter_processed),
        .letter_correct   (letter_correct),
        .letter_wrong     (letter_wrong),
        .letter_repeated  (letter_repeated)
    );


    // =========================================================
    // UART DEL JUEGO
    // =========================================================

    uart_game_interface #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) uart_game (
        .clk              (clk),
        .rst              (rst),

        .uart_rx_i        (pc_tx),
        .uart_tx_o        (fpga_tx),

        .letter           (letter),
        .letter_valid     (letter_valid),

        .hard_mode        (hard_mode),
        .game_active      (game_active),
        .result_active    (result_active),
        .result_win       (result_win),

        .selected_word    (selected_word),
        .word_length      (word_length),
        .revealed_mask    (revealed_mask),
        .wrong_count      (wrong_count),

        .letter_processed (letter_processed),
        .letter_correct   (letter_correct),
        .letter_wrong     (letter_wrong),
        .letter_repeated  (letter_repeated)
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
    // BOTÓN FÁCIL
    // =========================================================

    task automatic press_easy;

        begin

            @(negedge clk);
            btn_easy = 1;

            @(negedge clk);
            btn_easy = 0;

        end

    endtask


    // =========================================================
    // PC ENVÍA BYTE UART
    // =========================================================

    task automatic pc_send_byte(
        input logic [7:0] data
    );

        integer b;

        begin

            // Start
            pc_tx = 0;

            repeat (BIT_CLKS)
                @(posedge clk);


            // Datos LSB first
            for (b = 0; b < 8; b = b + 1) begin

                pc_tx = data[b];

                repeat (BIT_CLKS)
                    @(posedge clk);

            end


            // Stop
            pc_tx = 1;

            repeat (BIT_CLKS)
                @(posedge clk);

        end

    endtask


    // =========================================================
    // CAPTURAR BYTE FPGA -> PC
    // =========================================================

    task automatic capture_byte(
        output logic [7:0] data
    );

        integer b;

        begin

            data = 0;

            // Esperar start bit
            @(negedge fpga_tx);

            // Centro del start
            repeat (HALF_CLKS)
                @(posedge clk);

            // Datos
            for (b = 0; b < 8; b = b + 1) begin

                repeat (BIT_CLKS)
                    @(posedge clk);

                data[b] = fpga_tx;

            end

            // Stop
            repeat (BIT_CLKS)
                @(posedge clk);

        end

    endtask


    // =========================================================
    // CAPTURAR PAQUETE
    // =========================================================

    task automatic capture_packet(
        input integer length
    );

        integer n;

        begin

            for (n = 0; n < length; n = n + 1)
                capture_byte(packet[n]);

        end

    endtask


    // =========================================================
    // ENCONTRAR UNA LETRA INCORRECTA
    // =========================================================

    function automatic [7:0] find_wrong_letter;

        integer c;
        integer p;
        logic found;

        begin

            find_wrong_letter = "Z";

            for (c = 0; c < 26; c = c + 1) begin

                found = 0;

                for (p = 0; p < word_length; p = p + 1)
                    if (
                        selected_word[95-p*8 -: 8]
                        == ("A" + c)
                    )
                        found = 1;

                if (!found)
                    find_wrong_letter = "A" + c;

            end

        end

    endfunction


    // =========================================================
    // COMPROBAR PATRÓN UART
    // =========================================================

    task automatic check_pattern;

        logic [7:0] expected;

        begin

            for (i = 0; i < 12; i = i + 1) begin

                if (i < word_length) begin

                    if (revealed_mask[i])
                        expected =
                            selected_word[95-i*8 -: 8];
                    else
                        expected = "_";

                end

                else
                    expected = " ";


                check(
                    packet[6+i] == expected,
                    $sformatf(
                        "Patron UART posicion %0d correcto",
                        i
                    )
                );

            end

        end

    endtask


    // =========================================================
    // TEST
    // =========================================================

    initial begin

        logic [7:0] correct_char;
        logic [7:0] wrong_char;


        $display("");
        $display("======================================");
        $display("       TESTBENCH GAME + UART");
        $display("======================================");
        $display("");


        // =====================================================
        // RESET
        // =====================================================

        do_reset();

        check(
            menu_active,
            "Sistema inicia en MENU"
        );


        // =====================================================
        // INICIO DE PARTIDA + PAQUETE 01
        // =====================================================

        fork

            capture_packet(4);

            press_easy();

        join


        check(
            game_active,
            "BTNU inicia partida"
        );

        check(
            packet[0] == 8'hA5,
            "Paquete START inicia con A5"
        );

        check(
            packet[1] == 8'h01,
            "Paquete START tiene tipo 01"
        );

        check(
            packet[2] == 8'h00,
            "FPGA reporta modo FACIL"
        );

        check(
            packet[3] == word_length,
            "FPGA reporta longitud correcta"
        );


        // Primera letra de la palabra
        correct_char =
            selected_word[95 -: 8];


        // =====================================================
        // LETRA CORRECTA POR UART
        // =====================================================

        fork

            capture_packet(18);

            pc_send_byte(correct_char);

        join


        check(
            packet[0] == 8'hA5 &&
            packet[1] == 8'h02,
            "Respuesta de letra usa paquete 02"
        );

        check(
            packet[2] == correct_char,
            "FPGA responde la misma letra"
        );

        check(
            packet[3] == 8'h01,
            "Resultado UART indica CORRECTA"
        );

        check(
            packet[4] == 6,
            "Letra correcta conserva 6 intentos"
        );

        check(
            packet[5] == word_length,
            "Respuesta incluye longitud correcta"
        );

        check_pattern();


        // =====================================================
        // LETRA REPETIDA
        // =====================================================

        fork

            capture_packet(18);

            pc_send_byte(correct_char);

        join


        check(
            packet[3] == 8'h03,
            "Segunda letra igual se reporta REPETIDA"
        );

        check(
            packet[4] == 6,
            "Letra repetida no consume intento"
        );

        check(
            wrong_count == 0,
            "Repetida mantiene wrong_count"
        );


        // =====================================================
        // LETRA INCORRECTA
        // =====================================================

        wrong_char = find_wrong_letter();


        fork

            capture_packet(18);

            pc_send_byte(wrong_char);

        join


        check(
            packet[2] == wrong_char,
            "Respuesta corresponde a letra incorrecta enviada"
        );

        check(
            packet[3] == 8'h02,
            "Resultado UART indica INCORRECTA"
        );

        check(
            packet[4] == 5,
            "UART reporta 5 intentos restantes"
        );

        check(
            wrong_count == 1,
            "game_core registra un error"
        );

        check_pattern();


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