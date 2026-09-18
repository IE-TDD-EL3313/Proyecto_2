// ============================================================================
// filtro_antirrebote.sv
// Actualiza btn_stable unicamente cuando btn_sync conserva el nuevo estado
// durante MUESTRAS_ESTABLES pulsos consecutivos de ce_muestreo.
// ============================================================================
module filtro_antirrebote #(
    parameter int unsigned MUESTRAS_ESTABLES = 20
)(
    input  logic clk,
    input  logic rst_n,
    input  logic ce_muestreo,
    input  logic btn_sync,
    output logic btn_stable
);

    localparam int unsigned ANCHO_CONTADOR =
        (MUESTRAS_ESTABLES <= 1) ? 1 : $clog2(MUESTRAS_ESTABLES);

    logic [ANCHO_CONTADOR-1:0] contador;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            contador   <= '0;
            btn_stable <= 1'b0;
        end else if (ce_muestreo) begin
            if (btn_sync == btn_stable) begin
                // La entrada regreso al estado aceptado: no hay una nueva
                // transicion estable en progreso.
                contador <= '0;
            end else if (MUESTRAS_ESTABLES == 1) begin
                contador   <= '0;
                btn_stable <= btn_sync;
            end else if (contador == MUESTRAS_ESTABLES - 1) begin
                contador   <= '0;
                btn_stable <= btn_sync;
            end else begin
                contador <= contador + 1'b1;
            end
        end
    end

`ifndef SYNTHESIS
    initial begin
        assert (MUESTRAS_ESTABLES >= 1)
            else $fatal(1, "MUESTRAS_ESTABLES debe ser al menos 1");
    end
`endif

endmodule
