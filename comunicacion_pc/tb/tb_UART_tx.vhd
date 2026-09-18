library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_UART_tx is end entity;

architecture sim of tb_UART_tx is
    constant CLK_PERIOD : time := 10 ns;
    constant TICKS_TEST : positive := 8;
    constant BIT_PERIOD : time := TICKS_TEST * CLK_PERIOD;
    constant BYTE_A     : std_logic_vector(7 downto 0) := x"41";
    signal clk, reset, tx_start, tx_rdy : std_logic := '0';
    signal tx_data_in : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_data_out : std_logic;
    signal done_count : natural := 0;

    procedure check_bit(signal line : in std_logic; constant expected : in std_logic) is
    begin
        wait for BIT_PERIOD / 2;
        assert line = expected report "Bit UART incorrecto" severity failure;
        wait for BIT_PERIOD / 2;
    end procedure;
begin
    clk <= not clk after CLK_PERIOD / 2;

    dut : entity work.UART_tx
        generic map (BAUD_CLK_TICKS => TICKS_TEST)
        port map (clk => clk, reset => reset, tx_start => tx_start,
                  tx_rdy => tx_rdy, tx_data_in => tx_data_in,
                  tx_data_out => tx_data_out);

    process(clk)
    begin
        if rising_edge(clk) and tx_rdy = '1' then
            done_count <= done_count + 1;
        end if;
    end process;

    process
    begin
        reset <= '1'; wait for 3 * CLK_PERIOD;
        reset <= '0'; wait until rising_edge(clk);
        tx_data_in <= BYTE_A;
        tx_start <= '1'; wait until rising_edge(clk);
        tx_start <= '0';

        check_bit(tx_data_out, '0');
        for i in 0 to 7 loop
            check_bit(tx_data_out, BYTE_A(i));
        end loop;
        check_bit(tx_data_out, '1');
        wait for 2 * CLK_PERIOD;
        assert done_count = 1 report "No genero pulso de fin" severity failure;
        report "OK: UART TX transmitio la letra A correctamente" severity note;
        std.env.finish;
    end process;
end architecture sim;
