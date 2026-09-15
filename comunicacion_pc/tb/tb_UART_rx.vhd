library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_UART_rx is end entity;

architecture sim of tb_UART_rx is
    constant CLK_PERIOD : time := 10 ns;
    constant BIT_PERIOD : time := 8680 ns;
    signal clk         : std_logic := '0';
    signal reset       : std_logic := '1';
    signal rx_data_in  : std_logic := '1';
    signal rx_data_rdy : std_logic;
    signal rx_data_out : std_logic_vector(7 downto 0);
    signal last_byte   : std_logic_vector(7 downto 0) := (others => '0');
    signal byte_count  : natural := 0;

    procedure send_byte(signal line : out std_logic;
                        constant value : in std_logic_vector(7 downto 0)) is
    begin
        line <= '0'; wait for BIT_PERIOD;
        for i in 0 to 7 loop
            line <= value(i); wait for BIT_PERIOD;
        end loop;
        line <= '1'; wait for BIT_PERIOD;
    end procedure;
begin
    clk <= not clk after CLK_PERIOD / 2;

    dut : entity work.UART_rx
        port map (clk => clk, reset => reset, rx_data_in => rx_data_in,
                  rx_data_rdy => rx_data_rdy, rx_data_out => rx_data_out);

    process(clk)
    begin
        if rising_edge(clk) and rx_data_rdy = '1' then
            last_byte  <= rx_data_out;
            byte_count <= byte_count + 1;
        end if;
    end process;

    process
    begin
        wait for 10 * CLK_PERIOD;
        reset <= '0';
        wait for BIT_PERIOD;
        send_byte(rx_data_in, x"41");
        wait for 2 * CLK_PERIOD;
        assert byte_count = 1 and last_byte = x"41"
            report "No recibio A" severity failure;

        wait for BIT_PERIOD;
        send_byte(rx_data_in, x"52");
        wait for 2 * CLK_PERIOD;
        assert byte_count = 2 and last_byte = x"52"
            report "No recibio R" severity failure;

        report "OK: UART RX recibio A y R correctamente" severity note;
        std.env.finish;
    end process;
end architecture sim;
