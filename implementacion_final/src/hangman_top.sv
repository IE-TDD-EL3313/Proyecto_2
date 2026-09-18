module hangman_top (
    input  logic       CLK100MHZ,

    input  logic       btnC,
    input  logic       btnU,
    input  logic       btnD,

    input  logic       RsRx,
    output logic       RsTx,

    output logic       lcd_rs,
    output logic       lcd_rw,
    output logic       lcd_e,
    output logic [7:0] lcd_data,

    output logic [3:0] led,

    output logic [6:0] seg,
    output logic [3:0] an,
    output logic       dp,

    output logic       buzzer_out
);

    logic hard_mode, menu_active, game_active;
    logic result_active, result_win;

    logic [95:0] selected_word;
    logic [3:0]  word_length;
    logic [11:0] revealed_mask;
    logic [2:0]  wrong_count;
    logic [6:0]  time_left, victories;

    logic [7:0] letter;
    logic letter_valid;
    logic letter_processed, letter_correct;
    logic letter_wrong, letter_repeated;

    logic        lcd_we;
    logic [1:0]  lcd_addr;
    logic [31:0] lcd_wdata, lcd_rdata;


    // Juego
    game_core game (
        .clk              (CLK100MHZ),
        .rst              (btnC),
        .btn_easy         (btnU),
        .btn_hard         (btnD),

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


    // UART PC <-> FPGA
    uart_game_interface uart_game (
        .clk              (CLK100MHZ),
        .rst              (btnC),

        .uart_rx_i        (RsRx),
        .uart_tx_o        (RsTx),

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


    // Texto mostrado en LCD
    lcd_screen_controller lcd_screen (
        .clk            (CLK100MHZ),
        .rst            (btnC),

        .game_active    (game_active),
        .result_active  (result_active),
        .result_win     (result_win),

        .selected_word  (selected_word),
        .word_length    (word_length),
        .revealed_mask  (revealed_mask),
        .time_left      (time_left),
        .wrong_count    (wrong_count),

        .write_enable_o (lcd_we),
        .addr_o         (lcd_addr),
        .wdata_o        (lcd_wdata),
        .rdata_i        (lcd_rdata)
    );


    // Interfaz física PmodCLP
    lcd_peripheral lcd (
        .clk_i          (CLK100MHZ),
        .rst_i          (btnC),

        .write_enable_i (lcd_we),
        .addr_i         (lcd_addr),
        .wdata_i        (lcd_wdata),
        .rdata_o        (lcd_rdata),

        .lcd_rs         (lcd_rs),
        .lcd_rw         (lcd_rw),
        .lcd_e          (lcd_e),
        .lcd_data       (lcd_data)
    );


    // Display + buzzer
    io_controller io (
        .clk            (CLK100MHZ),
        .rst            (btnC),

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


    // LEDs de estado
    assign led[0] = menu_active;
    assign led[1] = game_active;
    assign led[2] = result_active;
    assign led[3] = hard_mode;

endmodule