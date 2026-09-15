library ieee;
use ieee.std_logic_1164.all;

-- Devuelve a la computadora cada byte que recibe por USB-UART.
entity top_prueba_uart_eco is
    port (
        clk         : in  std_logic;
        btnCpuReset : in  std_logic;
        RsRx        : in  std_logic;
        RsTx        : out std_logic;
        led         : out std_logic_vector(9 downto 0)
    );
end entity;

architecture rtl of top_prueba_uart_eco is
    signal reset       : std_logic;
    signal rx_data_rdy : std_logic;
    signal tx_done     : std_logic;
    signal rx_data     : std_logic_vector(7 downto 0);
    signal echo_data   : std_logic_vector(7 downto 0) := (others => '0');
    signal echo_start  : std_logic := '0';
    signal byte_toggle : std_logic := '0';
begin
    reset <= not btnCpuReset;

    uart_core : entity work.UART
        port map (
            clk         => clk,
            reset       => reset,
            tx_start    => echo_start,
            tx_rdy      => tx_done,
            rx_data_rdy => rx_data_rdy,
            data_in     => echo_data,
            data_out    => rx_data,
            rx          => RsRx,
            tx          => RsTx
        );

    process(clk)
    begin
        if rising_edge(clk) then
            echo_start <= '0';
            if reset = '1' then
                echo_data   <= (others => '0');
                byte_toggle <= '0';
            elsif rx_data_rdy = '1' then
                echo_data   <= rx_data;
                echo_start  <= '1';
                byte_toggle <= not byte_toggle;
            end if;
        end if;
    end process;

    led(7 downto 0) <= echo_data;
    led(8) <= byte_toggle;
    led(9) <= tx_done;
end architecture rtl;
