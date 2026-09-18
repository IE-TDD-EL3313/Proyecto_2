`timescale 1ns / 1ps

module tb_io_controller;

    // CLK_FREQ = 1000 hace que MS_DIV = 1
    // y permite simular los sonidos rápidamente.
    localparam int CLK_FREQ = 1000;

    logic clk = 0;
    logic rst = 0;

    logic [6:0] time_left = 0;
    logic [6:0] victories = 0;

    logic letter_correct = 0;
    logic letter_wrong   = 0;
    logic result_active  = 0;
    logic result_win     = 0;

    logic [6:0] seg;
    logic [3:0] an;
    logic       dp;
    logic       buzzer_out;

    integer errors = 0;


    io_controller #(
        .CLK_FREQ(CLK_FREQ)
    ) dut (
        .clk            (clk),
        .rst            (rst),

        .time_left      (time_left),
        .victories      (victories),

        .letter_correct (letter_correct),
        .letter_wrong   (letter_wrong),
        .result_active  (result_active),
        .result_win     (result_win),

        .seg            (seg),
        .an             (an),
        .dp             (dp),
        .buzzer_out     (buzzer_out)
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


    task automatic do_reset;
        begin
            rst = 1;
            repeat (3) @(posedge clk);
            rst = 0;
            @(negedge clk);
        end
    endtask


    task automatic pulse_correct;
        begin
            @(negedge clk);
            letter_correct = 1;
            @(negedge clk);
            letter_correct = 0;
        end
    endtask


    task automatic pulse_wrong;
        begin
            @(negedge clk);
            letter_wrong = 1;
            @(negedge clk);
            letter_wrong = 0;
        end
    endtask


    initial begin

        $display("");
        $display("======================================");
        $display("      TESTBENCH IO_CONTROLLER");
        $display("======================================");
        $display("");


        // ==============================================
        // RESET
        // ==============================================

        do_reset();

        check(
            buzzer_out == 0,
            "Reset deja el buzzer apagado"
        );

        check(
            dp == 1,
            "Punto decimal permanece apagado"
        );


        // ==============================================
        // 7 SEGMENTOS
        //
        // tiempo = 45
        // victorias = 12
        //
        // Display esperado: 4512
        // ==============================================

        time_left = 45;
        victories = 12;

        // AN0 -> unidades victorias = 2
        wait(an == 4'b1110);
        #1;

        check(
            seg == 7'b0100100,
            "AN0 muestra unidades de victorias = 2"
        );


        // AN1 -> decenas victorias = 1
        wait(an == 4'b1101);
        #1;

        check(
            seg == 7'b1111001,
            "AN1 muestra decenas de victorias = 1"
        );


        // AN2 -> unidades tiempo = 5
        wait(an == 4'b1011);
        #1;

        check(
            seg == 7'b0010010,
            "AN2 muestra unidades de tiempo = 5"
        );


        // AN3 -> decenas tiempo = 4
        wait(an == 4'b0111);
        #1;

        check(
            seg == 7'b0011001,
            "AN3 muestra decenas de tiempo = 4"
        );


        // ==============================================
        // LETRA CORRECTA
        // ==============================================

        pulse_correct();

        check(
            buzzer_out == 1,
            "Letra correcta enciende el buzzer"
        );

        wait(buzzer_out == 0);

        check(
            buzzer_out == 0,
            "Pitido de correcta termina"
        );


        // ==============================================
        // LETRA INCORRECTA
        // Debe producir dos pitidos
        // ==============================================

        pulse_wrong();

        check(
            buzzer_out == 1,
            "Incorrecta inicia primer pitido"
        );

        wait(buzzer_out == 0);

        check(
            buzzer_out == 0,
            "Incorrecta genera pausa entre pitidos"
        );

        wait(buzzer_out == 1);

        check(
            buzzer_out == 1,
            "Incorrecta genera segundo pitido"
        );

        wait(buzzer_out == 0);

        check(
            buzzer_out == 0,
            "Patron de incorrecta termina"
        );


        // ==============================================
        // VICTORIA
        // Tres pitidos
        // ==============================================

        @(negedge clk);
        result_win    = 1;
        result_active = 1;

        @(negedge clk);
        result_active = 0;

        check(
            buzzer_out == 1,
            "Victoria inicia primer pitido"
        );

        wait(buzzer_out == 0);
        wait(buzzer_out == 1);

        check(
            buzzer_out == 1,
            "Victoria genera segundo pitido"
        );

        wait(buzzer_out == 0);
        wait(buzzer_out == 1);

        check(
            buzzer_out == 1,
            "Victoria genera tercer pitido"
        );

        wait(buzzer_out == 0);

        check(
            buzzer_out == 0,
            "Patron de victoria termina"
        );


        // ==============================================
        // DERROTA
        // Un pitido largo
        // ==============================================

        // Dejamos result_active en cero un momento
        // para permitir otro flanco de subida.
        repeat (3) @(posedge clk);

        @(negedge clk);
        result_win    = 0;
        result_active = 1;

        @(negedge clk);
        result_active = 0;

        check(
            buzzer_out == 1,
            "Derrota enciende el buzzer"
        );

        // Debe seguir activo después de 100 ciclos,
        // porque la derrota dura 600 ms simulados.
        repeat (100) @(posedge clk);

        check(
            buzzer_out == 1,
            "Pitido de derrota es largo"
        );

        wait(buzzer_out == 0);

        check(
            buzzer_out == 0,
            "Pitido de derrota termina"
        );


        // ==============================================
        // RESULTADO FINAL
        // ==============================================

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