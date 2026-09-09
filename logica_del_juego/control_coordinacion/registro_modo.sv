// ============================================================================
// registro_modo.sv
// ============================================================================
module registro_modo (
    input  logic clk,
    input  logic rst_n,
    input  logic sel_pulse,
    input  logic rst_pulse,
    output logic dificultad
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)          dificultad <= 1'b0;
        else if (rst_pulse)  dificultad <= 1'b0; // Facil por defecto
        else if (sel_pulse)  dificultad <= ~dificultad;
    end
endmodule
