// ============================================================================
// detector_flanco_subida.sv
// Genera un pulso de un ciclo cuando la entrada cambia de 0 a 1.
// ============================================================================
module detector_flanco_subida (
    input  logic clk,
    input  logic rst_n,
    input  logic nivel,
    output logic pulso
);

    logic nivel_anterior;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nivel_anterior <= 1'b0;
            pulso          <= 1'b0;
        end else begin
            pulso          <= nivel && !nivel_anterior;
            nivel_anterior <= nivel;
        end
    end

endmodule
