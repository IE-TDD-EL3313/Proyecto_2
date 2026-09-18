module uart_game_interface #(
    parameter int CLK_FREQ  = 100_000_000,
    parameter int BAUD_RATE = 115200
)(
    input  logic        clk,
    input  logic        rst,

    input  logic        uart_rx_i,
    output logic        uart_tx_o,

    output logic [7:0]  letter,
    output logic        letter_valid,

    input  logic        hard_mode,
    input  logic        game_active,
    input  logic        result_active,
    input  logic        result_win,

    input  logic [95:0] selected_word,
    input  logic [3:0]  word_length,
    input  logic [11:0] revealed_mask,
    input  logic [2:0]  wrong_count,

    input  logic        letter_processed,
    input  logic        letter_correct,
    input  logic        letter_wrong,
    input  logic        letter_repeated
);

    localparam DATA_TX = 2'b00,
               DATA_RX = 2'b01,
               CONTROL = 2'b10;

    logic        we;
    logic [1:0]  addr;
    logic [31:0] wdata, rdata;

    uart_peripheral #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uart (
        .clk_i(clk), .rst_i(rst),
        .write_enable_i(we),
        .addr_i(addr),
        .wdata_i(wdata),
        .rdata_o(rdata),
        .uart_rx_i(uart_rx_i),
        .uart_tx_o(uart_tx_o)
    );


    typedef enum logic [2:0] {
        IDLE, RX_READ, RX_CLEAR,
        TX_LOAD, TX_START, TX_WAIT
    } state_t;

    state_t state;

    logic [7:0] tx_buffer [0:17];
    logic [4:0] tx_index, tx_length;

    logic game_d, result_d;
    logic pending_start, pending_letter, pending_end;

    logic start_mode;
    logic [3:0] start_length;

    logic [7:0] letter_snap, letter_result;
    logic [2:0] attempts_snap;
    logic [3:0] length_snap;
    logic [11:0] revealed_snap;
    logic [95:0] word_snap;

    logic end_win;
    logic [7:0] end_cause;
    logic [3:0] end_length;
    logic [95:0] end_word;

    logic [7:0] rx_byte;

    integer i;


    // Bus hacia uart_peripheral
    always_comb begin
        we    = 0;
        addr  = CONTROL;
        wdata = 0;

        case (state)

            RX_READ:
                addr = DATA_RX;

            RX_CLEAR: begin
                addr = CONTROL;
                we   = 1;
                wdata = 0;
            end

            TX_LOAD: begin
                addr = DATA_TX;
                we   = 1;
                wdata[7:0] = tx_buffer[tx_index];
            end

            TX_START: begin
                addr = CONTROL;
                we   = 1;
                wdata = 32'h3;
            end

            default:
                addr = CONTROL;

        endcase
    end


    always_ff @(posedge clk) begin

        if (rst) begin

            state          <= IDLE;
            letter         <= 0;
            letter_valid   <= 0;

            game_d         <= 0;
            result_d       <= 0;

            pending_start  <= 0;
            pending_letter <= 0;
            pending_end    <= 0;

            tx_index       <= 0;
            tx_length      <= 0;
            rx_byte        <= 0;

        end

        else begin

            letter_valid <= 0;

            game_d   <= game_active;
            result_d <= result_active;


            // Nueva partida
            if (game_active && !game_d) begin
                start_mode    <= hard_mode;
                start_length  <= word_length;
                pending_start <= 1;
            end


            // Resultado de una letra
            if (letter_processed) begin

                letter_snap   <= letter;
                length_snap   <= word_length;
                revealed_snap <= revealed_mask;
                word_snap     <= selected_word;

                attempts_snap <= (wrong_count >= 6)
                               ? 0
                               : 6 - wrong_count;

                if (letter_correct)
                    letter_result <= 8'h01;
                else if (letter_wrong)
                    letter_result <= 8'h02;
                else
                    letter_result <= 8'h03;

                pending_letter <= 1;
            end


            // Fin de partida
            if (result_active && !result_d) begin

                end_win    <= result_win;
                end_length <= word_length;
                end_word   <= selected_word;

                if (result_win)
                    end_cause <= 8'h01;
                else if (wrong_count >= 6)
                    end_cause <= 8'h02;
                else
                    end_cause <= 8'h03;

                pending_end <= 1;
            end


            case (state)

                // =================================================
                // ESPERA
                // =================================================

                IDLE: begin

                    // A5 01 MODO LONGITUD
                    if (pending_start) begin

                        tx_buffer[0] <= 8'hA5;
                        tx_buffer[1] <= 8'h01;
                        tx_buffer[2] <= start_mode;
                        tx_buffer[3] <= start_length;

                        tx_length <= 4;
                        tx_index  <= 0;

                        pending_start <= 0;
                        state <= TX_LOAD;
                    end


                    // A5 02 LETRA RESULTADO INT LONG PATRON[12]
                    else if (pending_letter) begin

                        tx_buffer[0] <= 8'hA5;
                        tx_buffer[1] <= 8'h02;
                        tx_buffer[2] <= letter_snap;
                        tx_buffer[3] <= letter_result;
                        tx_buffer[4] <= attempts_snap;
                        tx_buffer[5] <= length_snap;

                        for (i = 0; i < 12; i = i + 1)
                            tx_buffer[6+i] <=
                                (i < length_snap)
                                ? (revealed_snap[i]
                                   ? word_snap[95-i*8 -: 8]
                                   : "_")
                                : " ";

                        tx_length <= 18;
                        tx_index  <= 0;

                        pending_letter <= 0;
                        state <= TX_LOAD;
                    end


                    // A5 03 RESULTADO CAUSA LONG PALABRA[12]
                    else if (pending_end) begin

                        tx_buffer[0] <= 8'hA5;
                        tx_buffer[1] <= 8'h03;
                        tx_buffer[2] <= end_win;
                        tx_buffer[3] <= end_cause;
                        tx_buffer[4] <= end_length;

                        for (i = 0; i < 12; i = i + 1)
                            tx_buffer[5+i] <=
                                (i < end_length)
                                ? end_word[95-i*8 -: 8]
                                : " ";

                        tx_length <= 17;
                        tx_index  <= 0;

                        pending_end <= 0;
                        state <= TX_LOAD;
                    end


                    // Byte recibido desde Python
                    else if (rdata[1])
                        state <= RX_READ;

                end


                // Leer RX
                RX_READ: begin
                    rx_byte <= rdata[7:0];
                    state   <= RX_CLEAR;
                end


                // Limpiar new_rx y entregar A-Z
                RX_CLEAR: begin

                    if (rx_byte >= "A" && rx_byte <= "Z") begin
                        letter       <= rx_byte;
                        letter_valid <= 1;
                    end

                    state <= IDLE;
                end


                // Cargar byte TX
                TX_LOAD:
                    state <= TX_START;


                // Iniciar byte TX
                TX_START:
                    state <= TX_WAIT;


                // Esperar fin del byte
                TX_WAIT: begin

                    if (!rdata[0]) begin

                        if (tx_index == tx_length - 1)
                            state <= IDLE;

                        else begin
                            tx_index <= tx_index + 1;
                            state    <= TX_LOAD;
                        end

                    end
                end


                default:
                    state <= IDLE;

            endcase
        end
    end

endmodule