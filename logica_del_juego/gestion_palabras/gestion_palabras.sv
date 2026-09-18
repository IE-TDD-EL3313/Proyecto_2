// ============================================================================
// gestion_palabras.sv
//
// Bloque "Gestion de Palabras" completo (nivel 2/3), integrando:
//   - LFSR de 8 bits (free-running)
//   - Ajuste de rango segun dificultad + ROM de 50 palabras
//   - Registro de palabra activa + comparador de letra
//
// Respeta la latencia de 1 ciclo de la ROM (Block RAM con salida registrada):
// pedir_palabra en el ciclo N -> palabra_rom disponible en el ciclo N+1 ->
// letras_palabra/longitud_palabra/palabra_lista se cargan en el ciclo N+1.
// ============================================================================
module gestion_palabras #(
    parameter bit          MODO_PRUEBA    = 1'b0,
    parameter logic [63:0] PALABRA_PRUEBA = 64'h4000000000093DA1 // AMOR
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        dificultad,        // 0=Facil, 1=Dificil
    input  logic        pedir_palabra,     // pulso, 1 ciclo
    input  logic [4:0]  letra_in,          // codigo A=1..Z=26
    input  logic        validar,           // pulso, 1 ciclo
    output logic [3:0]  longitud_palabra,
    output logic        palabra_lista,     // pulso, 1 ciclo
    output logic [11:0] mask_coincidencia,
    output logic [59:0] palabra_codificada // 12 letras, 5 bits por letra
);

    // ---------------- LFSR ----------------
    logic [7:0] lfsr_q;
    lfsr8 u_lfsr (.clk(clk), .rst_n(rst_n), .q(lfsr_q));

    // ---------------- Ajuste de rango ----------------
    // Nota: el operador de modulo genera un divisor combinacional pequeno
    // (8 bits); aceptable para este proyecto. Alternativa sintetizable mas
    // liviana: comparar-y-restar en lugar de '%'.
    logic [7:0] indice_valido;
    always_comb begin
        if (dificultad)
            indice_valido = 8'd30 + (lfsr_q % 8'd20); // Dificil: direcciones 30-49
        else
            indice_valido = lfsr_q % 8'd50;            // Facil: direcciones 0-49
    end

    // ---------------- ROM (latencia 1 ciclo) ----------------
    logic [7:0]  direccion_rom;
    logic [63:0] palabra_rom;
    word_bank_rom #(
        .MODO_PRUEBA   (MODO_PRUEBA),
        .PALABRA_PRUEBA(PALABRA_PRUEBA)
    ) u_rom (
        .direccion   (direccion_rom),
        .palabra_rom (palabra_rom)
    );

    logic pedir_d;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            direccion_rom <= '0;
            pedir_d       <= 1'b0;
        end else begin
            pedir_d <= pedir_palabra;
            if (pedir_palabra)
                direccion_rom <= indice_valido;
        end
    end

    // ---------------- Registro Palabra + Comparador ----------------
    logic [4:0] letras_palabra [0:11];

    always_comb begin
        for (int i = 0; i < 12; i++)
            palabra_codificada[(i*5) +: 5] = letras_palabra[i];
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            longitud_palabra <= 4'd0;
            palabra_lista    <= 1'b0;
            for (int i = 0; i < 12; i++) letras_palabra[i] <= 5'd0;
        end else begin
            palabra_lista <= 1'b0; // pulso: por defecto bajo
            if (pedir_d) begin
                longitud_palabra <= palabra_rom[63:60];
                for (int i = 0; i < 12; i++)
                    letras_palabra[i] <= palabra_rom[(i*5)+4 -: 5];
                palabra_lista <= 1'b1;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            mask_coincidencia <= 12'd0;
        else if (validar) begin
            for (int i = 0; i < 12; i++)
                mask_coincidencia[i] <= (letras_palabra[i] == letra_in) &&
                                        (i < longitud_palabra);
        end
    end

endmodule
