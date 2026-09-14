module driver_7seg #(
    parameter int unsigned CLK_HZ  = 100_000_000,
    parameter int unsigned SCAN_HZ = 1_000
) (
    input  logic       clk_i,
    input  logic       rst_i,
    input  logic [6:0] tiempo_i,
    input  logic [6:0] victorias_i,
    input  logic       ce_display_i,
    output logic [6:0] seg_o,
    output logic [3:0] an_o
);
    localparam int unsigned SCAN_CYCLES = (CLK_HZ / (SCAN_HZ * 4) > 0) ? CLK_HZ / (SCAN_HZ * 4) : 1;
    localparam int unsigned SCAN_W = (SCAN_CYCLES < 2) ? 1 : $clog2(SCAN_CYCLES);

    logic [6:0] tiempo_q, victorias_q;
    logic [SCAN_W-1:0] scan_count_q;
    logic [1:0] scan_index_q;
    logic [3:0] digit;
    logic [3:0] tiempo_decenas, tiempo_unidades, victorias_decenas, victorias_unidades;

    function automatic logic [3:0] to_bcd_tens(input logic [6:0] value);
        to_bcd_tens = (value > 7'd99) ? 4'd9 : value / 10;
    endfunction
    function automatic logic [3:0] to_bcd_ones(input logic [6:0] value);
        to_bcd_ones = (value > 7'd99) ? 4'd9 : value % 10;
    endfunction
    function automatic logic [6:0] seven_seg(input logic [3:0] value);
        // abcdefg, activo en bajo
        case (value)
            4'd0: seven_seg = 7'b1000000; 4'd1: seven_seg = 7'b1111001;
            4'd2: seven_seg = 7'b0100100; 4'd3: seven_seg = 7'b0110000;
            4'd4: seven_seg = 7'b0011001; 4'd5: seven_seg = 7'b0010010;
            4'd6: seven_seg = 7'b0000010; 4'd7: seven_seg = 7'b1111000;
            4'd8: seven_seg = 7'b0000000; 4'd9: seven_seg = 7'b0010000;
            default: seven_seg = 7'b1111111;
        endcase
    endfunction

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            tiempo_q <= '0; victorias_q <= '0; scan_count_q <= '0; scan_index_q <= '0;
        end else begin
            if (ce_display_i) begin
                tiempo_q <= tiempo_i;
                victorias_q <= victorias_i;
            end
            if (scan_count_q == SCAN_CYCLES - 1) begin
                scan_count_q <= '0;
                scan_index_q <= scan_index_q + 1'b1;
            end else scan_count_q <= scan_count_q + 1'b1;
        end
    end

    always_comb begin
        tiempo_decenas = to_bcd_tens(tiempo_q);
        tiempo_unidades = to_bcd_ones(tiempo_q);
        victorias_decenas = to_bcd_tens(victorias_q);
        victorias_unidades = to_bcd_ones(victorias_q);
        case (scan_index_q)
            2'd0: begin an_o = 4'b0111; digit = tiempo_decenas; end
            2'd1: begin an_o = 4'b1011; digit = tiempo_unidades; end
            2'd2: begin an_o = 4'b1101; digit = victorias_decenas; end
            default: begin an_o = 4'b1110; digit = victorias_unidades; end
        endcase
        seg_o = seven_seg(digit);
    end
endmodule
