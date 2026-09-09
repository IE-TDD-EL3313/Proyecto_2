// ============================================================================
// seg7_mux_driver.sv
//
// Driver multiplexado de 4 digitos (an[3:0]) para el display de 7 segmentos
// del Nexys4 (comun anodo: segmentos y anodos activos en BAJO).
// NOTA: sustituto minimo solo para el harness de pruebas; el diseno
// definitivo de "Gestion de Visualizacion" le corresponde a otro sub-equipo.
//
// digitos[0] = unidades de tiempo restante   (an[0], el mas a la derecha)
// digitos[1] = decenas de tiempo restante    (an[1])
// digitos[2] = unidades de partidas ganadas  (an[2])
// digitos[3] = decenas de partidas ganadas   (an[3])
// ============================================================================
module seg7_mux_driver (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [3:0] digitos [0:3], // valor BCD (0-9) de cada digito
    output logic [6:0] seg,           // activo en bajo: {g,f,e,d,c,b,a}
    output logic [7:0] an             // activo en bajo
);
    // refresco ~1 kHz por digito (100MHz / 2^17 ~ 763 Hz)
    logic [16:0] refresh_cnt;
    logic [1:0]  sel;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) refresh_cnt <= '0;
        else        refresh_cnt <= refresh_cnt + 1'b1;
    end
    assign sel = refresh_cnt[16:15];

    logic [3:0] digito_actual;
    always_comb digito_actual = digitos[sel];

    always_comb begin
        case (digito_actual)
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            default: seg = 7'b1111111; // apagado
        endcase
    end

    always_comb begin
        an = 8'hFF;      // todos apagados por defecto (activo en bajo)
        an[sel] = 1'b0;  // enciende solo el digito seleccionado
    end
endmodule
