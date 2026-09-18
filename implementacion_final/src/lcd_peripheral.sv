module lcd_peripheral #(
    parameter int CLK_FREQ = 100_000_000
)(
    input  logic        clk_i,
    input  logic        rst_i,

    input  logic        write_enable_i,
    input  logic [1:0]  addr_i,
    input  logic [31:0] wdata_i,
    output logic [31:0] rdata_o,

    output logic        lcd_rs,
    output logic        lcd_rw,
    output logic        lcd_e,
    output logic [7:0]  lcd_data
);

    localparam DATA    = 2'b01;
    localparam CONTROL = 2'b00;

    localparam int US       = CLK_FREQ / 1_000_000;
    localparam int POWER_US = 40_000;
    localparam int SETUP_US = 1;
    localparam int E_US     = 1;
    localparam int NORMAL_US = 50;
    localparam int CLEAR_US  = 2_000;

    typedef enum logic [2:0] {
        POWER, IDLE, SETUP, ENABLE, WAIT
    } state_t;

    state_t state;

    logic [7:0] data_reg;
    logic       busy, done, ready;
    logic [1:0] init_index;

    integer count;
    integer wait_limit;


    // Secuencia de inicialización del LCD
    function automatic [7:0] init_cmd(input logic [1:0] n);
        case (n)
            0: init_cmd = 8'h38;
            1: init_cmd = 8'h0C;
            2: init_cmd = 8'h01;
            default: init_cmd = 8'h06;
        endcase
    endfunction


    // Lectura de registros
    always_comb begin
        rdata_o = 0;

        if (addr_i == DATA)
            rdata_o[7:0] = data_reg;

        if (addr_i == CONTROL) begin
            rdata_o[8] = busy;
            rdata_o[9] = done;
        end
    end


    // El LCD siempre trabaja en escritura
    assign lcd_rw = 1'b0;


    always_ff @(posedge clk_i) begin

        if (rst_i) begin
            state      <= POWER;
            count      <= 0;
            init_index <= 0;
            ready      <= 0;
            busy       <= 1;
            done       <= 0;

            data_reg   <= 0;
            lcd_data   <= 0;
            lcd_rs     <= 0;
            lcd_e      <= 0;
            wait_limit <= 0;
        end

        else begin

            done <= 0;

            case (state)

                // Espera inicial de 40 ms
                POWER: begin
                    if (count >= POWER_US*US-1) begin
                        count      <= 0;
                        lcd_data   <= init_cmd(0);
                        lcd_rs     <= 0;
                        wait_limit <= NORMAL_US*US;
                        state      <= SETUP;
                    end
                    else
                        count <= count + 1;
                end


                // Espera una solicitud
                IDLE: begin
                    busy <= 0;

                    if (write_enable_i && addr_i == DATA)
                        data_reg <= wdata_i[7:0];

                    if (write_enable_i && addr_i == CONTROL) begin

                        // CLEAR
                        if (wdata_i[2]) begin
                            lcd_data   <= 8'h01;
                            lcd_rs     <= 0;
                            wait_limit <= CLEAR_US*US;
                            busy       <= 1;
                            count      <= 0;
                            state      <= SETUP;
                        end

                        // HOME
                        else if (wdata_i[3]) begin
                            lcd_data   <= 8'h02;
                            lcd_rs     <= 0;
                            wait_limit <= CLEAR_US*US;
                            busy       <= 1;
                            count      <= 0;
                            state      <= SETUP;
                        end

                        // START
                        else if (wdata_i[0]) begin
                            lcd_data <= data_reg;
                            lcd_rs   <= wdata_i[1];

                            wait_limit <=
                                (!wdata_i[1] &&
                                (data_reg == 8'h01 ||
                                 data_reg == 8'h02))
                                ? CLEAR_US*US
                                : NORMAL_US*US;

                            busy  <= 1;
                            count <= 0;
                            state <= SETUP;
                        end
                    end
                end


                // Dar tiempo de establecimiento al bus
                SETUP: begin
                    if (count >= SETUP_US*US-1) begin
                        count <= 0;
                        lcd_e <= 1;
                        state <= ENABLE;
                    end
                    else
                        count <= count + 1;
                end


                // Pulso Enable
                ENABLE: begin
                    if (count >= E_US*US-1) begin
                        count <= 0;
                        lcd_e <= 0;
                        state <= WAIT;
                    end
                    else
                        count <= count + 1;
                end


                // Esperar ejecución del LCD
                WAIT: begin
                    if (count >= wait_limit-1) begin
                        count <= 0;

                        // Inicialización aún en curso
                        if (!ready) begin

                            if (init_index == 3) begin
                                ready <= 1;
                                busy  <= 0;
                                state <= IDLE;
                            end

                            else begin
                                init_index <= init_index + 1;

                                lcd_data <=
                                    init_cmd(init_index + 1);

                                lcd_rs <= 0;

                                wait_limit <=
                                    (init_index == 1)
                                    ? CLEAR_US*US
                                    : NORMAL_US*US;

                                state <= SETUP;
                            end
                        end

                        // Operación normal terminada
                        else begin
                            busy  <= 0;
                            done  <= 1;
                            state <= IDLE;
                        end
                    end

                    else
                        count <= count + 1;
                end

            endcase
        end
    end

endmodule