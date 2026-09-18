// Convierte un evento del juego en una trama fija de 19 bytes y la escribe
// mediante la interfaz de registros del periferico UART.
module generador_tramas_uart (
    input  logic         clk_i,
    input  logic         rst_i,
    input  logic         evento_i,
    input  logic [1:0]   tipo_i,       // 00=inicio, 01=letra, 10=final
    input  logic         modo_i,
    input  logic [3:0]   longitud_i,
    input  logic [1:0]   resultado_i,
    input  logic [2:0]   intentos_i,
    input  logic [95:0]  patron_ascii_i,
    input  logic [31:0]  uart_rdata_i,
    output logic         uart_write_enable_o,
    output logic [1:0]   uart_addr_o,
    output logic [31:0]  uart_wdata_o,
    output logic         busy_o
);
    typedef enum logic [2:0] {ESPERA, ESCRIBE_DATO, ACTIVA_ENVIO,
                              ESPERA_ACTIVO, ESPERA_FINAL} estado_t;
    estado_t estado;

    logic [4:0] indice;
    logic [1:0] tipo_reg;
    logic modo_reg;
    logic [3:0] longitud_reg;
    logic [1:0] resultado_reg;
    logic [2:0] intentos_reg;
    logic [95:0] patron_reg;
    logic [7:0] byte_actual;

    always_comb begin
        case (indice)
            5'd0: byte_actual = 8'h7E;
            5'd1: begin
                case (tipo_reg)
                    2'b00: byte_actual = "I";
                    2'b01: byte_actual = "L";
                    default: byte_actual = "F";
                endcase
            end
            5'd2: byte_actual = {7'b0, modo_reg};
            5'd3: byte_actual = {4'b0, longitud_reg};
            5'd4: byte_actual = {6'b0, resultado_reg};
            5'd5: byte_actual = {5'b0, intentos_reg};
            5'd18: byte_actual = 8'h0A;
            default: byte_actual = patron_reg[(indice-5'd6)*8 +: 8];
        endcase
    end

    always_comb begin
        uart_write_enable_o = 1'b0;
        uart_addr_o         = 2'b00;
        uart_wdata_o        = 32'h0;
        busy_o              = (estado != ESPERA);

        if (estado == ESCRIBE_DATO) begin
            uart_write_enable_o = 1'b1;
            uart_addr_o         = 2'b00;
            uart_wdata_o        = {24'h0, byte_actual};
        end else if (estado == ACTIVA_ENVIO) begin
            uart_write_enable_o = 1'b1;
            uart_addr_o         = 2'b10;
            uart_wdata_o        = 32'h00000001;
        end else if (estado == ESPERA_ACTIVO || estado == ESPERA_FINAL) begin
            uart_addr_o = 2'b10;
        end
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            estado        <= ESPERA;
            indice        <= 5'd0;
            tipo_reg      <= 2'b00;
            modo_reg      <= 1'b0;
            longitud_reg  <= 4'd0;
            resultado_reg <= 2'b00;
            intentos_reg  <= 3'd0;
            patron_reg    <= '0;
        end else begin
            case (estado)
                ESPERA: begin
                    if (evento_i) begin
                        indice        <= 5'd0;
                        tipo_reg      <= tipo_i;
                        modo_reg      <= modo_i;
                        longitud_reg  <= longitud_i;
                        resultado_reg <= resultado_i;
                        intentos_reg  <= intentos_i;
                        patron_reg    <= patron_ascii_i;
                        estado        <= ESCRIBE_DATO;
                    end
                end
                ESCRIBE_DATO: estado <= ACTIVA_ENVIO;
                ACTIVA_ENVIO: estado <= ESPERA_ACTIVO;
                ESPERA_ACTIVO:
                    if (uart_rdata_i[0]) estado <= ESPERA_FINAL;
                ESPERA_FINAL: begin
                    if (!uart_rdata_i[0]) begin
                        if (indice == 5'd18)
                            estado <= ESPERA;
                        else begin
                            indice <= indice + 5'd1;
                            estado <= ESCRIBE_DATO;
                        end
                    end
                end
                default: estado <= ESPERA;
            endcase
        end
    end
endmodule
