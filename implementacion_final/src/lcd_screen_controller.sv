module lcd_screen_controller (
    input  logic        clk,
    input  logic        rst,

    input  logic        game_active,
    input  logic        result_active,
    input  logic        result_win,

    input  logic [95:0] selected_word,
    input  logic [3:0]  word_length,
    input  logic [11:0] revealed_mask,
    input  logic [6:0]  time_left,
    input  logic [2:0]  wrong_count,

    output logic        write_enable_o,
    output logic [1:0]  addr_o,
    output logic [31:0] wdata_o,
    input  logic [31:0] rdata_i
);

    localparam CONTROL = 2'b00,
               DATA    = 2'b01;

    logic [127:0] line1, line2;
    logic [127:0] snap1, snap2;
    logic [127:0] shown1, shown2;
    logic shown_valid;

    integer i;


    // Construir las dos líneas del LCD
    always_comb begin

        line1 = "MODO FACIL      ";
        line2 = "MODO DIFICIL    ";

        // Partida
        if (game_active) begin

            line1 = "P:              ";
            line2 = "T:00 Y INT:0    ";

            for (i = 0; i < 12; i = i + 1) begin
                if (i < word_length)
                    line1[127-(i+2)*8 -: 8] =
                        revealed_mask[i]
                        ? selected_word[95-i*8 -: 8]
                        : "_";
            end

            line2[127-2*8 -: 8] = "0" + (time_left / 10);
            line2[127-3*8 -: 8] = "0" + (time_left % 10);

            line2[127-11*8 -: 8] =
                (wrong_count >= 6)
                ? "0"
                : "0" + (6 - wrong_count);
        end


        // Resultado
        if (result_active) begin

            if (result_win) begin

                line1 = "RESULTADO:      ";
                line2 = "GANO            ";

            end

            else begin

                line1 = "PERDIO:         ";
                line2 = "P:              ";

                // Mostrar la palabra completa al perder
                for (i = 0; i < 12; i = i + 1)
                    if (i < word_length)
                        line2[127-(i+2)*8 -: 8] =
                            selected_word[95-i*8 -: 8];

            end
        end
    end


    // Cada pantalla requiere:
    //
    // paso 0      -> comando línea 1
    // pasos 1-16  -> 16 caracteres línea 1
    // paso 17     -> comando línea 2
    // pasos 18-33 -> 16 caracteres línea 2

    typedef enum logic [1:0] {
        IDLE, LOAD, START, WAIT_LCD
    } state_t;

    state_t state;

    logic [5:0] step;
    logic [7:0] lcd_byte;
    logic       lcd_rs_value;


    // Byte correspondiente al paso actual
    always_comb begin

        lcd_byte     = 8'h20;
        lcd_rs_value = 1'b1;

        if (step == 0) begin
            lcd_byte     = 8'h80;
            lcd_rs_value = 1'b0;
        end

        else if (step <= 16)
            lcd_byte =
                snap1[127-(step-1)*8 -: 8];

        else if (step == 17) begin
            lcd_byte     = 8'hC0;
            lcd_rs_value = 1'b0;
        end

        else
            lcd_byte =
                snap2[127-(step-18)*8 -: 8];

    end


    // Bus hacia lcd_peripheral
    always_comb begin

        write_enable_o = 0;
        addr_o          = CONTROL;
        wdata_o         = 0;

        if (state == LOAD) begin

            write_enable_o = 1;
            addr_o          = DATA;
            wdata_o[7:0]    = lcd_byte;

        end

        else if (state == START) begin

            write_enable_o = 1;
            addr_o          = CONTROL;

            wdata_o[0] = 1;             // start
            wdata_o[1] = lcd_rs_value;  // RS

        end
    end


    // Control de escritura
    always_ff @(posedge clk) begin

        if (rst) begin

            state       <= IDLE;
            step        <= 0;

            snap1       <= 0;
            snap2       <= 0;
            shown1      <= 0;
            shown2      <= 0;
            shown_valid <= 0;

        end

        else begin

            case (state)

                // Redibujar solo si cambió algo
                IDLE: begin

                    if (!rdata_i[8] &&
                        (!shown_valid ||
                         line1 != shown1 ||
                         line2 != shown2)) begin

                        snap1 <= line1;
                        snap2 <= line2;
                        step  <= 0;

                        state <= LOAD;
                    end
                end


                LOAD:
                    state <= START;


                START:
                    state <= WAIT_LCD;


                WAIT_LCD: begin

                    if (!rdata_i[8]) begin

                        if (step == 33) begin

                            shown1      <= snap1;
                            shown2      <= snap2;
                            shown_valid <= 1;

                            state <= IDLE;

                        end

                        else begin

                            step  <= step + 1;
                            state <= LOAD;

                        end
                    end
                end


                default:
                    state <= IDLE;

            endcase
        end
    end

endmodule