// Guarda y ordena los eventos del juego antes de formar sus tramas UART.
module coordinador_eventos_uart (
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic        inicio_i,
    input  logic        letra_i,
    input  logic        final_i,
    input  logic        modo_i,
    input  logic [3:0]  longitud_i,
    input  logic [1:0]  resultado_letra_i,
    input  logic [1:0]  causa_final_i,
    input  logic [2:0]  intentos_i,
    input  logic [95:0] patron_ascii_i,
    input  logic        generador_busy_i,
    output logic        evento_o,
    output logic [1:0]  tipo_o,
    output logic        modo_o,
    output logic [3:0]  longitud_o,
    output logic [1:0]  resultado_o,
    output logic [2:0]  intentos_o,
    output logic [95:0] patron_ascii_o,
    output logic        pendientes_o
);
    logic pendiente_inicio, pendiente_letra, pendiente_final;
    logic modo_inicio, modo_letra, modo_final;
    logic [3:0] longitud_inicio, longitud_letra, longitud_final;
    logic [1:0] resultado_letra_reg, causa_final_reg;
    logic [2:0] intentos_inicio, intentos_letra, intentos_final;
    logic [95:0] patron_inicio, patron_letra, patron_final;

    assign pendientes_o = pendiente_inicio | pendiente_letra | pendiente_final;

    always_comb begin
        evento_o       = 1'b0;
        tipo_o         = 2'b00;
        modo_o         = 1'b0;
        longitud_o     = 4'd0;
        resultado_o    = 2'b00;
        intentos_o     = 3'd0;
        patron_ascii_o = '0;

        if (!generador_busy_i) begin
            if (pendiente_inicio) begin
                evento_o       = 1'b1;
                tipo_o         = 2'b00;
                modo_o         = modo_inicio;
                longitud_o     = longitud_inicio;
                intentos_o     = intentos_inicio;
                patron_ascii_o = patron_inicio;
            end else if (pendiente_letra) begin
                evento_o       = 1'b1;
                tipo_o         = 2'b01;
                modo_o         = modo_letra;
                longitud_o     = longitud_letra;
                resultado_o    = resultado_letra_reg;
                intentos_o     = intentos_letra;
                patron_ascii_o = patron_letra;
            end else if (pendiente_final) begin
                evento_o       = 1'b1;
                tipo_o         = 2'b10;
                modo_o         = modo_final;
                longitud_o     = longitud_final;
                resultado_o    = causa_final_reg;
                intentos_o     = intentos_final;
                patron_ascii_o = patron_final;
            end
        end
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            pendiente_inicio   <= 1'b0;
            pendiente_letra    <= 1'b0;
            pendiente_final    <= 1'b0;
            modo_inicio        <= 1'b0;
            modo_letra         <= 1'b0;
            modo_final         <= 1'b0;
            longitud_inicio    <= 4'd0;
            longitud_letra     <= 4'd0;
            longitud_final     <= 4'd0;
            resultado_letra_reg <= 2'b00;
            causa_final_reg    <= 2'b00;
            intentos_inicio    <= 3'd0;
            intentos_letra     <= 3'd0;
            intentos_final     <= 3'd0;
            patron_inicio      <= '0;
            patron_letra       <= '0;
            patron_final       <= '0;
        end else begin
            // El generador captura el evento en este mismo flanco.
            if (evento_o) begin
                case (tipo_o)
                    2'b00: pendiente_inicio <= 1'b0;
                    2'b01: pendiente_letra  <= 1'b0;
                    default: pendiente_final <= 1'b0;
                endcase
            end

            // Las capturas tienen prioridad para no perder un evento nuevo.
            if (inicio_i) begin
                pendiente_inicio <= 1'b1;
                modo_inicio      <= modo_i;
                longitud_inicio  <= longitud_i;
                intentos_inicio  <= intentos_i;
                patron_inicio    <= patron_ascii_i;
            end
            if (letra_i) begin
                pendiente_letra    <= 1'b1;
                modo_letra         <= modo_i;
                longitud_letra     <= longitud_i;
                resultado_letra_reg <= resultado_letra_i;
                intentos_letra     <= intentos_i;
                patron_letra       <= patron_ascii_i;
            end
            if (final_i) begin
                pendiente_final <= 1'b1;
                modo_final      <= modo_i;
                longitud_final  <= longitud_i;
                causa_final_reg <= causa_final_i;
                intentos_final  <= intentos_i;
                patron_final    <= patron_ascii_i;
            end
        end
    end
endmodule
