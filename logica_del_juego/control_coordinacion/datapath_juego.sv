// ============================================================================
// datapath_juego.sv
//
// Registros de la partida + generacion de flags. IMPORTANTE: los 4 bits de
// "flags" se calculan unicamente a partir de REGISTROS e ENTRADAS externas
// (letra_ascii, mask_coincidencia, longitud_palabra) -- nunca a partir de
// "cmd". Esto evita un lazo combinacional cmd->flags->cmd, ya que "cmd" lo
// decide la Unidad de Control usando flags del ciclo actual.
//
// Ajuste respecto al documento de nivel 4: "intentos_agotados" se calcula en
// forma de "lookahead" (si este error fuera el sexto, ya se reporta en este
// mismo ciclo), de modo que la Unidad de Control pueda decidir en el mismo
// ciclo si la partida termina, sin esperar un ciclo adicional.
// ============================================================================
module datapath_juego (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [7:0]  letra_ascii,
    input  logic [11:0] mask_coincidencia,
    input  logic [3:0]  longitud_palabra,
    input  logic [2:0]  cmd,
    output logic [3:0]  flags,              // {agotados, completa, repetida, acierto}
    output logic [4:0]  letra_in,           // hacia Gestion de Palabras
    output logic [11:0] palabra_revelada,
    output logic [2:0]  intentos_restantes,
    output logic [7:0]  partidas_ganadas_bcd
);
    localparam logic [2:0]
        CMD_NADA    = 3'b000,
        CMD_CARGA   = 3'b001,
        CMD_INTENTO = 3'b010,
        CMD_GANADAS = 3'b011,
        CMD_LIMPIA  = 3'b100;

    logic [25:0] letras_usadas;
    logic [2:0]  intentos_fallidos;

    // letra_in: convierte ASCII a codigo 5 bits (A=1 .. Z=26); 0 si invalido
    logic letra_valida;
    assign letra_valida = (letra_ascii >= 8'd65) && (letra_ascii <= 8'd90); // 'A'..'Z'
    assign letra_in     = letra_valida ? (5'(letra_ascii - 8'd65) + 5'd1) : 5'd0;

    // --- Flags combinacionales (dependen solo de registros + entradas) ---
    logic hay_acierto, letra_repetida, palabra_completa, intentos_agotados;
    logic [11:0] palabra_completa_mask;

    assign hay_acierto    = |mask_coincidencia;
    assign letra_repetida = letra_valida && letras_usadas[letra_ascii - 8'd65];

    // mascara con 'longitud_palabra' unos desde el LSB
    assign palabra_completa_mask = (12'hFFF >> (4'd12 - longitud_palabra));
    assign palabra_completa      = ((palabra_revelada | mask_coincidencia) ==
                                      palabra_completa_mask);

    // "lookahead": ya esta en 6, o este error (no acierto, no repetida) seria el 6to
    assign intentos_agotados = (intentos_fallidos == 3'd6) ||
                               ((intentos_fallidos == 3'd5) &&
                                !hay_acierto && !letra_repetida);

    assign flags = {intentos_agotados, palabra_completa, letra_repetida, hay_acierto};
    assign intentos_restantes = 3'd6 - intentos_fallidos;

    // --- Registros, actualizados por cmd ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            letras_usadas     <= '0;
            palabra_revelada  <= '0;
            intentos_fallidos <= '0;
        end else begin
            case (cmd)
                CMD_CARGA: begin
                    if (letra_valida)
                        letras_usadas[letra_ascii - 8'd65] <= 1'b1;
                    palabra_revelada <= palabra_revelada | mask_coincidencia;
                end
                CMD_INTENTO:
                    if (intentos_fallidos != 3'd6)
                        intentos_fallidos <= intentos_fallidos + 3'd1;
                CMD_LIMPIA: begin
                    letras_usadas     <= '0;
                    palabra_revelada  <= '0;
                    intentos_fallidos <= '0;
                end
                default: ;
            endcase
        end
    end

    // --- Contador BCD de partidas ganadas (00-99, satura) ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            partidas_ganadas_bcd <= 8'h00;
        else if (cmd == CMD_GANADAS && partidas_ganadas_bcd != 8'h99) begin
            if (partidas_ganadas_bcd[3:0] == 4'd9)
                partidas_ganadas_bcd <= {partidas_ganadas_bcd[7:4] + 4'd1, 4'd0};
            else
                partidas_ganadas_bcd <= {partidas_ganadas_bcd[7:4], partidas_ganadas_bcd[3:0] + 4'd1};
        end
    end

endmodule
