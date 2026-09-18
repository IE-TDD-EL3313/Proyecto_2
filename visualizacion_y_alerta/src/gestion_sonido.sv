module gestion_sonido #(
    parameter int unsigned CLK_HZ            = 100_000_000,
    parameter int unsigned FREQ_ACIERTO_HZ   = 1_000,
    parameter int unsigned FREQ_ERROR_HZ     = 400,
    parameter int unsigned FREQ_FINAL_HZ     = 800,
    parameter int unsigned DUR_ACIERTO_MS    = 120,
    parameter int unsigned DUR_ERROR_MS      = 250,
    parameter int unsigned DUR_FINAL_MS      = 600
) (
    input  logic       clk_i,
    input  logic       rst_i,
    input  logic [1:0] tono_sel_i,
    input  logic       tono_start_i,
    output logic       buzzer_o
);
    import alertas_pkg::*;

    localparam int unsigned DUR_ACIERTO_CYCLES = (DUR_ACIERTO_MS * CLK_HZ) / 1_000;
    localparam int unsigned DUR_ERROR_CYCLES   = (DUR_ERROR_MS   * CLK_HZ) / 1_000;
    localparam int unsigned DUR_FINAL_CYCLES   = (DUR_FINAL_MS   * CLK_HZ) / 1_000;
    localparam int unsigned HALF_ACIERTO       = CLK_HZ / (2 * FREQ_ACIERTO_HZ);
    localparam int unsigned HALF_ERROR         = CLK_HZ / (2 * FREQ_ERROR_HZ);
    localparam int unsigned HALF_FINAL         = CLK_HZ / (2 * FREQ_FINAL_HZ);
    localparam int unsigned MAX_DURATION_A = (DUR_ACIERTO_CYCLES > DUR_ERROR_CYCLES) ? DUR_ACIERTO_CYCLES : DUR_ERROR_CYCLES;
    localparam int unsigned MAX_DURATION = (MAX_DURATION_A > DUR_FINAL_CYCLES) ? MAX_DURATION_A : DUR_FINAL_CYCLES;
    localparam int unsigned MAX_HALF_A = (HALF_ACIERTO > HALF_ERROR) ? HALF_ACIERTO : HALF_ERROR;
    localparam int unsigned MAX_HALF = (MAX_HALF_A > HALF_FINAL) ? MAX_HALF_A : HALF_FINAL;
    localparam int unsigned DUR_W        = (MAX_DURATION < 2) ? 1 : $clog2(MAX_DURATION);
    localparam int unsigned HALF_W       = (MAX_HALF < 2) ? 1 : $clog2(MAX_HALF);

    logic [DUR_W-1:0]  duration_count_q, duration_limit_q;
    logic [HALF_W-1:0] half_count_q, half_limit_q;
    logic active_q;

    function automatic int unsigned duration_cycles(input logic [1:0] tono);
        case (tono)
            TONO_ACIERTO: duration_cycles = (DUR_ACIERTO_MS * CLK_HZ) / 1_000;
            TONO_ERROR:   duration_cycles = (DUR_ERROR_MS   * CLK_HZ) / 1_000;
            TONO_FINAL:   duration_cycles = (DUR_FINAL_MS   * CLK_HZ) / 1_000;
            default:      duration_cycles = 1;
        endcase
    endfunction

    function automatic int unsigned half_period_cycles(input logic [1:0] tono);
        case (tono)
            TONO_ACIERTO: half_period_cycles = CLK_HZ / (2 * FREQ_ACIERTO_HZ);
            TONO_ERROR:   half_period_cycles = CLK_HZ / (2 * FREQ_ERROR_HZ);
            TONO_FINAL:   half_period_cycles = CLK_HZ / (2 * FREQ_FINAL_HZ);
            default:      half_period_cycles = 1;
        endcase
    endfunction

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            duration_count_q <= '0;
            duration_limit_q <= '0;
            half_count_q     <= '0;
            half_limit_q     <= '0;
            active_q         <= 1'b0;
            buzzer_o         <= 1'b0;
        end else if (!active_q) begin
            buzzer_o <= 1'b0;
            if (tono_start_i && (tono_sel_i != TONO_SILENCIO)) begin
                active_q         <= 1'b1;
                duration_count_q <= '0;
                half_count_q     <= '0;
                duration_limit_q <= duration_cycles(tono_sel_i) - 1;
                half_limit_q     <= half_period_cycles(tono_sel_i) - 1;
            end
        end else begin
            if (duration_count_q == duration_limit_q) begin
                active_q         <= 1'b0;
                duration_count_q <= '0;
                buzzer_o         <= 1'b0;
            end else begin
                duration_count_q <= duration_count_q + 1'b1;
                if (half_count_q == half_limit_q) begin
                    half_count_q <= '0;
                    buzzer_o     <= ~buzzer_o;
                end else
                    half_count_q <= half_count_q + 1'b1;
            end
        end
    end
endmodule
