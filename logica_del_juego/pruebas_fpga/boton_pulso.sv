// ============================================================================
// boton_pulso.sv
//
// Sincronizador + antirrebote (contador simple) + detector de flanco.
// NOTA: este modulo es un SUSTITUTO MINIMO, solo para poder probar estos
// tres bloques en la FPGA de forma aislada. El diseno definitivo de
// "Gestion de entradas locales" (Banco de sincronizadores + Banco de
// filtros antirrebote + Banco de detectores de flanco) le corresponde a
// otro sub-equipo y debe reemplazar a este modulo en la integracion final.
// ============================================================================
module boton_pulso #(
    parameter int CICLOS_ESTABLE = 200_000  // ~2 ms a 100 MHz
)(
    input  logic clk,
    input  logic rst_n,
    input  logic boton_raw,
    output logic pulso          // 1 ciclo, en el flanco de subida ya estable
);
    logic sync0, sync1, estable;
    logic [17:0] contador;
    logic estable_prev;

    // sincronizador de 2 flip-flops
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin sync0 <= 1'b0; sync1 <= 1'b0; end
        else begin sync0 <= boton_raw; sync1 <= sync0; end
    end

    // antirrebote: solo actualiza "estable" si la senal se mantiene
    // constante por CICLOS_ESTABLE ciclos seguidos
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            contador <= '0;
            estable  <= 1'b0;
        end else if (sync1 == estable) begin
            contador <= '0;
        end else if (contador == CICLOS_ESTABLE[17:0]) begin
            estable  <= sync1;
            contador <= '0;
        end else begin
            contador <= contador + 1'b1;
        end
    end

    // detector de flanco de subida
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) estable_prev <= 1'b0;
        else        estable_prev <= estable;
    end

    assign pulso = estable && !estable_prev;
endmodule
