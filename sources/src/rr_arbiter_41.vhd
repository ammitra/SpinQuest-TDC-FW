---------------------------------------------------------------------------------------------------------
--! \file rr_arbiter_41.vhd
--! \brief A round-robin 4:1 arbiter that sends 4 parallel data streams to one serial output stream.
--!
--! \details This module describes a 4:1 arbiter that sends 4 parallel data streams to one serial output stream. 
--! Four data producers (either four `TDC_channel` modules or four `TDC_4ch` modules, or four groups of four `TDC_4ch` modules)
--! will write their hits into their own `ring_buffer` hit FIFOs. These FIFOs have their empty, read_valid, and read_data signals
--! input to this module. The arbiter will read out the non-empty FIFOs in a round robin order and write their data into another 
--! ring buffer, which acts as a shared hit buffer. At the top level of the design, this data is written directly to one port 
--! of a dual port BRAM. 
--! 
--! \author Amitav Mitra, amitra3@jhu.edu
---------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--! Use SlvArray for data input from requester FIFOs
use work.common_types.all;

--! \brief A round-robin 4:1 arbiter that sends 4 parallel data streams to one serial output stream.
--!
--! \details This module describes a 4:1 arbiter that sends 4 parallel data streams to one serial output stream. 
--! Four data producers (either four `TDC_channel` modules or four `TDC_4ch` modules, or four groups of four `TDC_4ch` modules)
--! will write their hits into their own `ring_buffer` hit FIFOs. These FIFOs have their empty, read_valid, and read_data signals
--! input to this module. The arbiter will read out the non-empty FIFOs in a round robin order and write their data into another 
--! ring buffer, which acts as a shared hit buffer. At the top level of the design, this data is written directly to one port 
--! of a dual port BRAM. 
entity rr_arbiter_41 is
    generic (
        DWIDTH : natural := 39 --! Data word width from requester FIFOs
    );
    port (
        -- Input from requesters 
        empty_in : std_logic_vector(0 to 3);             --! Empty signals from requester FIFOs. Nonzero values indicate the FIFO is no longer empty
        valid_in : std_logic_vector(0 to 3);             --! Read valid signals from requester FIFOs. Nonzero values indicate the FIFO is exposing data to be read by the arbiter.
        data_in  : SlvArray(0 to 3)(DWIDTH-1 downto 0);  --! Array of data to be read from requester FIFOs. 
        -- Control inputs
        clk      : in std_logic;    --! 4x RF clock
        rst      : in std_logic;    --! Synchronous, active high reset
        -- Outputs
        enable_out : out std_logic_vector(0 to 3);              --! Read enable signals sent to requester FIFOs.
        data_out   : out std_logic_vector(DWIDTH-1 downto 0);   --! Data from granted requester, sent out for further storage.
        valid_out  : out std_logic                              --! Pulse sent to the write enable port of the next storage module (either intermediate hit buffer or final hit storage BRAM)
    );
end rr_arbiter_41;

architecture Behavioral of rr_arbiter_41 is

    --! State governing which of the requester FIFOs is being granted access to the shared resource
    type state is (
        s_idle, -- All requester FIFOs are empty, arbiter awaits data
        s0,     -- Arbiter granting write access to FIFO 0
        s1,     -- Arbiter granting write access to FIFO 1
        s2,     -- Arbiter granting write access to FIF0 2
        s3,     -- Arbiter granting write access to FIFO 3
        s_tx    -- FIFO has been granted write access and exposes data to arbiter, which reads the data and sends it out for writing
    );
    signal present_state, next_state, buffer_state: state;

    --! SLV representing which FIFO(s) request access to the shared resource.
    signal request_reg : std_logic_vector(0 to 3);
    --! Integer representing the FIFO to which write access is being granted.
    signal which_fifo : integer range 0 to 3;
    
begin

    -- Invert the empty signals from the FIFOs to act as the request register 
    request_reg <= not empty_in; 
    
    --! \brief Perform the round robin arbitration to grant access to the shared resource.
    --! \details Arbiter monitors the request register and issue grants based on round-robin arbitration.
    --! When a request is observed (a requester FIFO reports non-empty), the arbiter issues a grant and the 
    --! state moves to transmit, where a read is granted to the FIFO and the arbiter waits for the FIFO to
    --! return the read valid flag. Simultaneously, a lookup table writes a buffer state that tells the arbiter which FIFO should be 
    --! granted access to the shared resource next, given round robin priority. After the FIFO read valid flag is
    --! pulsed, the state machine moves to the buffered state and the process continues until there are no more requests.
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
                    when s_idle =>                          -- All FIFOs are empty, wait for request_reg to change from "0000"
                        valid_out <= '0';                   -- Lower the valid flag controlling write access to the downstream memory
                        if request_reg(0) = '1' then        -- FIFO 0 is no longer empty
                            enable_out   <= "1000";         -- From the idle state, round robin priority dictates that FIFO 0 should be granted access 
                            which_fifo   <= 0;              -- Track that FIFO 0 is being granted access
                            next_state   <= s_tx;           -- Move to the transmit state where we actually grant the write access
                            buffer_state <= s0;             -- Buffer the next state to run after the transmission finishes
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
                        -- Disable the read_enable so it's only high for one clock period (avoids losing data in the FIFO if there are multiple hits)
                        enable_out(which_fifo) <= '0';
                        -- Tie the data output to the read data of the granted FIFO requester
                        data_out <= data_in(which_fifo);
                        -- Send the valid pulse which will act as the write enable for the downstream memory
                        valid_out <= '1';
                        -- Wait for the upstream FIFO to return the valid read flag before moving to next (buffered) state
                        if valid_in(which_fifo) = '1' then 
                            -- The FIFO has successfully read out
                            next_state <= buffer_state; -- mMve to next state in round robin
                        end if;
                    when others => 
                        null;
                end case;
            end if;
        end if;
    end process arbitrate;

end Behavioral;
