-----------------------------------------------------------------------------------
-- rr_arbiter_41.vhd
--
-- 4:1 mux arbiter using round-robin priority. Four TDC modules will write their hits
-- into their own 4-deep FIFOs. These FIFOs will have their empty, read_valid, and 
-- read_data signals input to this module. The arbiter will read out non-empty FIFOs
-- in a round-robin order and put their data into a common ring buffer (event FIFO).
--
-- NOTE: due to vivado freaking out over vhdl2008, I am hard-coding the slv array for
-- the data_in port. For 39-bit data words, data_in must be slv39_array(0 to 3)
--
-- V0: 07/10/2024
--  * first version, passed behavioral simulation. No handling of switching to different 
--    output ring buffers for trigger accept yet.
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.common_types.all;

entity rr_arbiter_41 is
    generic (
        DWIDTH : natural := 39 -- data word width from requester FIFOs
    );
    port (
        -- Input from requesters 
        empty_in : std_logic_vector(0 to 3);    -- Empty signals from requester FIFOs
        valid_in : std_logic_vector(0 to 3);    -- Read valid signals from requester FIFOs
        data_in  : SlvArray(0 to 3)(DWIDTH-1 downto 0);  -- Read data from requester FIFOs
        -- Control inputs
        clk      : in std_logic;    -- 4x system clock (212.4 MHz)
        rst      : in std_logic;    -- synchronous, active high reset
        -- Outputs
        enable_out : out std_logic_vector(0 to 3);  -- Read enable signals sent to requester FIFOs
        data_out   : out std_logic_vector(DWIDTH-1 downto 0);   -- Data from granted requester, sent to event ring buffer
        valid_out  : out std_logic     -- sent to wr_enable of the event ring buffer alongside data_out
    );
end rr_arbiter_41;

architecture Behavioral of rr_arbiter_41 is

    type state is (s_idle, s_tx, s0, s1, s2, s3);
    signal present_state, next_state, buffer_state: state;
    signal request_reg : std_logic_vector(0 to 3);
    -- Store an integer to determine which of the inputs has been granted
    signal which_fifo : integer range 0 to 3;
    
