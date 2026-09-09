// ============================================================================
// lfsr8.sv
// LFSR de Fibonacci de 8 bits, free-running (avanza cada ciclo de clk).
// Polinomio: x^8 + x^6 + x^5 + x^4 + 1  ->  periodo maximo 255 (nunca pasa
// por 0x00 si la semilla es distinta de cero).
// ============================================================================
module lfsr8 (
    input  logic       clk,
    input  logic       rst_n,
    output logic [7:0] q
);
    localparam logic [7:0] SEED = 8'hB3; // cualquier valor != 0

    logic feedback;
    assign feedback = q[7] ^ q[5] ^ q[4] ^ q[3];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= SEED;
        else
            q <= {q[6:0], feedback};
    end
endmodule
