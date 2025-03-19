-----------------------------------------------------------------------------------
-- encoder.vhd
--
-- Encodes the arrival time of valid hits into a N+11-bit data word
--  * N = g_coarse_bits == length of coarse counter (RF bucket ID)
--  * 11 = (5-bit fine time) + (6-bit channelID)
--
-- V0: 23/09/2024
--  * first version, passed behavioral simulation tests
-- V0.1: 23/09/2024
--  * added valid hit detection (pulse duration requirement set by generic)
-- V0.2: 24/09/2024
--  * handled edge case where hit arrives on rising edge of RF clock
-- V0.3: 09/12/2024
--  * simplified fine counter - no need to calculate true fine time, it gets sent from sampler
-- V0.4: 17/12/2024
--  * fixed state machine logic for saturation duration counting
-- V0.5: 24/02/2025
--  * refactored comb+seq FSMs into one seq FSM to avoid latches
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.common_types.all;

entity encoder is
    generic (
        g_coarse_bits : natural := 28;
        g_channel_id  : natural := 0;
        g_sat_duration : natural range 1 to 5 := 3   -- number of clk_0 cycles the signal needs to be saturated to be considered valid
    );
    port (
        clk_0       : in std_logic; -- 4x RF clock 0degree phase
        fine_i      : in std_logic_vector(9 downto 0);  -- [9:2] are hit pattern [1:0] are fine counter
        reset_i     : in std_logic;
        coarse_i    : in std_logic_vector(g_coarse_bits-1 downto 0);
        timestamp_o : out std_logic_vector(g_coarse_bits+10 downto 0);   -- (coarse) + [ (5-bit fine) + (6-bit channel id) ] - 1
        valid_o     : out std_logic
    );
end encoder;

architecture Behavioral of encoder is

    -- Preserve architecture
    attribute keep_hierarchy : string;
    attribute keep : string;
    attribute dont_touch : string;
    attribute keep_hierarchy of Behavioral : architecture is "true";

    -- Signals for the current and previous input from sampler module
    signal fine_last  : std_logic_vector(9 downto 0);
    --signal fine_count : std_logic_vector(1 downto 0);
    -- signals for checking if output is valid 
    type t_state is (
        IDLE,   -- sampler is not saturated, waiting 
        READY,  --
        DONE
    );
    signal state : t_state;
    signal saturation_counter : unsigned(bitSize(g_sat_duration)-1 downto 0);
    signal hit_finished : std_logic;
    signal is_saturated : std_logic;
    -- Signals for output 
    --signal valid_s : std_logic;
    signal encoded_fine_time : std_logic_vector(4 downto 0);
    -- Signals for the fine period calculation
    signal true_fine_period : unsigned(1 downto 0);
    -- Signals for coarse time calculation
    signal true_coarse_period : std_logic_vector(g_coarse_bits-1 downto 0);
    signal coarse_s : std_logic_vector(g_coarse_bits-1 downto 0);
    signal g_channel_id_s : std_logic_vector(5 downto 0);   -- 6 bit channel ID
    attribute keep of g_channel_id_s : signal is "true";
    attribute dont_touch of g_channel_id_s : signal is "true";


