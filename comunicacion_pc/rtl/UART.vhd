library ieee;
use ieee.std_logic_1164.all;

-- Integra el receptor y el transmisor entregados por el profesor.
entity UART is
    generic (
        RX_BAUD_X16_TICKS : positive := 54;
        TX_BAUD_TICKS     : positive := 868
    );
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        tx_start    : in  std_logic;
        tx_rdy      : out std_logic;
        rx_data_rdy : out std_logic;
        data_in     : in  std_logic_vector(7 downto 0);
        data_out    : out std_logic_vector(7 downto 0);
        rx          : in  std_logic;
        tx          : out std_logic
    );
end entity UART;

architecture rtl of UART is
begin
    transmitter : entity work.UART_tx
        generic map (BAUD_CLK_TICKS => TX_BAUD_TICKS)
        port map (
            clk         => clk,
            reset       => reset,
            tx_start    => tx_start,
            tx_rdy      => tx_rdy,
            tx_data_in  => data_in,
            tx_data_out => tx
        );

    receiver : entity work.UART_rx
        generic map (BAUD_X16_CLK_TICKS => RX_BAUD_X16_TICKS)
        port map (
            clk         => clk,
            reset       => reset,
            rx_data_in  => rx,
            rx_data_rdy => rx_data_rdy,
            rx_data_out => data_out
        );
end architecture rtl;
