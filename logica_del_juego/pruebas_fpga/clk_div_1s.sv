// ============================================================================
// clk_div_1s.sv
// Genera un pulso de 1 ciclo de clk cada 1 segundo, a partir de un reloj de
// 100 MHz. Utilidad de soporte para poder probar en la FPGA los bloques
// "Gestion del Tiempo" y "Control y Coordinacion" sin depender aun del
// bloque "Reloj Integrado" (asignado a otro sub-equipo).
// ============================================================================
module clk_div_1s (
    input  logic clk,      // 100 MHz
    input  logic rst_n,
    output logic tick_1s   // pulso de 1 ciclo, cada 1 s
);
    localparam int MAX_COUNT = 100_000_000 - 1;
    logic [26:0] cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt     <= '0;
            tick_1s <= 1'b0;
        end else if (cnt == MAX_COUNT[26:0]) begin
            cnt     <= '0;
            tick_1s <= 1'b1;
        end else begin
            cnt     <= cnt + 1'b1;
            tick_1s <= 1'b0;
        end
    end
endmodule