begin

    -- Assign the channel ID signal the proper value based on the generic 
    g_channel_id_s <= std_logic_vector(to_unsigned(g_channel_id, 6));

    -- Shift the hit patterns from the previous clock cycle in
    p_shift : process(all)
    begin 
        if rising_edge(clk_0) then
            fine_last <= fine_i;
            coarse_s <= coarse_i;
            -- The fine period (0-3) in which the hit arrived is sent from the sampler as-is, with no need for any calculation. We therefore only need to wire the 2 LSBs from the sampler to the true_fine_period signal
            true_fine_period <= unsigned(fine_i(1 downto 0));
        end if;
    end process p_shift;
    
    -- FSM for determining hit validity based on input pulse duration
    p_is_valid : process(all)
    begin 
        if rising_edge(clk_0) then 
            if reset_i = '1' then 
                state <= IDLE;
                saturation_counter <= (others => '0');
                valid_o <= '0';
                timestamp_o <= (others => '0');
            else 
                case state is 
                    when IDLE =>
                        -- Reset timestamp & valid output to ensure that the output signal is one clk0 period long
                        timestamp_o <= (others => '0');
                        saturation_counter <= (others => '0');
                        valid_o <= '0';
                        if is_saturated = '1' then 
                            state <= READY;
                            saturation_counter <= saturation_counter + 1;
                        end if;
                    when READY =>
                        -- First check if the hit has been high long enough
                        if to_integer(saturation_counter) = g_sat_duration-1 then
                            state <= DONE;
                        else
                            -- Otherwise, check if the hit is still high. If not, return to idle state.
                            if is_saturated = '1' then 
                                saturation_counter <= saturation_counter + 1;
                            else
                                state <= IDLE;
                            end if;
                        end if;
                    when DONE => 
                        -- wait for hit pulse to go low before sending it out 
                        if hit_finished = '1' then 
                            valid_o <= '1';
                            timestamp_o <= true_coarse_period & encoded_fine_time & g_channel_id_s;--std_logic_vector(to_unsigned(g_channel_id, 6));
                            state <= IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process p_is_valid;

    -- Encode the fine arrival time of the hit within the coarse (RF) clock period. The fine time will be encoded by a 5-bit value representing one of the 32 0.58ns time intervals making up the RF clock period.
    p_encode : process(all)
    begin 
        if rising_edge(clk_0) then
            -- First check if the sampler output is saturated - this indicates a hit has fully been latched in
            if fine_i(9 downto 2) = "11111111" then
                hit_finished <= '0';
                is_saturated <= '1';
                -- Now we have to look at the previous hit state using the fine_last signal which has been delayed by one clk0 cycle.
                -- Because of the 2 clock0 cycle latency, if the true fine period is 01,10, or 11 (hit arrived after 1/4 of RF period), 
                -- then we need to decrement the coarse counter (RF bucket ID). Otherwise, use the current RF bucket ID. 
                if fine_last(9 downto 2) = "00000000" then   -- hit arrived b/w 135fe and 0re
                    case true_fine_period is 
                        when "00" =>    -- Range 0-7
                            encoded_fine_time <= std_logic_vector(to_unsigned(7, encoded_fine_time'length));
                            true_coarse_period <= coarse_s;
                        when "01" =>    -- Range 8-15 
                            encoded_fine_time <= std_logic_vector(to_unsigned(15, encoded_fine_time'length));
                            --true_coarse_period <= coarse_s;
                            true_coarse_period <= std_logic_vector(unsigned(coarse_s)-1);
                        when "10" =>    -- Range 16-23
                            encoded_fine_time <= std_logic_vector(to_unsigned(23, encoded_fine_time'length));
                            true_coarse_period <= std_logic_vector(unsigned(coarse_s)-1);
                        ----------------------------------------------------------------------------------------------------
                        -- EDGE CASE:
                        -- If the hit arrives exactly on the rising edge of the RF clock, then the hit will be attributed 
                        -- (incorrectly) to the previous RF bucket. If a hit were to arrive on the rising edge of the RF clock
                        -- then we would see:
                        --      fine_i[9:2]    = "11111111"
                        --      fine_last[9:2] = "00000000"
                        -- and a "true" fine period of 
                        --      true_fine_period = "11" 
                        -- Therefore, for this edge case only, we simply take the current coarse period as the proper RF bucket.
                        -- In this way, the hit is attributed to the correct RF bucket.
                        ----------------------------------------------------------------------------------------------------
                        when "11" =>    -- hit arrives in 1st interval of current RF bucket (00000)
                            encoded_fine_time <= std_logic_vector(to_unsigned(0, encoded_fine_time'length));
                            true_coarse_period <= coarse_s;
                        when others => 
                            null;
                    end case;
                elsif fine_last(9 downto 2) = "00000001" then   -- hit arrived b/w 90fe and 135fe
                    case true_fine_period is 
                        when "00" =>    -- Range 0-7
                            encoded_fine_time <= std_logic_vector(to_unsigned(6, encoded_fine_time'length));
                            true_coarse_period <= coarse_s;
                        when "01" =>    -- Range 8-15 
                            encoded_fine_time <= std_logic_vector(to_unsigned(14, encoded_fine_time'length));
                            --true_coarse_period <= coarse_s;
                            true_coarse_period <= std_logic_vector(unsigned(coarse_s)-1);
                        when "10" =>    -- Range 16-23
                            encoded_fine_time <= std_logic_vector(to_unsigned(22, encoded_fine_time'length));
                            true_coarse_period <= std_logic_vector(unsigned(coarse_s)-1);
                        when "11" =>    -- Range 24-31
                            encoded_fine_time <= std_logic_vector(to_unsigned(30, encoded_fine_time'length));
                            true_coarse_period <= std_logic_vector(unsigned(coarse_s)-1);
                        when others => 
                            null;
                    end case;
                elsif fine_last(9 downto 2) = "00000011" then   -- hit arrived b/w 45fe and 90fe
                    case true_fine_period is 
                        when "00" =>    -- Range 0-7
                            encoded_fine_time <= std_logic_vector(to_unsigned(5, encoded_fine_time'length));
                            true_coarse_period <= coarse_s;
                        when "01" =>    -- Range 8-15 
                            encoded_fine_time <= std_logic_vector(to_unsigned(13, encoded_fine_time'length));
                            --true_coarse_period <= coarse_s;
                            true_coarse_period <= std_logic_vector(unsigned(coarse_s)-1);
                        when "10" =>    -- Range 16-23
                            encoded_fine_time <= std_logic_vector(to_unsigned(21, encoded_fine_time'length));
                            true_coarse_period <= std_logic_vector(unsigned(coarse_s)-1);
                        when "11" =>    -- Range 24-31
                            encoded_fine_time <= std_logic_vector(to_unsigned(29, encoded_fine_time'length));
                            true_coarse_period <= std_logic_vector(unsigned(coarse_s)-1);
                        when others => 
                            null;
                    end case;
                elsif fine_last(9 downto 2) = "00000111" then   -- hit arrived b/w 0fe and 45fe
                    case true_fine_period is 
                        when "00" =>    -- Range 0-7
                            encoded_fine_time <= std_logic_vector(to_unsigned(4, encoded_fine_time'length));
                            true_coarse_period <= coarse_s;
                        when "01" =>    -- Range 8-15 
                            encoded_fine_time <= std_logic_vector(to_unsigned(12, encoded_fine_time'length));
                            --true_coarse_period <= coarse_s;
                            true_coarse_period <= std_logic_vector(unsigned(coarse_s)-1);
                        when "10" =>    -- Range 16-23
                            encoded_fine_time <= std_logic_vector(to_unsigned(20, encoded_fine_time'length));
                            true_coarse_period <= std_logic_vector(unsigned(coarse_s)-1);
                        when "11" =>    -- Range 24-31
                            encoded_fine_time <= std_logic_vector(to_unsigned(28, encoded_fine_time'length));
                            true_coarse_period <= std_logic_vector(unsigned(coarse_s)-1);
                        when others => 
                            null;
                    end case;
                elsif fine_last(9 downto 2) = "00001111" then   -- hit arrived b/w 135re and 0fe
                    case true_fine_period is 
                        when "00" =>    -- Range 0-7
                            encoded_fine_time <= std_logic_vector(to_unsigned(3, encoded_fine_time'length));
                            true_coarse_period <= coarse_s;
                        when "01" =>    -- Range 8-15 
                            encoded_fine_time <= std_logic_vector(to_unsigned(11, encoded_fine_time'length));
                            --true_coarse_period <= coarse_s;
                            true_coarse_period <= std_logic_vector(unsigned(coarse_s)-1);
                        when "10" =>    -- Range 16-23
                            encoded_fine_time <= std_logic_vector(to_unsigned(19, encoded_fine_time'length));
                            true_coarse_period <= std_logic_vector(unsigned(coarse_s)-1);
                        when "11" =>    -- Range 24-31
                            encoded_fine_time <= std_logic_vector(to_unsigned(27, encoded_fine_time'length));
                            true_coarse_period <= std_logic_vector(unsigned(coarse_s)-1);
                        when others => 
                            null;
                    end case;
                elsif fine_last(9 downto 2) = "00011111" then   -- hit arrived b/w 90re and 135re
                    case true_fine_period is 
                        when "00" =>    -- Range 0-7
                            encoded_fine_time <= std_logic_vector(to_unsigned(2, encoded_fine_time'length));
                            true_coarse_period <= coarse_s;
                        when "01" =>    -- Range 8-15 
                            encoded_fine_time <= std_logic_vector(to_unsigned(10, encoded_fine_time'length));
                            --true_coarse_period <= coarse_s;
                            true_coarse_period <= std_logic_vector(unsigned(coarse_s)-1);
                        when "10" =>    -- Range 16-23
                            encoded_fine_time <= std_logic_vector(to_unsigned(18, encoded_fine_time'length));
                            true_coarse_period <= std_logic_vector(unsigned(coarse_s)-1);
                        when "11" =>    -- Range 24-31
                            encoded_fine_time <= std_logic_vector(to_unsigned(26, encoded_fine_time'length));
                            true_coarse_period <= std_logic_vector(unsigned(coarse_s)-1);
                        when others => 
                            null;
                    end case;
                elsif fine_last(9 downto 2) = "00111111" then   -- hit arrived b/w 45re and 90re
                    case true_fine_period is 
                        when "00" =>    -- Range 0-7
                            encoded_fine_time <= std_logic_vector(to_unsigned(1, encoded_fine_time'length));
                            true_coarse_period <= coarse_s;
                        when "01" =>    -- Range 8-15 
                            encoded_fine_time <= std_logic_vector(to_unsigned(9, encoded_fine_time'length));
                            --true_coarse_period <= coarse_s;
                            true_coarse_period <= std_logic_vector(unsigned(coarse_s)-1);
                        when "10" =>    -- Range 16-23
                            encoded_fine_time <= std_logic_vector(to_unsigned(17, encoded_fine_time'length));
                            true_coarse_period <= std_logic_vector(unsigned(coarse_s)-1);
                        when "11" =>    -- Range 24-31
                            encoded_fine_time <= std_logic_vector(to_unsigned(25, encoded_fine_time'length));
                            true_coarse_period <= std_logic_vector(unsigned(coarse_s)-1);
                        when others => 
                            null;
                    end case;
                --elsif fine_last(9 downto 2) = "01111111" then   -- hit arrived b/w 0re and 45re
                else -- avoid latch being inferred
                    case true_fine_period is 
                        when "00" =>    -- Range 0-7
                            encoded_fine_time <= std_logic_vector(to_unsigned(0, encoded_fine_time'length));
                            true_coarse_period <= coarse_s;
                        when "01" =>    -- Range 8-15 
                            encoded_fine_time <= std_logic_vector(to_unsigned(8, encoded_fine_time'length));
                            --true_coarse_period <= coarse_s;
                            true_coarse_period <= std_logic_vector(unsigned(coarse_s)-1);
                        when "10" =>    -- Range 16-23
                            encoded_fine_time <= std_logic_vector(to_unsigned(16, encoded_fine_time'length));
                            true_coarse_period <= std_logic_vector(unsigned(coarse_s)-1);
                        when "11" =>    -- Range 24-31
                            encoded_fine_time <= std_logic_vector(to_unsigned(24, encoded_fine_time'length));
                            true_coarse_period <= std_logic_vector(unsigned(coarse_s)-1);
                        when others => 
                            null;
                    end case;
                end if; -- if fine_last[9:2] = "XXXXXXXX"              
            else
                is_saturated <= '0';
                if fine_last(9 downto 2) = "11111111" then -- the hit pulse has gone low
                    hit_finished <= '1';
                end if;  
            end if; -- if fine_i[9:2] = "11111111"
        end if; -- rising_edge(clk0)
    end process p_encode;

end Behavioral;

