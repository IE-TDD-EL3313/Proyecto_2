`timescale 1ns / 1ps

module tb_game_core;

    localparam int CLK_FREQ    = 20;
    localparam int EASY_TIME   = 5;
    localparam int HARD_TIME   = 3;
    localparam int RESULT_TIME = 2;

    logic clk = 0;
    logic rst = 0;

    logic btn_easy = 0;
    logic btn_hard = 0;

    logic [7:0] letter = 0;
    logic       letter_valid = 0;

    logic hard_mode;
    logic menu_active;
    logic game_active;
    logic result_active;
    logic result_win;

    logic [95:0] selected_word;
    logic [3:0]  word_length;
    logic [11:0] revealed_mask;

    logic [2:0] wrong_count;
    logic [6:0] time_left;
    logic [6:0] victories;

    logic letter_processed;
    logic letter_correct;
    logic letter_wrong;
    logic letter_repeated;

    integer errors = 0;


    // =========================================================
    // DUT
    // =========================================================

    game_core #(
        .CLK_FREQ    (CLK_FREQ),
        .EASY_TIME   (EASY_TIME),
        .HARD_TIME   (HARD_TIME),
        .RESULT_TIME (RESULT_TIME)
    ) dut (
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


    // Clock de 100 MHz equivalente
    always #5 clk = ~clk;


    // =========================================================
    // CHECK AUTOCORRECTIVO
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

            repeat (2)
                @(posedge clk);

            rst = 0;

            @(negedge clk);

        end

    endtask


    // =========================================================
    // BOTONES
    // =========================================================

    task automatic press_easy;

        begin

            @(negedge clk);
            btn_easy = 1;

            @(negedge clk);
            btn_easy = 0;

            @(negedge clk);

        end

    endtask


    task automatic press_hard;

        begin

            @(negedge clk);
            btn_hard = 1;

            @(negedge clk);
            btn_hard = 0;

            @(negedge clk);

        end

    endtask


    // =========================================================
    // ENVIAR LETRA
    // =========================================================

    task automatic send_letter(
        input logic [7:0] c
    );

        begin

            @(negedge clk);

            letter       = c;
            letter_valid = 1;

            @(posedge clk);
            #1;

            // En este punto ya podemos observar
            // los pulsos del game_core.

            @(negedge clk);

            letter_valid = 0;

        end

    endtask


    // =========================================================
    // BUSCAR UNA LETRA QUE NO ESTÁ EN LA PALABRA
    // =========================================================

    function automatic [7:0] wrong_letter(
        input integer number
    );

        integer c;
        integer p;
        integer count;
        logic found;

        begin

            wrong_letter = "Z";
            count = 0;

            for (c = 0; c < 26; c = c + 1) begin

                found = 0;

                for (p = 0; p < word_length; p = p + 1)
                    if (
                        selected_word[95-p*8 -: 8]
                        == (8'd65 + c)
                    )
                        found = 1;

                if (!found) begin

                    if (count == number)
                        wrong_letter = 8'd65 + c;

                    count = count + 1;

                end

            end

        end

    endfunction


    // =========================================================
    // CALCULAR POSICIONES DE UNA LETRA
    // =========================================================

    function automatic [11:0] mask_for_letter(
        input logic [7:0] c
    );

        integer p;

        begin

            mask_for_letter = 0;

            for (p = 0; p < word_length; p = p + 1)
                if (
                    selected_word[95-p*8 -: 8] == c
                )
                    mask_for_letter[p] = 1;

        end

    endfunction


    // =========================================================
    // COMPLETAR PALABRA ACTUAL
    // =========================================================

    task automatic complete_word;

        integer p;
        integer idx;

        logic [25:0] sent;
        logic [7:0] c;

        begin

            sent = 0;

            for (p = 0; p < word_length; p = p + 1) begin

                c   = selected_word[95-p*8 -: 8];
                idx = c - "A";

                if (!sent[idx] && game_active) begin

                    sent[idx] = 1;
                    send_letter(c);

                end

            end

        end

    endtask


    // =========================================================
    // TEST PRINCIPAL
    // =========================================================

    initial begin

        logic [7:0] correct_char;
        logic [11:0] expected_mask;
        logic [2:0] previous_wrong;

        integer n;


        $display("");
        $display("======================================");
        $display("      TESTBENCH GAME_CORE");
        $display("======================================");
        $display("");


        // =====================================================
        // PRUEBA 1 - RESET
        // =====================================================

        do_reset();

        check(
            menu_active == 1,
            "Reset deja el sistema en MENU"
        );

        check(
            victories == 0,
            "Reset limpia victorias"
        );

        check(
            wrong_count == 0,
            "Reset limpia errores"
        );


        // =====================================================
        // PRUEBA 2 - MODO FACIL
        // =====================================================

        press_easy();

        check(
            game_active == 1,
            "BTNU inicia una partida"
        );

        check(
            hard_mode == 0,
            "BTNU selecciona modo FACIL"
        );

        check(
            time_left == EASY_TIME,
            "Modo FACIL carga el tiempo correcto"
        );

        check(
            word_length >= 4 &&
            word_length <= 12,
            "Modo FACIL selecciona una palabra valida"
        );


        // =====================================================
        // PRUEBA 3 - LETRA CORRECTA
        // =====================================================

        correct_char =
            selected_word[95 -: 8];

        expected_mask =
            mask_for_letter(correct_char);

        send_letter(correct_char);

        check(
            letter_processed == 1,
            "La letra valida genera letter_processed"
        );

        check(
            letter_correct == 1,
            "Se detecta una letra correcta"
        );

        check(
            (revealed_mask & expected_mask)
            == expected_mask,
            "Se revelan todas las apariciones"
        );

        check(
            wrong_count == 0,
            "Una letra correcta no resta intentos"
        );


        // =====================================================
        // PRUEBA 4 - LETRA REPETIDA
        // =====================================================

        send_letter(correct_char);

        check(
            letter_repeated == 1,
            "La segunda aparicion de la misma entrada es repetida"
        );

        check(
            wrong_count == 0,
            "Una letra repetida no resta intentos"
        );


        // =====================================================
        // PRUEBA 5 - LETRA INCORRECTA
        // =====================================================

        previous_wrong = wrong_count;

        send_letter(
            wrong_letter(0)
        );

        check(
            letter_wrong == 1,
            "Se detecta una letra incorrecta"
        );

        check(
            wrong_count == previous_wrong + 1,
            "La letra incorrecta aumenta wrong_count"
        );


        // =====================================================
        // PRUEBA 6 - MODO DIFICIL
        // =====================================================

        do_reset();
        press_hard();

        check(
            game_active == 1,
            "BTND inicia una partida"
        );

        check(
            hard_mode == 1,
            "BTND selecciona modo DIFICIL"
        );

        check(
            time_left == HARD_TIME,
            "Modo DIFICIL carga el tiempo correcto"
        );

        check(
            word_length >= 6,
            "Modo DIFICIL usa palabras de al menos 6 letras"
        );


        // =====================================================
        // PRUEBA 7 - SEIS ERRORES
        // =====================================================

        do_reset();
        press_easy();

        for (n = 0; n < 6; n = n + 1) begin

            send_letter(
                wrong_letter(n)
            );

            if (n < 5) begin

                check(
                    wrong_count == n + 1,
                    $sformatf(
                        "Error %0d registrado correctamente",
                        n + 1
                    )
                );

                check(
                    game_active == 1,
                    "La partida sigue antes del sexto error"
                );

            end

        end

        check(
            wrong_count == 6,
            "El sexto error deja wrong_count en 6"
        );

        check(
            result_active == 1,
            "El sexto error termina la partida"
        );

        check(
            result_win == 0,
            "Seis errores producen DERROTA"
        );


        // Esperar regreso automático al menú
        wait(menu_active);

        check(
            menu_active == 1,
            "Después del resultado vuelve al MENU"
        );


        // =====================================================
        // PRUEBA 8 - TIMEOUT
        // =====================================================

        do_reset();
        press_hard();

        wait(result_active);

        check(
            time_left == 0,
            "El temporizador llega a cero"
        );

        check(
            result_win == 0,
            "Timeout produce DERROTA"
        );


        // =====================================================
        // PRUEBA 9 - VICTORIA
        // =====================================================

        do_reset();
        press_easy();

        complete_word();

        check(
            result_active == 1,
            "Completar la palabra termina la partida"
        );

        check(
            result_win == 1,
            "Completar la palabra produce VICTORIA"
        );

        check(
            victories == 1,
            "La victoria incrementa el contador"
        );


        // =====================================================
        // PRUEBA 10 - RESET DE VICTORIAS
        // =====================================================

        do_reset();

        check(
            victories == 0,
            "Reset limpia el contador de victorias"
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