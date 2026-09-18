module game_core #(
    parameter int CLK_FREQ    = 100_000_000,
    parameter int EASY_TIME   = 60,
    parameter int HARD_TIME   = 45,
    parameter int RESULT_TIME = 3
)(
    input  logic        clk,
    input  logic        rst,
    input  logic        btn_easy,
    input  logic        btn_hard,

    input  logic [7:0]  letter,
    input  logic        letter_valid,

    output logic        hard_mode,
    output logic        menu_active,
    output logic        game_active,
    output logic        result_active,
    output logic        result_win,

    output logic [95:0] selected_word,
    output logic [3:0]  word_length,
    output logic [11:0] revealed_mask,
    output logic [2:0]  wrong_count,
    output logic [6:0]  time_left,
    output logic [6:0]  victories,

    output logic        letter_processed,
    output logic        letter_correct,
    output logic        letter_wrong,
    output logic        letter_repeated
);

    typedef enum logic [1:0] {MENU, GAME, RESULT} state_t;
    state_t state;

    logic [7:0]  lfsr = 8'h1;
    logic [5:0]  last_index = 6'h3F;
    logic [25:0] used_letters;

    logic [31:0] sec_count;
    logic [2:0]  result_secs;

    logic btn_easy_d, btn_hard_d;

    wire easy_pulse = btn_easy & ~btn_easy_d;
    wire hard_pulse = btn_hard & ~btn_hard_d;

    wire [5:0] easy_index = lfsr % 50;
    wire [5:0] hard_index = 20 + (lfsr % 30);

    logic [5:0] candidate_index;
    logic [95:0] candidate_word;
    logic [3:0] candidate_length;

    logic [11:0] match_mask;
    logic [11:0] valid_mask;

    integer i;


    assign menu_active   = (state == MENU);
    assign game_active   = (state == GAME);
    assign result_active = (state == RESULT);


    // Elegir índice según dificultad y evitar repetición inmediata
    always_comb begin
        candidate_index = hard_pulse ? hard_index : easy_index;

        if (candidate_index == last_index) begin
            if (hard_pulse)
                candidate_index = (candidate_index == 49) ? 20
                                                         : candidate_index + 1;
            else
                candidate_index = (candidate_index == 49) ? 0
                                                         : candidate_index + 1;
        end
    end


    word_bank u_word_bank (
        .index  (candidate_index),
        .word   (candidate_word),
        .length (candidate_length)
    );


    // Buscar todas las posiciones donde aparece la letra
    always_comb begin
        match_mask = 12'b0;

        for (i = 0; i < 12; i = i + 1)
            if (i < word_length &&
                selected_word[95-i*8 -: 8] == letter)
                match_mask[i] = 1'b1;
    end


    // Bits válidos de la palabra actual
    always_comb begin
        if (word_length == 0)
            valid_mask = 12'b0;
        else
            valid_mask = 12'hFFF >> (12 - word_length);
    end


    always_ff @(posedge clk) begin

        if (rst) begin
            state            <= MENU;
            hard_mode        <= 0;
            result_win       <= 0;

            selected_word    <= 0;
            word_length      <= 0;
            revealed_mask    <= 0;
            used_letters     <= 0;
            wrong_count      <= 0;

            time_left        <= 0;
            victories        <= 0;

            sec_count        <= 0;
            result_secs      <= 0;

            lfsr             <= 8'h1;
            last_index       <= 6'h3F;

            btn_easy_d       <= 0;
            btn_hard_d       <= 0;

            letter_processed <= 0;
            letter_correct   <= 0;
            letter_wrong     <= 0;
            letter_repeated  <= 0;
        end

        else begin

            btn_easy_d <= btn_easy;
            btn_hard_d <= btn_hard;

            letter_processed <= 0;
            letter_correct   <= 0;
            letter_wrong     <= 0;
            letter_repeated  <= 0;


            case (state)

                MENU: begin

                    sec_count <= 0;

                    // LFSR pseudoaleatorio
                    lfsr <= {
                        lfsr[6:0],
                        lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3]
                    };

                    if (easy_pulse || hard_pulse) begin

                        hard_mode     <= hard_pulse;
                        selected_word <= candidate_word;
                        word_length   <= candidate_length;
                        last_index    <= candidate_index;

                        revealed_mask <= 0;
                        used_letters  <= 0;
                        wrong_count   <= 0;
                        result_win    <= 0;

                        time_left <= hard_pulse ? HARD_TIME
                                               : EASY_TIME;

                        state <= GAME;
                    end
                end


                GAME: begin

                    // Procesar letra A-Z
                    if (letter_valid &&
                        letter >= "A" &&
                        letter <= "Z") begin

                        letter_processed <= 1;

                        if (used_letters[letter-"A"]) begin
                            letter_repeated <= 1;
                        end

                        else begin
                            used_letters[letter-"A"] <= 1;

                            // Correcta
                            if (match_mask != 0) begin
                                letter_correct <= 1;
                                revealed_mask <= revealed_mask | match_mask;

                                if ((revealed_mask | match_mask) == valid_mask) begin
                                    result_win <= 1;
                                    victories <= (victories == 99)
                                                 ? 0
                                                 : victories + 1;

                                    sec_count   <= 0;
                                    result_secs <= 0;
                                    state       <= RESULT;
                                end
                            end

                            // Incorrecta
                            else begin
                                letter_wrong <= 1;

                                if (wrong_count == 5) begin
                                    wrong_count <= 6;
                                    result_win  <= 0;
                                    sec_count   <= 0;
                                    result_secs <= 0;
                                    state       <= RESULT;
                                end
                                else
                                    wrong_count <= wrong_count + 1;
                            end
                        end
                    end


                    // Temporizador
                    else if (sec_count == CLK_FREQ-1) begin
                        sec_count <= 0;

                        if (time_left <= 1) begin
                            time_left   <= 0;
                            result_win  <= 0;
                            result_secs <= 0;
                            state       <= RESULT;
                        end
                        else
                            time_left <= time_left - 1;
                    end

                    else
                        sec_count <= sec_count + 1;
                end


                RESULT: begin

                    if (sec_count == CLK_FREQ-1) begin
                        sec_count <= 0;

                        if (result_secs == RESULT_TIME-1) begin
                            result_secs <= 0;
                            state <= MENU;
                        end
                        else
                            result_secs <= result_secs + 1;
                    end

                    else
                        sec_count <= sec_count + 1;
                end


                default:
                    state <= MENU;

            endcase
        end
    end

endmodule