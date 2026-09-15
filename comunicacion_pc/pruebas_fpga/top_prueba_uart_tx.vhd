library ieee;
use ieee.std_logic_1164.all;

-- Envia una letra A por USB-UART cada vez que se presiona BTNC.
entity top_prueba_uart_tx is
    port (
        clk         : in  std_logic;
        btnCpuReset : in  std_logic;
        btnC        : in  std_logic;
        RsTx        : out std_logic;
        led         : out std_logic_vector(1 downto 0)
    );
end entity;

architecture rtl of top_prueba_uart_tx is
    signal reset      : std_logic;
    signal btn_meta   : std_logic := '0';
    signal btn_sync   : std_logic := '0';
    signal btn_prev   : std_logic := '0';
    signal tx_start   : std_logic := '0';
    signal tx_done    : std_logic;
    signal done_light : std_logic := '0';
begin
    reset <= not btnCpuReset;

    -- Sincroniza BTNC y genera un pulso al presionarlo.
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                btn_meta   <= '0';
                btn_sync   <= '0';
                btn_prev   <= '0';
                tx_start   <= '0';
                done_light <= '0';
            else
                btn_meta <= btnC;
                btn_sync <= btn_meta;
                btn_prev <= btn_sync;
                tx_start <= btn_sync and not btn_prev;
                if tx_done = '1' then
                    done_light <= not done_light;
                end if;
            end if;
        end if;
    end process;

    transmisor : entity work.UART_tx
        generic map (BAUD_CLK_TICKS => 868)
        port map (
            clk         => clk,
            reset       => reset,
            tx_start    => tx_start,
            tx_rdy      => tx_done,
            tx_data_in  => x"41",
            tx_data_out => RsTx
        );

    led(0) <= done_light;
    led(1) <= tx_start;
end architecture;
