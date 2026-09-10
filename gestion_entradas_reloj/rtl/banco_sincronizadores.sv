// ============================================================================
// banco_sincronizadores.sv
// Sincroniza los tres botones externos mediante dos flip-flops en cascada.
//
// Convencion del bus:
//   bit 0: BTN_SEL
//   bit 1: BTN_OK
//   bit 2: BTN_RST
// ============================================================================
module banco_sincronizadores #(
    parameter int unsigned NUM_BOTONES = 3
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic [NUM_BOTONES-1:0] btn_async,
    output logic [NUM_BOTONES-1:0] btn_sync
);

    // ASYNC_REG indica a Vivado que ambos registros forman una cadena de
    // sincronizacion y ayuda a colocarlos fisicamente cerca entre si.
    (* ASYNC_REG = "TRUE" *) logic [NUM_BOTONES-1:0] sync_etapa_1;
    (* ASYNC_REG = "TRUE" *) logic [NUM_BOTONES-1:0] sync_etapa_2;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_etapa_1 <= '0;
            sync_etapa_2 <= '0;
        end else begin
            sync_etapa_1 <= btn_async;
            sync_etapa_2 <= sync_etapa_1;
        end
    end

    assign btn_sync = sync_etapa_2;

endmodule
