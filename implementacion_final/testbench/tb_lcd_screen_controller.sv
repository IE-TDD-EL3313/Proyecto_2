
`timescale 1ns / 1ps

module tb_lcd_screen_controller;

    logic clk = 0;
    logic rst = 0;

    logic game_active   = 0;
    logic result_active = 0;
    logic result_win    = 0;

    logic [95:0] selected_word = 0;
    logic [3:0]  word_length = 0;
    logic [11:0] revealed_mask = 0;
    logic [6:0]  time_left = 0;
    logic [2:0]  wrong_count = 0;

    logic        write_enable;
    logic [1:0]  addr;
    logic [31:0] wdata;
    logic [31:0] rdata = 0;

    localparam CONTROL = 2'b00;
    localparam DATA    = 2'b01;

    logic [7:0] data_reg;
    logic [7:0] captured [0:31];

    integer char_count = 0;
    integer errors = 0;
    integer busy_count = 0;


    lcd_screen_controller dut (
        .clk            (clk),
        .rst            (rst),

        .game_active    (game_active),
        .result_active  (result_active),
        .result_win     (result_win),

        .selected_word  (selected_word),
        .word_length    (word_length),
        .revealed_mask  (revealed_mask),
        .time_left      (time_left),
        .wrong_count    (wrong_count),

        .write_enable_o (write_enable),
        .addr_o         (addr),
        .wdata_o        (wdata),
        .rdata_i        (rdata)
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


    // Simula el comportamiento mínimo de lcd_peripheral:
    // guarda DATA y genera BUSY después de START.
    always_ff @(posedge clk) begin

        if (rst) begin
            data_reg   <= 0;
            rdata      <= 0;
            busy_count <= 0;
            char_count <= 0;
        end

        else begin

            if (busy_count > 0) begin
                busy_count <= busy_count - 1;
                rdata[8]   <= 1;
            end
            else begin
                rdata[8] <= 0;
            end


            if (write_enable && addr == DATA)
                data_reg <= wdata[7:0];


            if (write_enable &&
                addr == CONTROL &&
                wdata[0]) begin

                busy_count <= 2;

                // Solo guardar caracteres, no comandos 80/C0
                if (wdata[1]) begin
                    captured[char_count] <= data_reg;
                    char_count <= char_count + 1;
                end
            end
        end
    end


    task automatic wait_screen;
        begin
            wait(char_count >= 32);
            repeat (5) @(posedge clk);
        end
    endtask


    task automatic clear_capture;
        integer k;
        begin
            char_count = 0;

            for (k = 0; k < 32; k = k + 1)
                captured[k] = " ";
        end
    endtask


    task automatic check_char(
        input integer pos,
        input logic [7:0] expected,
        input string message
    );
        begin
            check(
                captured[pos] == expected,
                message
            );
        end
    endtask


    initial begin

        $display("");
        $display("======================================");
        $display("   TESTBENCH LCD_SCREEN_CONTROLLER");
        $display("======================================");
        $display("");


        // =====================================================
        // MENU
        // =====================================================

        do_reset();
        wait_screen();

        check_char(0,  "M", "Menu linea 1 inicia con M");
        check_char(1,  "O", "Menu linea 1 contiene O");
        check_char(5,  "F", "Menu muestra FACIL");

        check_char(16, "M", "Menu linea 2 inicia con M");
        check_char(21, "D", "Menu muestra DIFICIL");

        $display("PASS: Pantalla MENU generada");


        // =====================================================
        // PARTIDA
        //
        // Palabra: CASA
        // Reveladas: C _ S _
        //
        // P:C_S_
        // T:45 Y INT:5
        // =====================================================

        clear_capture();

        selected_word = "CASA        ";
        word_length   = 4;
        revealed_mask = 12'b0000_0101;

        time_left   = 45;
        wrong_count = 1;

        game_active   = 1;
        result_active = 0;

        wait_screen();

        check_char(0, "P", "Juego muestra P");
        check_char(1, ":", "Juego muestra ':'");

        check_char(2, "C", "Primera letra revelada");
        check_char(3, "_", "Segunda letra oculta");
        check_char(4, "S", "Tercera letra revelada");
        check_char(5, "_", "Cuarta letra oculta");

        check_char(16, "T", "Linea 2 muestra T");
        check_char(17, ":", "Linea 2 muestra ':'");

        check_char(18, "4", "Tiempo decenas = 4");
        check_char(19, "5", "Tiempo unidades = 5");

        check_char(21, "Y", "Linea 2 contiene Y");

        check_char(23, "I", "INT inicia con I");
        check_char(24, "N", "INT contiene N");
        check_char(25, "T", "INT contiene T");
        check_char(26, ":", "INT contiene ':'");
        check_char(27, "5", "Intentos restantes = 5");

        $display("PASS: Pantalla de JUEGO generada");


        // =====================================================
        // VICTORIA
        // =====================================================

        clear_capture();

        game_active   = 0;
        result_active = 1;
        result_win    = 1;

        wait_screen();

        check_char(0, "R", "Victoria muestra RESULTADO");
        check_char(16, "G", "Victoria linea 2 inicia G");
        check_char(17, "A", "Victoria contiene A");
        check_char(18, "N", "Victoria contiene N");
        check_char(19, "O", "Victoria contiene O");

        $display("PASS: Pantalla de VICTORIA generada");


        // =====================================================
        // DERROTA
        //
        // Debe mostrar la palabra completa
        // =====================================================

        clear_capture();

        selected_word = "CIRCUITO    ";
        word_length   = 8;

        result_active = 1;
        result_win    = 0;

        wait_screen();

        check_char(0, "P", "Derrota muestra PERDIO");
        check_char(1, "E", "Derrota contiene E");

        check_char(16, "P", "Linea 2 inicia P:");
        check_char(17, ":", "Linea 2 contiene ':'");

        check_char(18, "C", "Palabra final posicion 1");
        check_char(19, "I", "Palabra final posicion 2");
        check_char(20, "R", "Palabra final posicion 3");
        check_char(21, "C", "Palabra final posicion 4");
        check_char(22, "U", "Palabra final posicion 5");
        check_char(23, "I", "Palabra final posicion 6");
        check_char(24, "T", "Palabra final posicion 7");
        check_char(25, "O", "Palabra final posicion 8");

        $display("PASS: Pantalla de DERROTA revela palabra");


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