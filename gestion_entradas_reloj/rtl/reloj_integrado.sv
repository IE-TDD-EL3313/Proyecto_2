// ============================================================================
// reloj_integrado.sv
// Distribucion temporal para la Nexys 4 a partir del reloj unico de 100 MHz.
// ============================================================================
module reloj_integrado #(
    parameter int unsigned CLK_HZ      = 100_000_000,
    parameter int unsigned DEBOUNCE_HZ = 1_000,
    parameter int unsigned DISPLAY_HZ  = 4_000
)(
    input  logic clk,
    input  logic rst_n,

    output logic ce_debounce,
    output logic ce_1s,
    output logic ce_display
);

    localparam int unsigned DIV_DEBOUNCE = CLK_HZ / DEBOUNCE_HZ;
    localparam int unsigned DIV_1S       = CLK_HZ;
    localparam int unsigned DIV_DISPLAY  = CLK_HZ / DISPLAY_HZ;

    generador_ce #(
        .DIVISOR(DIV_DEBOUNCE)
    ) u_ce_debounce (
        .clk   (clk),
        .rst_n (rst_n),
        .ce    (ce_debounce)
    );

    generador_ce #(
        .DIVISOR(DIV_1S)
    ) u_ce_1s (
        .clk   (clk),
        .rst_n (rst_n),
        .ce    (ce_1s)
    );

    generador_ce #(
        .DIVISOR(DIV_DISPLAY)
    ) u_ce_display (
        .clk   (clk),
        .rst_n (rst_n),
        .ce    (ce_display)
    );

`ifndef SYNTHESIS
    initial begin
        assert (CLK_HZ >= 1)
            else $fatal(1, "CLK_HZ debe ser mayor o igual que 1");
        assert (DEBOUNCE_HZ >= 1 && DEBOUNCE_HZ <= CLK_HZ)
            else $fatal(1, "DEBOUNCE_HZ fuera de rango");
        assert (DISPLAY_HZ >= 1 && DISPLAY_HZ <= CLK_HZ)
            else $fatal(1, "DISPLAY_HZ fuera de rango");
        assert ((CLK_HZ % DEBOUNCE_HZ) == 0)
            else $fatal(1, "DEBOUNCE_HZ debe dividir exactamente CLK_HZ");
        assert ((CLK_HZ % DISPLAY_HZ) == 0)
            else $fatal(1, "DISPLAY_HZ debe dividir exactamente CLK_HZ");
    end
`endif

endmodule
