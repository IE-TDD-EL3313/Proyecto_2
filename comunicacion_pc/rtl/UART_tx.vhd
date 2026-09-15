library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Transmisor entregado por el profesor, adaptado al reloj de 100 MHz.
-- Formato: 115200 baudios, 8 bits, sin paridad y un bit de parada.
entity UART_tx is
    generic (
        BAUD_CLK_TICKS : positive := 868
    );
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        tx_start    : in  std_logic;
        tx_rdy      : out std_logic;
        tx_data_in  : in  std_logic_vector(7 downto 0);
        tx_data_out : out std_logic
    );
end entity UART_tx;

architecture rtl of UART_tx is
    type tx_state_t is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal state      : tx_state_t := IDLE;
    signal baud_count : integer range 0 to BAUD_CLK_TICKS - 1 := 0;
    signal bit_index  : integer range 0 to 7 := 0;
    signal data_latch : std_logic_vector(7 downto 0) := (others => '0');
begin
    process(clk)
    begin
        if rising_edge(clk) then
            tx_rdy <= '0';

            if reset = '1' then
                state       <= IDLE;
                baud_count  <= 0;
                bit_index   <= 0;
                data_latch  <= (others => '0');
                tx_data_out <= '1';
            else
                case state is
                    when IDLE =>
                        tx_data_out <= '1';
                        baud_count  <= 0;
                        bit_index   <= 0;
                        if tx_start = '1' then
                            data_latch  <= tx_data_in;
                            tx_data_out <= '0';
                            state       <= START_BIT;
                        end if;

                    when START_BIT =>
                        if baud_count = BAUD_CLK_TICKS - 1 then
                            baud_count  <= 0;
                            tx_data_out <= data_latch(0);
                            state       <= DATA_BITS;
                        else
                            baud_count <= baud_count + 1;
                        end if;

                    when DATA_BITS =>
                        if baud_count = BAUD_CLK_TICKS - 1 then
                            baud_count <= 0;
                            if bit_index = 7 then
                                tx_data_out <= '1';
                                state       <= STOP_BIT;
                            else
                                bit_index   <= bit_index + 1;
                                tx_data_out <= data_latch(bit_index + 1);
                            end if;
                        else
                            baud_count <= baud_count + 1;
                        end if;

                    when STOP_BIT =>
                        if baud_count = BAUD_CLK_TICKS - 1 then
                            baud_count <= 0;
                            tx_rdy     <= '1';
                            state      <= IDLE;
                        else
                            baud_count <= baud_count + 1;
                        end if;
                end case;
            end if;
        end if;
    end process;
end architecture rtl;
