// ============================================================================
// gestion_entradas_locales.sv
// Integra sincronizacion, antirrebote y deteccion de nuevas pulsaciones.
// ============================================================================
module gestion_entradas_locales #(
    parameter int unsigned MUESTRAS_ESTABLES = 20
)(
    input  logic clk,
    input  logic rst_n,
    input  logic ce_debounce,

    input  logic btn_sel_i,
    input  logic btn_ok_i,
    input  logic btn_rst_i,

    output logic sel_pulse,
    output logic ok_pulse,
    output logic rst_pulse
);

    logic [2:0] btn_async;
    logic [2:0] btn_sync;
    logic [2:0] btn_stable;
    logic [2:0] btn_pulse;

    assign btn_async = {btn_rst_i, btn_ok_i, btn_sel_i};

    banco_sincronizadores #(
        .NUM_BOTONES(3)
    ) u_sincronizadores (
        .clk       (clk),
        .rst_n     (rst_n),
        .btn_async (btn_async),
        .btn_sync  (btn_sync)
    );

    banco_filtros_antirrebote #(
        .NUM_BOTONES      (3),
        .MUESTRAS_ESTABLES(MUESTRAS_ESTABLES)
    ) u_filtros (
        .clk         (clk),
        .rst_n       (rst_n),
        .ce_debounce (ce_debounce),
        .btn_sync    (btn_sync),
        .btn_stable  (btn_stable)
    );

    banco_detectores_flanco #(
        .NUM_BOTONES(3)
    ) u_detectores (
        .clk        (clk),
        .rst_n      (rst_n),
        .btn_stable (btn_stable),
        .btn_pulse  (btn_pulse)
    );

    assign sel_pulse = btn_pulse[0];
    assign ok_pulse  = btn_pulse[1];
    assign rst_pulse = btn_pulse[2];

endmodule
