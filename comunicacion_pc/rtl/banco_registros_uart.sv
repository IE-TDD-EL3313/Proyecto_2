// Banco de registros de 32 bits del periferico UART.
// 00: DATA_TX, 01: DATA_RX, 10: CONTROL, 11: reservado.
module banco_registros_uart (
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic        write_enable_i,
    input  logic [1:0]  addr_i,
    input  logic [31:0] wdata_i,
    output logic [31:0] rdata_o,

    input  logic [7:0]  rx_data_i,
    input  logic        rx_valid_i,
    input  logic        tx_done_i,
    output logic [7:0]  tx_data_o,
    output logic        send_o,
    output logic        new_rx_o
);
    localparam logic [1:0]
        ADDR_DATA_TX = 2'b00,
        ADDR_DATA_RX = 2'b01,
        ADDR_CONTROL = 2'b10;

    logic [7:0] rx_data_reg;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            tx_data_o   <= 8'h00;
            rx_data_reg <= 8'h00;
            send_o      <= 1'b0;
            new_rx_o    <= 1'b0;
        end else begin
            // El nucleo limpia send al terminar la transferencia.
            if (tx_done_i)
                send_o <= 1'b0;

            if (write_enable_i) begin
                case (addr_i)
                    ADDR_DATA_TX: tx_data_o   <= wdata_i[7:0];
                    ADDR_DATA_RX: rx_data_reg <= wdata_i[7:0];
                    ADDR_CONTROL: begin
                        // Escribir 1 solicita el envio; permanece hasta tx_done.
                        if (wdata_i[0])
                            send_o <= 1'b1;
                        // new_rx es RW: el controlador lo limpia escribiendo 0.
                        new_rx_o <= wdata_i[1];
                    end
                    default: ;
                endcase
            end

            // Una recepcion nueva tiene prioridad sobre una limpieza simultanea.
            if (rx_valid_i) begin
                rx_data_reg <= rx_data_i;
                new_rx_o    <= 1'b1;
            end
        end
    end

    always_comb begin
        case (addr_i)
            ADDR_DATA_TX: rdata_o = {24'h0, tx_data_o};
            ADDR_DATA_RX: rdata_o = {24'h0, rx_data_reg};
            ADDR_CONTROL: rdata_o = {30'h0, new_rx_o, send_o};
            default:      rdata_o = 32'h00000000;
        endcase
    end
endmodule
