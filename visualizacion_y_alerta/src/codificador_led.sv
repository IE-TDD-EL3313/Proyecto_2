module codificador_led #(
    parameter int unsigned CLK_HZ   = 100_000_000,
    parameter int unsigned BLINK_HZ = 2
) (
    input  logic       clk_i,
    input  logic       rst_i,
    input  logic [1:0] led_sel_i,
    output logic       led_o
);
    import alertas_pkg::*;
    localparam int unsigned HALF_BLINK_CYCLES = (CLK_HZ / (2 * BLINK_HZ) > 0) ? CLK_HZ / (2 * BLINK_HZ) : 1;
    localparam int unsigned COUNT_W = (HALF_BLINK_CYCLES < 2) ? 1 : $clog2(HALF_BLINK_CYCLES);
    logic [COUNT_W-1:0] count_q;
    logic blink_q;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            count_q <= '0;
            blink_q <= 1'b0;
        end else if (led_sel_i != LED_PARPADEO) begin
            count_q <= '0;
            blink_q <= 1'b0;
        end else if (count_q == HALF_BLINK_CYCLES - 1) begin
            count_q <= '0;
            blink_q <= ~blink_q;
        end else count_q <= count_q + 1'b1;
    end

    always_comb begin
        case (led_sel_i)
            LED_ENCENDIDO: led_o = 1'b1;
            LED_PARPADEO:  led_o = blink_q;
            default:       led_o = 1'b0;
        endcase
    end
endmodule
