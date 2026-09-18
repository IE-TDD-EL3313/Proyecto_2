// Controla el inicio y la finalizacion de cada transferencia UART.
module control_uart (
    input  logic clk_i,
    input  logic rst_i,
    input  logic send_i,
    input  logic tx_done_i,
    input  logic rx_valid_i,
    output logic tx_start_o,
    output logic tx_complete_o,
    output logic rx_event_o,
    output logic busy_o
);
    typedef enum logic {ESPERANDO, TRANSMITIENDO} estado_t;
    estado_t estado, estado_siguiente;

    always_ff @(posedge clk_i) begin
        if (rst_i)
            estado <= ESPERANDO;
        else
            estado <= estado_siguiente;
    end

    always_comb begin
        estado_siguiente = estado;
        tx_start_o       = 1'b0;
        tx_complete_o    = 1'b0;
        busy_o           = (estado == TRANSMITIENDO);

        case (estado)
            ESPERANDO: begin
                if (send_i) begin
                    tx_start_o       = 1'b1;
                    estado_siguiente = TRANSMITIENDO;
                end
            end

            TRANSMITIENDO: begin
                if (tx_done_i) begin
                    tx_complete_o    = 1'b1;
                    estado_siguiente = ESPERANDO;
                end
            end

            default: estado_siguiente = ESPERANDO;
        endcase
    end

    // El nucleo RX ya entrega un pulso de un ciclo por cada byte completo.
    assign rx_event_o = rx_valid_i;
endmodule