begin

    -- Invert the empty signals from the FIFOs to act as the request register 
    request_reg <= not empty_in; 
    
    -- Monitor the request register and issue grants based on round-robin arbitration.
    -- When a request is observed (a non-empty requester FIFO), a grant is issued and the 
    -- state moves to transmit, where a FIFO read is granted and the system waits for the 
    -- read valid flag from the FIFO. After the read valid flag is pulsed, the state machine
    -- moves to the buffered state and the process continues until there are no more requests.
    arbitrate : process(all)
    begin
        if rising_edge(clk) then 
            if rst = '1' then 
                valid_out     <= '0';
                data_out      <= (others => '0');
                enable_out    <= (others => '0');
                buffer_state  <= s_idle;
                next_state    <= s_idle;
                present_state <= s_idle;
                which_fifo    <= 0;
            else
                present_state <= next_state;
                case present_state is
                    when s_idle =>
                        valid_out <= '0';
                        if request_reg(0) = '1' then
                            enable_out   <= "1000";
                            which_fifo   <= 0;
                            next_state   <= s_tx;
                            buffer_state <= s0;
                        elsif request_reg(1) = '1' then
                            enable_out   <= "0100";
                            which_fifo   <= 1;
                            next_state   <= s_tx;
                            buffer_state <= s1;
                        elsif request_reg(2) = '1' then
                            enable_out   <= "0010";
                            which_fifo   <= 2;
                            next_state   <= s_tx;
                            buffer_state <= s2;
                        elsif request_reg(3) = '1' then
                            enable_out   <= "0001";
                            which_fifo   <= 3;
                            next_state   <= s_tx;
                            buffer_state <= s3;
                        else
                            enable_out   <= (others => '0');
                            data_out     <= (others => '0');
                            which_fifo   <= 0;
                            buffer_state <= s_idle;
                            next_state   <= s_idle;
                        end if;
                    when s0 =>
                        valid_out <= '0';
                        if request_reg(1) = '1' then
                            enable_out   <= "0100";
                            which_fifo   <= 1;
                            next_state   <= s_tx;
                            buffer_state <= s1;
                        elsif request_reg(2) = '1' then
                            enable_out   <= "0010";
                            which_fifo   <= 2;
                            next_state   <= s_tx;
                            buffer_state <= s2;
                        elsif request_reg(3) = '1' then
                            enable_out   <= "0001";
                            which_fifo   <= 3;
                            next_state   <= s_tx;
                            buffer_state <= s3;
                        elsif request_reg(0) = '1' then
                            enable_out   <= "1000";
                            which_fifo   <= 0;
                            next_state   <= s_tx;
                            buffer_state <= s0;
                        else
                            enable_out   <= (others => '0');
                            data_out     <= (others => '0');
                            which_fifo   <= 0;
                            buffer_state <= s_idle;
                            next_state   <= s_idle;
                        end if;
                    when s1 =>
                        valid_out <= '0';
                        if request_reg(2) = '1' then
                            enable_out   <= "0010";
                            which_fifo   <= 2;
                            next_state   <= s_tx;
                            buffer_state <= s2;
                        elsif request_reg(3) = '1' then
                            enable_out   <= "0001";
                            which_fifo   <= 3;
                            next_state   <= s_tx;
                            buffer_state <= s3;
                        elsif request_reg(0) = '1' then
                            enable_out   <= "1000";
                            which_fifo   <= 0;
                            next_state   <= s_tx;
                            buffer_state <= s0;
                        elsif request_reg(1) = '1' then
                            enable_out   <= "0100";
                            which_fifo   <= 1;
                            next_state   <= s_tx;
                            buffer_state <= s1;
                        else
                            enable_out   <= (others => '0');
                            data_out     <= (others => '0');
                            which_fifo   <= 0;
                            buffer_state <= s_idle;
                            next_state   <= s_idle;
                        end if;
                    when s2 =>
                        valid_out <= '0';
                        if request_reg(3) = '1' then
                            enable_out   <= "0001";
                            which_fifo   <= 3;
                            next_state   <= s_tx;
                            buffer_state <= s3;
                        elsif request_reg(0) = '1' then
                            enable_out   <= "1000";
                            which_fifo   <= 0;
                            next_state   <= s_tx;
                            buffer_state <= s0;
                        elsif request_reg(1) = '1' then
                            enable_out   <= "0100";
                            which_fifo   <= 1;
                            next_state   <= s_tx;
                            buffer_state <= s1;
                        elsif request_reg(2) = '1' then
                            enable_out   <= "0010";
                            which_fifo   <= 2;
                            next_state   <= s_tx;
                            buffer_state <= s2;
                        else
                            enable_out   <= (others => '0');
                            data_out     <= (others => '0');
                            which_fifo   <= 0;
                            buffer_state <= s_idle;
                            next_state   <= s_idle;
                        end if;
                    when s3 =>
                        valid_out <= '0';
                        if request_reg(0) = '1' then
                            enable_out   <= "1000";
                            which_fifo   <= 0;
                            next_state   <= s_tx;
                            buffer_state <= s0;
                        elsif request_reg(1) = '1' then
                            enable_out   <= "0100";
                            which_fifo   <= 1;
                            next_state   <= s_tx;
                            buffer_state <= s1;
                        elsif request_reg(2) = '1' then
                            enable_out   <= "0010";
                            which_fifo   <= 2;
                            next_state   <= s_tx;
                            buffer_state <= s2;
                        elsif request_reg(3) = '1' then
                            enable_out   <= "0001";
                            which_fifo   <= 3;
                            next_state   <= s_tx;
                            buffer_state <= s3;
                        else
                            enable_out   <= (others => '0');
                            data_out     <= (others => '0');
                            which_fifo   <= 0;
                            buffer_state <= s_idle;
                            next_state   <= s_idle;
                        end if;
                    when s_tx =>
                        -- disable the read_enable so it's only high for one clock period (avoids losing data in the FIFO if there are multiple hits)
                        enable_out(which_fifo) <= '0';
                        -- Tie the data output to the read data of the granted FIFO requester
                        data_out <= data_in(which_fifo);
                        valid_out <= '1';
                        -- wait for the FIFO to return the valid read flag before moving to next (buffered) state
                        if valid_in(which_fifo) = '1' then 
                            -- The FIFO has successfully read out
                            next_state <= buffer_state; -- move to next state in round robin
                        end if;
                    when others => 
                        null;
                end case;
            end if;
        end if;
    end process arbitrate;
    
       
    -- State_assignment: process (clk, rst)
    --     begin  
    --         if rising_edge(clk) then  
    --             if rst = '1' then 
    --                 present_state <= s_idle;
    --             else
    --                 present_state <= next_state;
    --             end if;
    --         end if;
    --     end process State_assignment;

end Behavioral;
