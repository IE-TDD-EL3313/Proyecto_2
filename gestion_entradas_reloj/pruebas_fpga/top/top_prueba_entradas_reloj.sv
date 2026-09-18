// ============================================================================
// top_prueba_entradas_reloj.sv
// Arnés para comprobar físicamente el bloque en una Nexys 4 Rev. B.
// ============================================================================
module top_prueba_entradas_reloj #(
    parameter int unsigned CLK_HZ            = 100_000_000,
    parameter int unsigned DEBOUNCE_HZ       = 1_000,
    parameter int unsigned DISPLAY_HZ        = 4_000,
    parameter int unsigned MUESTRAS_ESTABLES = 20
)(
    input  logic       clk,
    input  logic       cpu_reset_n,
    input  logic       btn_sel_i,
    input  logic       btn_ok_i,
    input  logic       btn_rst_i,
    output logic [3:0] led
);

    logic sel_pulse;
    logic ok_pulse;
    logic rst_pulse;
    logic ce_debounce;
    logic ce_1s;
    logic ce_display;

    entradas_reloj #(
        .CLK_HZ            (CLK_HZ),
        .DEBOUNCE_HZ       (DEBOUNCE_HZ),
        .DISPLAY_HZ        (DISPLAY_HZ),
        .MUESTRAS_ESTABLES (MUESTRAS_ESTABLES)
    ) u_entradas_reloj (
        .clk         (clk),
        .rst_n       (cpu_reset_n),
        .btn_sel_i   (btn_sel_i),
        .btn_ok_i    (btn_ok_i),
        .btn_rst_i   (btn_rst_i),
        .sel_pulse   (sel_pulse),
        .ok_pulse    (ok_pulse),
        .rst_pulse   (rst_pulse),
        .ce_debounce (ce_debounce),
        .ce_1s       (ce_1s),
        .ce_display  (ce_display)
    );

    // Cada evento cambia el estado de su LED y permanece visible.
    always_ff @(posedge clk or negedge cpu_reset_n) begin
        if (!cpu_reset_n) begin
            led <= 4'b0000;
        end else begin
            if (sel_pulse) led[0] <= ~led[0];
            if (ok_pulse)  led[1] <= ~led[1];
            if (rst_pulse) led[2] <= ~led[2];
            if (ce_1s)     led[3] <= ~led[3];
        end
    end

endmodule
