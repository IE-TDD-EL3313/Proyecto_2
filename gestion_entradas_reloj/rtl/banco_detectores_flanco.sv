// ============================================================================
// banco_detectores_flanco.sv
// Convierte las señales estables de los botones en pulsos de un ciclo.
// Convencion: bit 0 = SEL, bit 1 = OK, bit 2 = RST.
// ============================================================================
module banco_detectores_flanco #(
    parameter int unsigned NUM_BOTONES = 3
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic [NUM_BOTONES-1:0] btn_stable,
    output logic [NUM_BOTONES-1:0] btn_pulse
);

    genvar i;
    generate
        for (i = 0; i < NUM_BOTONES; i++) begin : gen_detectores
            detector_flanco_subida u_detector (
                .clk   (clk),
                .rst_n (rst_n),
                .nivel (btn_stable[i]),
                .pulso (btn_pulse[i])
            );
        end
    endgenerate

endmodule
