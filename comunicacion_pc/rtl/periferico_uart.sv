// Periferico UART completo con interfaz estandar de registros de 32 bits.
module periferico_uart #(
    parameter int RX_BAUD_X16_TICKS = 54,
    parameter int TX_BAUD_TICKS     = 868
) (
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic        write_enable_i,
    input  logic [1:0]  addr_i,
    input  logic [31:0] wdata_i,
    output logic [31:0] rdata_o,
    input  logic        rx_i,
    output logic        tx_o,
    output logic        new_rx_o,
    output logic        busy_o
);
    logic [7:0] rx_data;
    logic [7:0] tx_data;
    logic       rx_valid;
    logic       rx_event;
    logic       send;
    logic       tx_start;
    logic       tx_done_core;
    logic       tx_complete;

    UART #(
        .RX_BAUD_X16_TICKS(RX_BAUD_X16_TICKS),
        .TX_BAUD_TICKS    (TX_BAUD_TICKS)
    ) u_uart (
        .clk         (clk_i),
        .reset       (rst_i),
        .tx_start    (tx_start),
        .tx_rdy      (tx_done_core),
        .rx_data_rdy (rx_valid),
        .data_in     (tx_data),
        .data_out    (rx_data),
        .rx          (rx_i),
        .tx          (tx_o)
    );

    control_uart u_control (
        .clk_i         (clk_i),
        .rst_i         (rst_i),
        .send_i        (send),
        .tx_done_i     (tx_done_core),
        .rx_valid_i    (rx_valid),
        .tx_start_o    (tx_start),
        .tx_complete_o (tx_complete),
        .rx_event_o    (rx_event),
        .busy_o        (busy_o)
    );

    banco_registros_uart u_registros (
        .clk_i          (clk_i),
        .rst_i          (rst_i),
        .write_enable_i (write_enable_i),
        .addr_i         (addr_i),
        .wdata_i        (wdata_i),
        .rdata_o        (rdata_o),
        .rx_data_i      (rx_data),
        .rx_valid_i     (rx_event),
        .tx_done_i      (tx_complete),
        .tx_data_o      (tx_data),
        .send_o         (send),
        .new_rx_o       (new_rx_o)
    );
endmodule
