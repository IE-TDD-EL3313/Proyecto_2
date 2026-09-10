// ============================================================================
// entradas_reloj.sv
// Bloque superior de Gestion de Entradas Locales y Reloj Integrado.
// ============================================================================
module entradas_reloj #(
    parameter int unsigned CLK_HZ             = 100_000_000,
    parameter int unsigned DEBOUNCE_HZ        = 1_000,
    parameter int unsigned DISPLAY_HZ         = 4_000,
    parameter int unsigned MUESTRAS_ESTABLES  = 20
)(
    input  logic clk,
    input  logic rst_n,

    input  logic btn_sel_i,
    input  logic btn_ok_i,
    input  logic btn_rst_i,

    output logic sel_pulse,
    output logic ok_pulse,
    output logic rst_pulse,

    output logic ce_debounce,
    output logic ce_1s,
    output logic ce_display
);

    reloj_integrado #(
        .CLK_HZ      (CLK_HZ),
        .DEBOUNCE_HZ (DEBOUNCE_HZ),
        .DISPLAY_HZ  (DISPLAY_HZ)
    ) u_reloj (
        .clk         (clk),
        .rst_n       (rst_n),
        .ce_debounce (ce_debounce),
        .ce_1s       (ce_1s),
        .ce_display  (ce_display)
    );

    gestion_entradas_locales #(
        .MUESTRAS_ESTABLES(MUESTRAS_ESTABLES)
    ) u_entradas (
        .clk         (clk),
        .rst_n       (rst_n),
        .ce_debounce (ce_debounce),
        .btn_sel_i   (btn_sel_i),
        .btn_ok_i    (btn_ok_i),
        .btn_rst_i   (btn_rst_i),
        .sel_pulse   (sel_pulse),
        .ok_pulse    (ok_pulse),
        .rst_pulse   (rst_pulse)
    );

endmodule
