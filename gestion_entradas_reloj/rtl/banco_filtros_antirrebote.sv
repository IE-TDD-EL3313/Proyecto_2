// ============================================================================
// banco_filtros_antirrebote.sv
// Banco de filtros para BTN_SEL, BTN_OK y BTN_RST.
// Convencion: bit 0 = SEL, bit 1 = OK, bit 2 = RST.
// ============================================================================
module banco_filtros_antirrebote #(
    parameter int unsigned NUM_BOTONES       = 3,
    parameter int unsigned MUESTRAS_ESTABLES = 20
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic                   ce_debounce,
    input  logic [NUM_BOTONES-1:0] btn_sync,
    output logic [NUM_BOTONES-1:0] btn_stable
);

    genvar i;
    generate
        for (i = 0; i < NUM_BOTONES; i++) begin : gen_filtros
            filtro_antirrebote #(
                .MUESTRAS_ESTABLES(MUESTRAS_ESTABLES)
            ) u_filtro (
                .clk         (clk),
                .rst_n       (rst_n),
                .ce_muestreo (ce_debounce),
                .btn_sync    (btn_sync[i]),
                .btn_stable  (btn_stable[i])
            );
        end
    endgenerate

endmodule
