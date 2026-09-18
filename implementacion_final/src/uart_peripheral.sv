module uart_peripheral #(
    parameter int CLK_FREQ  = 100_000_000,
    parameter int BAUD_RATE = 115200
)(
    input  logic        clk_i,
    input  logic        rst_i,

    input  logic        write_enable_i,
    input  logic [1:0]  addr_i,
    input  logic [31:0] wdata_i,
    output logic [31:0] rdata_o,

    input  logic uart_rx_i,
    output logic uart_tx_o
);

    localparam int BIT_CLKS  = CLK_FREQ / BAUD_RATE;
    localparam int HALF_CLKS = BIT_CLKS / 2;

    localparam logic [1:0] DATA_TX = 2'b00;
    localparam logic [1:0] DATA_RX = 2'b01;
    localparam logic [1:0] CONTROL = 2'b10;

    logic [7:0] tx_data, rx_data;
    logic       tx_busy, new_rx;

    // Sincronizador de RX
    logic rx_ff1, rx_sync;

    // TX
    logic [9:0] tx_shift;
    integer tx_count;
    integer tx_bit;

    // RX
    typedef enum logic [1:0] {RX_IDLE, RX_START, RX_DATA, RX_STOP} rx_state_t;
    rx_state_t rx_state;

    logic [7:0] rx_shift;
    integer rx_count;
    integer rx_bit;


    // Lectura de registros
    always_comb begin
        rdata_o = 32'b0;

        case (addr_i)
            DATA_TX: rdata_o[7:0] = tx_data;
            DATA_RX: rdata_o[7:0] = rx_data;

            CONTROL: begin
                rdata_o[0] = tx_busy;
                rdata_o[1] = new_rx;
            end

            default: rdata_o = 32'b0;
        endcase
    end


    // UART TX
    assign uart_tx_o = tx_busy ? tx_shift[0] : 1'b1;


    always_ff @(posedge clk_i) begin

        if (rst_i) begin

            rx_ff1  <= 1'b1;
            rx_sync <= 1'b1;

            tx_data  <= 0;
            rx_data  <= 0;
            tx_busy  <= 0;
            new_rx   <= 0;

            tx_shift <= 10'h3FF;
            tx_count <= 0;
            tx_bit   <= 0;

            rx_state <= RX_IDLE;
            rx_shift <= 0;
            rx_count <= 0;
            rx_bit   <= 0;

        end

        else begin

            // Sincronizar entrada UART
            rx_ff1  <= uart_rx_i;
            rx_sync <= rx_ff1;


            // =====================================================
            // REGISTROS
            // =====================================================

            if (write_enable_i) begin

                // Guardar byte que se quiere transmitir
                if (addr_i == DATA_TX)
                    tx_data <= wdata_i[7:0];


                // CONTROL
                if (addr_i == CONTROL) begin

                    // bit 1 = 0 limpia new_rx
                    if (!wdata_i[1])
                        new_rx <= 1'b0;

                    // bit 0 = 1 inicia transmisión
                    if (wdata_i[0] && !tx_busy) begin
                        tx_shift <= {1'b1, tx_data, 1'b0};
                        tx_busy  <= 1'b1;
                        tx_count <= 0;
                        tx_bit   <= 0;
                    end

                end
            end


            // =====================================================
            // TRANSMISOR UART
            // =====================================================

            if (tx_busy) begin

                if (tx_count == BIT_CLKS - 1) begin

                    tx_count <= 0;
                    tx_shift <= {1'b1, tx_shift[9:1]};

                    if (tx_bit == 9) begin
                        tx_busy <= 1'b0;
                        tx_bit  <= 0;
                    end

                    else
                        tx_bit <= tx_bit + 1;

                end

                else
                    tx_count <= tx_count + 1;

            end


            // =====================================================
            // RECEPTOR UART
            // =====================================================

            case (rx_state)

                RX_IDLE: begin
                    rx_count <= 0;
                    rx_bit   <= 0;

                    if (!rx_sync)
                        rx_state <= RX_START;
                end


                // Confirmar start bit en el centro
                RX_START: begin

                    if (rx_count == HALF_CLKS - 1) begin

                        rx_count <= 0;

                        if (!rx_sync)
                            rx_state <= RX_DATA;
                        else
                            rx_state <= RX_IDLE;

                    end

                    else
                        rx_count <= rx_count + 1;

                end


                // Leer 8 bits
                RX_DATA: begin

                    if (rx_count == BIT_CLKS - 1) begin

                        rx_count <= 0;
                        rx_shift[rx_bit] <= rx_sync;

                        if (rx_bit == 7) begin
                            rx_bit   <= 0;
                            rx_state <= RX_STOP;
                        end

                        else
                            rx_bit <= rx_bit + 1;

                    end

                    else
                        rx_count <= rx_count + 1;

                end


                // Stop bit
                RX_STOP: begin

                    if (rx_count == BIT_CLKS - 1) begin

                        rx_count <= 0;

                        if (rx_sync) begin
                            rx_data <= rx_shift;
                            new_rx  <= 1'b1;
                        end

                        rx_state <= RX_IDLE;

                    end

                    else
                        rx_count <= rx_count + 1;

                end

            endcase

        end
    end

endmodule
