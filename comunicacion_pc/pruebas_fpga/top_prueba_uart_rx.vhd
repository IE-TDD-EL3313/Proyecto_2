library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Muestra en LED7..LED0 el ultimo byte recibido por USB-UART.
entity top_prueba_uart_rx is
    port (clk : in std_logic; btnCpuReset : in std_logic; RsRx : in std_logic;
          led : out std_logic_vector(9 downto 0));
end entity;

architecture rtl of top_prueba_uart_rx is
    signal reset, rx_data_rdy, byte_toggle : std_logic := '0';
    signal rx_data, data_latch : std_logic_vector(7 downto 0) := (others => '0');
begin
    reset <= not btnCpuReset;

    receptor : entity work.UART_rx
        generic map (BAUD_X16_CLK_TICKS => 54)
        port map (clk => clk, reset => reset, rx_data_in => RsRx,
                  rx_data_rdy => rx_data_rdy, rx_data_out => rx_data);

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                data_latch <= (others => '0'); byte_toggle <= '0';
            elsif rx_data_rdy = '1' then
                data_latch <= rx_data; byte_toggle <= not byte_toggle;
            end if;
        end if;
    end process;

    led(7 downto 0) <= data_latch;
    led(8) <= byte_toggle;
    led(9) <= '1' when unsigned(data_latch) >= 65 and unsigned(data_latch) <= 90 else '0';
end architecture;
