// ============================================================================
// generador_ce.sv
// Genera un pulso de habilitacion de un ciclo cada DIVISOR ciclos de clk.
// No genera un reloj nuevo: todo el sistema permanece en el dominio de clk.
// ============================================================================
module generador_ce #(
    parameter int unsigned DIVISOR = 2
)(
    input  logic clk,
    input  logic rst_n,
    output logic ce
);

    localparam int unsigned ANCHO_CONTADOR =
        (DIVISOR <= 1) ? 1 : $clog2(DIVISOR);

    logic [ANCHO_CONTADOR-1:0] contador;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            contador <= '0;
            ce       <= 1'b0;
        end else if (DIVISOR == 1) begin
            contador <= '0;
            ce       <= 1'b1;
        end else if (contador == DIVISOR - 1) begin
            contador <= '0;
            ce       <= 1'b1;
        end else begin
            contador <= contador + 1'b1;
            ce       <= 1'b0;
        end
    end

`ifndef SYNTHESIS
    initial begin
        assert (DIVISOR >= 1)
            else $fatal(1, "DIVISOR debe ser mayor o igual que 1");
    end
`endif

endmodule
