module io_controller #(
    parameter int CLK_FREQ = 100_000_000
)(
    input  logic       clk,
    input  logic       rst,

    input  logic [6:0] time_left,
    input  logic [6:0] victories,

    input  logic       letter_correct,
    input  logic       letter_wrong,
    input  logic       result_active,
    input  logic       result_win,

    output logic [6:0] seg,
    output logic [3:0] an,
    output logic       dp,
    output logic       buzzer_out
);

    // Un tick cada 1 ms
    localparam int MS_DIV = CLK_FREQ / 1000;

    logic [$clog2(MS_DIV)-1:0] ms_count;
    logic [1:0] digit;
    logic ms_tick;

    always_ff @(posedge clk) begin
        if (rst) begin
            ms_count <= 0;
            digit    <= 0;
            ms_tick  <= 0;
        end
        else begin
            ms_tick <= 0;

            if (ms_count == MS_DIV-1) begin
                ms_count <= 0;
                digit    <= digit + 1'b1;
                ms_tick  <= 1;
            end
            else
                ms_count <= ms_count + 1'b1;
        end
    end


    // =========================================================
    // 7 SEGMENTOS
    //
    // [tiempo][victorias]
    // Ejemplo: 45 s y 2 victorias -> 4502
    // =========================================================

    logic [3:0] number;

    always_comb begin
        an = 4'b1111;

        case (digit)
            0: begin an = 4'b1110; number = victories % 10; end
            1: begin an = 4'b1101; number = (victories / 10) % 10; end
            2: begin an = 4'b1011; number = time_left % 10; end
            default: begin an = 4'b0111; number = (time_left / 10) % 10; end
        endcase

        case (number)
            0: seg = 7'b1000000;
            1: seg = 7'b1111001;
            2: seg = 7'b0100100;
            3: seg = 7'b0110000;
            4: seg = 7'b0011001;
            5: seg = 7'b0010010;
            6: seg = 7'b0000010;
            7: seg = 7'b1111000;
            8: seg = 7'b0000000;
            9: seg = 7'b0010000;
            default: seg = 7'b1111111;
        endcase
    end

    assign dp = 1'b1;


    // =========================================================
    // BUZZER ACTIVO
    //
    // Correcta   -> 1 beep
    // Incorrecta -> 2 beeps
    // Victoria   -> 3 beeps
    // Derrota    -> 1 beep largo
    // =========================================================

    logic result_d;
    wire result_start = result_active & ~result_d;

    logic       buzz_on;
    logic [2:0] beeps_left;
    logic [9:0] buzz_ms;
    logic [9:0] on_ms, off_ms;

    assign buzzer_out = buzz_on;


    always_ff @(posedge clk) begin

        if (rst) begin
            result_d   <= 0;
            buzz_on    <= 0;
            beeps_left <= 0;
            buzz_ms    <= 0;
            on_ms      <= 0;
            off_ms     <= 0;
        end

        else begin
            result_d <= result_active;


            // Resultado final tiene prioridad
            if (result_start) begin

                buzz_on <= 1;

                if (result_win) begin
                    beeps_left <= 3;
                    on_ms      <= 100;
                    off_ms     <= 70;
                    buzz_ms    <= 100;
                end
                else begin
                    beeps_left <= 1;
                    on_ms      <= 600;
                    off_ms     <= 0;
                    buzz_ms    <= 600;
                end

            end

            else if (letter_correct) begin
                buzz_on    <= 1;
                beeps_left <= 1;
                on_ms      <= 120;
                off_ms     <= 0;
                buzz_ms    <= 120;
            end

            else if (letter_wrong) begin
                buzz_on    <= 1;
                beeps_left <= 2;
                on_ms      <= 90;
                off_ms     <= 90;
                buzz_ms    <= 90;
            end


            // Control de duración usando el tick de 1 ms
            else if (ms_tick && beeps_left != 0) begin

                if (buzz_ms > 1)
                    buzz_ms <= buzz_ms - 1'b1;

                else if (buzz_on) begin

                    // Terminó un beep
                    if (beeps_left == 1) begin
                        buzz_on    <= 0;
                        beeps_left <= 0;
                    end

                    else begin
                        buzz_on    <= 0;
                        beeps_left <= beeps_left - 1'b1;
                        buzz_ms    <= off_ms;
                    end

                end

                else begin

                    // Terminó la pausa: siguiente beep
                    buzz_on <= 1;
                    buzz_ms <= on_ms;

                end
            end
        end
    end

endmodule