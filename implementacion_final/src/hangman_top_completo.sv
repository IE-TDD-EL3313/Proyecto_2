// =============================================================================
// TOP COMPLETO DEL JUEGO DE AHORCADO - BASYS 3
// =============================================================================
// Asignacion funcional de botones:
//   btnC = BTN_RST: reinicio general
//   btnU = BTN_SEL: alterna entre FACIL y DIFICIL
//   btnD = BTN_OK : confirma el modo e inicia la partida
//
// Este top agrega al diseño original:
//   1. Sincronizacion y antirrebote para BTN_SEL y BTN_OK.
//   2. Registro del modo seleccionado mientras el sistema esta en MENU.
//   3. Inicio de partida solamente al confirmar con BTN_OK.
//   4. Indicación visible de la opcion seleccionada en el LCD.
//
// El resto de funciones se delega a modulos especializados. Toda la logica
// trabaja con CLK100MHZ; los divisores producen habilitaciones, no relojes.
// =============================================================================
module hangman_top_completo #(
    // Valores reales por defecto. El testbench puede reducirlos para acelerar
    // la simulación sin modificar el comportamiento del bitstream.
    parameter int CLK_FREQ    = 100_000_000,
    parameter int BAUD_RATE   = 115200,
    parameter int EASY_TIME   = 60,
    parameter int HARD_TIME   = 45,
    parameter int RESULT_TIME = 3,
    parameter int DEBOUNCE_MS = 20
)(
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

    // -------------------------------------------------------------------------
    // Entradas locales
    // -------------------------------------------------------------------------
    logic sel_level, ok_level;
    logic sel_level_d, ok_level_d;
    logic sel_pulse, ok_pulse;
    logic selected_mode;             // 0=FACIL, 1=DIFICIL
    logic start_easy, start_hard;

    // -------------------------------------------------------------------------
    // Estado compartido del juego
    // -------------------------------------------------------------------------
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

    // Bus comun de 32 bits hacia el periferico LCD.
    logic        lcd_we;
    logic [1:0]  lcd_addr;
    logic [31:0] lcd_wdata, lcd_rdata;

    // Los botones son asincronos y mecanicos. Cada instancia sincroniza la
    // señal y exige 20 ms de estabilidad antes de cambiar su salida.
    button_conditioner #(
        .CLK_FREQ    (CLK_FREQ),
        .DEBOUNCE_MS (DEBOUNCE_MS)
    ) condition_sel (
        .clk      (CLK100MHZ),
        .rst      (btnC),
        .button_i (btnU),
        .level_o  (sel_level)
    );

    button_conditioner #(
        .CLK_FREQ    (CLK_FREQ),
        .DEBOUNCE_MS (DEBOUNCE_MS)
    ) condition_ok (
        .clk      (CLK100MHZ),
        .rst      (btnC),
        .button_i (btnD),
        .level_o  (ok_level)
    );

    // Deteccion de flancos y registro de la opcion mostrada. BTN_SEL solo
    // cambia la seleccion en MENU. BTN_OK produce uno de los dos pulsos start.
    always_ff @(posedge CLK100MHZ) begin
        if (btnC) begin
            sel_level_d   <= 1'b0;
            ok_level_d    <= 1'b0;
            selected_mode <= 1'b0;
        end
        else begin
            sel_level_d <= sel_level;
            ok_level_d  <= ok_level;

            if (menu_active && sel_pulse)
                selected_mode <= ~selected_mode;
        end
    end

    assign sel_pulse  = sel_level & ~sel_level_d;
    assign ok_pulse   = ok_level  & ~ok_level_d;
    assign start_easy = menu_active & ok_pulse & ~selected_mode;
    assign start_hard = menu_active & ok_pulse &  selected_mode;

    // -------------------------------------------------------------------------
    // Nucleo del juego
    // -------------------------------------------------------------------------
    game_core #(
        .CLK_FREQ    (CLK_FREQ),
        .EASY_TIME   (EASY_TIME),
        .HARD_TIME   (HARD_TIME),
        .RESULT_TIME (RESULT_TIME)
    ) game (
        .clk              (CLK100MHZ),
        .rst              (btnC),
        .btn_easy         (start_easy),
        .btn_hard         (start_hard),
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

    // -------------------------------------------------------------------------
    // Comunicacion PC <-> FPGA
    // -------------------------------------------------------------------------
    uart_game_interface #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) uart_game (
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

    // -------------------------------------------------------------------------
    // Contenido e interfaz fisica del LCD
    // -------------------------------------------------------------------------
    lcd_screen_controller_completo lcd_screen (
        .clk            (CLK100MHZ),
        .rst            (btnC),
        .selected_mode  (selected_mode),
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

    lcd_peripheral #(
        .CLK_FREQ (CLK_FREQ)
    ) lcd (
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

    // -------------------------------------------------------------------------
    // Indicadores locales
    // -------------------------------------------------------------------------
    io_controller #(
        .CLK_FREQ (CLK_FREQ)
    ) io (
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

    // LED0..2 indican la etapa. LED3 muestra la opcion en MENU y el modo real
    // durante una partida o resultado.
    assign led[0] = menu_active;
    assign led[1] = game_active;
    assign led[2] = result_active;
    assign led[3] = menu_active ? selected_mode : hard_mode;

endmodule


// =============================================================================
// ACONDICIONADOR DE BOTON
// =============================================================================
// Dos flip-flops reducen metaestabilidad. El contador cambia level_o solamente
// si la muestra sincronizada permanece diferente durante DEBOUNCE_MS.
// =============================================================================
module button_conditioner #(
    parameter int CLK_FREQ    = 100_000_000,
    parameter int DEBOUNCE_MS = 20
)(
    input  logic clk,
    input  logic rst,
    input  logic button_i,
    output logic level_o
);

    localparam int STABLE_CYCLES = (CLK_FREQ / 1000) * DEBOUNCE_MS;
    localparam int COUNT_WIDTH = (STABLE_CYCLES <= 1)
                               ? 1 : $clog2(STABLE_CYCLES);

    logic sync_1, sync_2;
    logic [COUNT_WIDTH-1:0] stable_count;

    always_ff @(posedge clk) begin
        if (rst) begin
            sync_1      <= 1'b0;
            sync_2      <= 1'b0;
            stable_count <= '0;
            level_o     <= 1'b0;
        end
        else begin
            sync_1 <= button_i;
            sync_2 <= sync_1;

            if (sync_2 == level_o) begin
                stable_count <= '0;
            end
            else if (stable_count == STABLE_CYCLES - 1) begin
                level_o      <= sync_2;
                stable_count <= '0;
            end
            else begin
                stable_count <= stable_count + 1'b1;
            end
        end
    end

endmodule


// =============================================================================
// CONTROLADOR DE PANTALLA PARA EL TOP COMPLETO
// =============================================================================
// Es equivalente al controlador original durante GAME y RESULT. En MENU agrega
// un simbolo '>' para identificar la opcion que BTN_OK confirmara.
// =============================================================================
module lcd_screen_controller_completo (
    input  logic        clk,
    input  logic        rst,
    input  logic        selected_mode,
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

    localparam logic [1:0] CONTROL = 2'b00;
    localparam logic [1:0] DATA    = 2'b01;

    logic [127:0] line1, line2;
    logic [127:0] snap1, snap2;
    logic [127:0] shown1, shown2;
    logic shown_valid;
    integer i;

    // Construccion del contenido deseado de ambas lineas.
    always_comb begin
        if (!selected_mode) begin
            line1 = "> FACIL         ";
            line2 = "  DIFICIL       ";
        end
        else begin
            line1 = "  FACIL         ";
            line2 = "> DIFICIL       ";
        end

        if (game_active) begin
            line1 = "P:              ";
            line2 = "T:00 Y INT:0    ";

            for (i = 0; i < 12; i = i + 1) begin
                if (i < word_length)
                    line1[127-(i+2)*8 -: 8] = revealed_mask[i]
                        ? selected_word[95-i*8 -: 8] : "_";
            end

            line2[127-2*8 -: 8] = "0" + (time_left / 10);
            line2[127-3*8 -: 8] = "0" + (time_left % 10);
            line2[127-11*8 -: 8] = (wrong_count >= 6)
                                      ? "0" : "0" + (6 - wrong_count);
        end

        if (result_active) begin
            if (result_win) begin
                line1 = "RESULTADO:      ";
                line2 = "GANO            ";
            end
            else begin
                line1 = "PERDIO:         ";
                line2 = "P:              ";

                for (i = 0; i < 12; i = i + 1)
                    if (i < word_length)
                        line2[127-(i+2)*8 -: 8] =
                            selected_word[95-i*8 -: 8];
            end
        end
    end

    typedef enum logic [1:0] {IDLE, LOAD, START, WAIT_LCD} state_t;
    state_t state;

    logic [5:0] step;
    logic [7:0] lcd_byte;
    logic lcd_rs_value;

    // Selecciona el comando o caracter correspondiente al paso actual.
    always_comb begin
        lcd_byte     = 8'h20;
        lcd_rs_value = 1'b1;

        if (step == 0) begin
            lcd_byte     = 8'h80;       // Inicio de primera linea
            lcd_rs_value = 1'b0;
        end
        else if (step <= 16) begin
            lcd_byte = snap1[127-(step-1)*8 -: 8];
        end
        else if (step == 17) begin
            lcd_byte     = 8'hC0;       // Inicio de segunda linea
            lcd_rs_value = 1'b0;
        end
        else begin
            lcd_byte = snap2[127-(step-18)*8 -: 8];
        end
    end

    // Maestro del bus de registros del periferico LCD.
    always_comb begin
        write_enable_o = 1'b0;
        addr_o         = CONTROL;
        wdata_o        = 32'b0;

        if (state == LOAD) begin
            write_enable_o = 1'b1;
            addr_o         = DATA;
            wdata_o[7:0]   = lcd_byte;
        end
        else if (state == START) begin
            write_enable_o = 1'b1;
            addr_o         = CONTROL;
            wdata_o[0]     = 1'b1;      // start W1P
            wdata_o[1]     = lcd_rs_value;
        end
    end

    // Captura una instantanea y escribe 2 comandos + 32 caracteres. Solo
    // repite el proceso cuando alguna de las dos lineas ha cambiado.
    always_ff @(posedge clk) begin
        if (rst) begin
            state       <= IDLE;
            step        <= 0;
            snap1       <= 0;
            snap2       <= 0;
            shown1      <= 0;
            shown2      <= 0;
            shown_valid <= 1'b0;
        end
        else begin
            case (state)
                IDLE: begin
                    if (!rdata_i[8] &&
                        (!shown_valid || line1 != shown1 || line2 != shown2)) begin
                        snap1 <= line1;
                        snap2 <= line2;
                        step  <= 0;
                        state <= LOAD;
                    end
                end

                LOAD:  state <= START;
                START: state <= WAIT_LCD;

                WAIT_LCD: begin
                    if (!rdata_i[8]) begin
                        if (step == 33) begin
                            shown1      <= snap1;
                            shown2      <= snap2;
                            shown_valid <= 1'b1;
                            state       <= IDLE;
                        end
                        else begin
                            step  <= step + 1'b1;
                            state <= LOAD;
                        end
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
