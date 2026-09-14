// Controlador de escritura para LCD paralelo 16x2 compatible con HD44780.
// La interfaz de registros no hace lecturas del LCD: lcd_rw_o permanece en 0.
module lcd_16x2 #(
    parameter int unsigned CLK_HZ        = 100_000_000,
    parameter int unsigned POWER_ON_US   = 20_000,
    parameter int unsigned E_PULSE_US    = 1,
    parameter int unsigned CMD_WAIT_US   = 50,
    parameter int unsigned CLEAR_WAIT_US = 2_000
) (
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic        write_enable_i,
    input  logic [1:0]  addr_i,
    input  logic [31:0] wdata_i,
    output logic [31:0] rdata_o,

    output logic        lcd_rs_o,
    output logic        lcd_rw_o,
    output logic        lcd_e_o,
    output logic [7:0]  lcd_data_o
);

    localparam int unsigned CYCLES_PER_US = (CLK_HZ + 999_999) / 1_000_000;
    localparam int unsigned POWER_CYCLES  = (POWER_ON_US   * CYCLES_PER_US > 0) ? POWER_ON_US   * CYCLES_PER_US : 1;
    localparam int unsigned E_CYCLES      = (E_PULSE_US    * CYCLES_PER_US > 0) ? E_PULSE_US    * CYCLES_PER_US : 1;
    localparam int unsigned CMD_CYCLES    = (CMD_WAIT_US   * CYCLES_PER_US > 0) ? CMD_WAIT_US   * CYCLES_PER_US : 1;
    localparam int unsigned CLEAR_CYCLES  = (CLEAR_WAIT_US * CYCLES_PER_US > 0) ? CLEAR_WAIT_US * CYCLES_PER_US : 1;
    localparam int unsigned COUNT_MAX     = (POWER_CYCLES > CLEAR_CYCLES) ? POWER_CYCLES : CLEAR_CYCLES;
    localparam int unsigned COUNT_W       = (COUNT_MAX < 2) ? 1 : $clog2(COUNT_MAX);

    typedef enum logic [2:0] {
        ST_POWER_WAIT,
        ST_INIT_SETUP,
        ST_IDLE,
        ST_E_HIGH,
        ST_EXEC_WAIT
    } state_t;

    state_t state_q;
    logic [COUNT_W-1:0] count_q;
    logic [2:0]         init_index_q;
    logic               init_active_q;
    logic               rs_reg_q;
    logic [7:0]         data_reg_q;
    logic               tx_rs_q;
    logic [7:0]         tx_data_q;
    logic               tx_is_long_q;
    logic               done_q;

    function automatic logic [7:0] init_command(input logic [2:0] index);
        case (index)
            3'd0: init_command = 8'h38; // 8 bits, 2 lineas, fuente 5x8
            3'd1: init_command = 8'h0C; // display encendido, cursor apagado
            3'd2: init_command = 8'h06; // incremento de cursor
            default: init_command = 8'h01; // limpiar display
        endcase
    endfunction

    always_comb begin
        rdata_o = 32'b0;
        if (addr_i == 2'b00) begin
            rdata_o[1] = rs_reg_q;
            rdata_o[8] = (state_q != ST_IDLE);
            rdata_o[9] = done_q;
        end else if (addr_i == 2'b01) begin
            rdata_o[7:0] = data_reg_q;
        end
    end

    always_comb begin
        lcd_rs_o   = tx_rs_q;
        lcd_rw_o   = 1'b0;
        lcd_e_o    = (state_q == ST_E_HIGH);
        lcd_data_o = tx_data_q;
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            state_q      <= ST_POWER_WAIT;
            count_q      <= '0;
            init_index_q <= '0;
            init_active_q <= 1'b1;
            rs_reg_q     <= 1'b0;
            data_reg_q   <= 8'h00;
            tx_rs_q      <= 1'b0;
            tx_data_q    <= 8'h00;
            tx_is_long_q <= 1'b0;
            done_q       <= 1'b0;
        end else begin
            // Los registros de configuracion se pueden preparar mientras el LCD esta ocupado.
            if (write_enable_i && (addr_i == 2'b00))
                rs_reg_q <= wdata_i[1];
            if (write_enable_i && (addr_i == 2'b01))
                data_reg_q <= wdata_i[7:0];

            case (state_q)
                ST_POWER_WAIT: begin
                    if (count_q == POWER_CYCLES - 1) begin
                        count_q <= '0;
                        state_q <= ST_INIT_SETUP;
                    end else
                        count_q <= count_q + 1'b1;
                end

                ST_INIT_SETUP: begin
                    tx_rs_q      <= 1'b0;
                    tx_data_q    <= init_command(init_index_q);
                    tx_is_long_q <= (init_index_q == 3'd3);
                    count_q      <= '0;
                    state_q      <= ST_E_HIGH;
                end

                ST_IDLE: begin
                    // clear y home son comandos, por lo que tienen prioridad sobre start.
                    if (write_enable_i && (addr_i == 2'b00) &&
                        (wdata_i[2] || wdata_i[3] || wdata_i[0])) begin
                        done_q  <= 1'b0;
                        count_q <= '0;
                        if (wdata_i[2]) begin
                            tx_rs_q      <= 1'b0;
                            tx_data_q    <= 8'h01;
                            tx_is_long_q <= 1'b1;
                        end else if (wdata_i[3]) begin
                            tx_rs_q      <= 1'b0;
                            tx_data_q    <= 8'h02;
                            tx_is_long_q <= 1'b1;
                        end else begin
                            tx_rs_q      <= wdata_i[1];
                            tx_data_q    <= data_reg_q;
                            tx_is_long_q <= 1'b0;
                        end
                        state_q <= ST_E_HIGH;
                    end
                end

                ST_E_HIGH: begin
                    if (count_q == E_CYCLES - 1) begin
                        count_q <= '0;
                        state_q <= ST_EXEC_WAIT;
                    end else
                        count_q <= count_q + 1'b1;
                end

                ST_EXEC_WAIT: begin
                    if (count_q == ((tx_is_long_q ? CLEAR_CYCLES : CMD_CYCLES) - 1)) begin
                        count_q <= '0;
                        if (init_active_q) begin
                            if (init_index_q == 3'd3) begin
                                init_index_q <= 3'd4;
                                init_active_q <= 1'b0;
                                state_q <= ST_IDLE;
                            end else begin
                                init_index_q <= init_index_q + 1'b1;
                                state_q <= ST_INIT_SETUP;
                            end
                        end else begin
                            done_q  <= 1'b1;
                            state_q <= ST_IDLE;
                        end
                    end else
                        count_q <= count_q + 1'b1;
                end

                default: state_q <= ST_POWER_WAIT;
            endcase
        end
    end

endmodule
