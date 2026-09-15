library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Receptor entregado por el profesor, adaptado para el reloj de 100 MHz
-- de la Nexys 4 y una comunicacion 8N1 a 115200 baudios.
entity UART_rx is
    generic (BAUD_X16_CLK_TICKS : positive := 54);
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        rx_data_in  : in  std_logic;
        rx_data_rdy : out std_logic;
        rx_data_out : out std_logic_vector(7 downto 0)
    );
end entity UART_rx;

architecture rtl of UART_rx is
    type rx_state_t is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal state       : rx_state_t := IDLE;
    signal rx_meta     : std_logic := '1';
    signal rx_sync     : std_logic := '1';
    signal baud_x16_ce : std_logic := '0';
    signal shift_reg   : std_logic_vector(7 downto 0) := (others => '0');
    signal sample_cnt  : integer range 0 to 15 := 0;
    signal bit_index   : integer range 0 to 7 := 0;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                rx_meta <= '1';
                rx_sync <= '1';
            else
                rx_meta <= rx_data_in;
                rx_sync <= rx_meta;
            end if;
        end if;
    end process;

    process(clk)
        variable count : integer range 0 to BAUD_X16_CLK_TICKS - 1 :=
                         BAUD_X16_CLK_TICKS - 1;
    begin
        if rising_edge(clk) then
            baud_x16_ce <= '0';
            if reset = '1' then
                count := BAUD_X16_CLK_TICKS - 1;
            elsif count = 0 then
                count := BAUD_X16_CLK_TICKS - 1;
                baud_x16_ce <= '1';
            else
                count := count - 1;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            rx_data_rdy <= '0';
            if reset = '1' then
                state       <= IDLE;
                shift_reg   <= (others => '0');
                rx_data_out <= (others => '0');
                sample_cnt  <= 0;
                bit_index   <= 0;
            elsif baud_x16_ce = '1' then
                case state is
                    when IDLE =>
                        sample_cnt <= 0;
                        bit_index  <= 0;
                        if rx_sync = '0' then state <= START_BIT; end if;

                    when START_BIT =>
                        if sample_cnt = 7 then
                            sample_cnt <= 0;
                            if rx_sync = '0' then state <= DATA_BITS;
                            else state <= IDLE;
                            end if;
                        else
                            sample_cnt <= sample_cnt + 1;
                        end if;

                    when DATA_BITS =>
                        if sample_cnt = 15 then
                            sample_cnt <= 0;
                            shift_reg(bit_index) <= rx_sync;
                            if bit_index = 7 then state <= STOP_BIT;
                            else bit_index <= bit_index + 1;
                            end if;
                        else
                            sample_cnt <= sample_cnt + 1;
                        end if;

                    when STOP_BIT =>
                        if sample_cnt = 15 then
                            sample_cnt <= 0;
                            state <= IDLE;
                            if rx_sync = '1' then
                                rx_data_out <= shift_reg;
                                rx_data_rdy <= '1';
                            end if;
                        else
                            sample_cnt <= sample_cnt + 1;
                        end if;
                end case;
            end if;
        end if;
    end process;
end architecture rtl;
