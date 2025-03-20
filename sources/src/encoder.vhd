---------------------------------------------------------------------------------------------------------
--! \file encoder.vhd
--! \brief Module that encodes the arrival time of valid hits with respect to the RF (coarse) clock.
--! 
--! \details The encoder module acts to encode the arrival time of valid hits from the detector front-end into 
--! N+11 bit-long data words, where `N = g_coarse_bits` == the length of the \ref CoarseCounter.vhd "coarse time counter".
--! The additional factor of 11 comes from the 11-bit concatenation of (5-bit fine time) & (6-bit channel ID).
--! The fine time is encoded by a 5-bit value representing one of the 32 0.58ns time intervals making up the RF clock period.
--! 
--! \author Amitav Mitra, amitra3@jhu.edu
---------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--! Use bitSize() function
use work.common_types.all;

--! \brief Module that encodes the arrival time of valid hits with respect to the RF (coarse) clock.
--! 
--! \details The encoder module acts to encode the arrival time of valid hits from the detector front-end into 
--! N+11 bit-long data words, where `N = g_coarse_bits` == the length of the \ref CoarseCounter.vhd "coarse time counter".
--! The additional factor of 11 comes from the 11-bit concatenation of (5-bit fine time) & (6-bit channel ID).
--! The fine time is encoded by a 5-bit value representing one of the 32 0.58ns time intervals making up the RF clock period.
entity encoder is
    generic (
        g_coarse_bits : natural := 28;  --! Number of bits making up the \ref CoarseCounter.vhd "coarse time counter".
        g_channel_id  : natural := 0;   --! Channel ID (number from 0-63).
        g_sat_duration : natural range 1 to 5 := 3   --! number of clk_0 cycles the signal needs to remain high to be considered valid
    );
    port (
        clk_0       : in std_logic;                                     --! 0-degree phase MMCM output clock
        fine_i      : in std_logic_vector(9 downto 0);                  --! Bits [9:2] are the \ref sampler.vhd "sampler" hit pattern and bits [1:0] are the clk_0 period counter
        reset_i     : in std_logic;                                     --! Active high reset
        coarse_i    : in std_logic_vector(g_coarse_bits-1 downto 0);    --! \ref CoarseCounter.vhd "Coarse time counter" value
        timestamp_o : out std_logic_vector(g_coarse_bits+10 downto 0);  --! Timestamp formed by (coarse time) + [ (5-bit fine time) + (6-bit channel id) ] - 1
        valid_o     : out std_logic                                     --! Output pulse sent when valid fine time is encoded
    );
end encoder;

architecture Behavioral of encoder is

    -- Preserve architecture
    attribute keep_hierarchy : string;  --! <a href="https://docs.amd.com/r/en-US/ug912-vivado-properties/KEEP_HIERARCHY">KEEP_HIERARCHY</a>
    attribute keep : string;            --! <a href="https://docs.amd.com/r/en-US/ug912-vivado-properties/KEEP">KEEP</a>
    attribute dont_touch : string;      --! <a href="https://docs.amd.com/r/en-US/ug912-vivado-properties/DONT_TOUCH">DONT_TOUCH</a>
    attribute keep_hierarchy of Behavioral : architecture is "true"; --! Prevent optimization from occurring across boundary of this hierarchy.

    signal fine_last  : std_logic_vector(9 downto 0);   --! Signal to register the previous input from the \ref sampler.vhd "sampler" module.

    --! State governing the status of the encoder while waiting for the sampler to fully saturate
    type t_state is (
        IDLE,   -- Sampler is not saturated, waiting for a hit to arrive
        READY,  -- Sampler has been saturated for `g_sat_duration` `clk_0` periods
        DONE    -- Sampler has been saturated for long enough, wait for hit pulse to go low before sending the encoded data for further processing
    );
    signal state : t_state;

    --! Keeps track of how many clk_0 periods the hit has been high for (saturates the sampler)
    signal saturation_counter : unsigned(bitSize(g_sat_duration)-1 downto 0);
    signal hit_finished : std_logic;    --! Hit signal has gone low:                        fine_i[9:2] => '0'
    signal is_saturated : std_logic;    --! Hit signal is high and sampler is saturated:    fine_i[9:2] => '1'

    --! 5-bit encoded fine time representing which of the 32 time divisions in an RF clock period the hit arrived during.
    signal encoded_fine_time : std_logic_vector(4 downto 0); 

    --! The fine period (0-3) in which the hit arrived that is sent directly from the sampler
    signal true_fine_period : unsigned(1 downto 0);

    --! The actual coarse period the hit arrived during. Prevents hits arriving near the end of an RF clock period from being attributed to the wrong RF bucket
    signal true_coarse_period : std_logic_vector(g_coarse_bits-1 downto 0);
    --! Register the incoming coarse time from the coarse counter.
    signal coarse_s : std_logic_vector(g_coarse_bits-1 downto 0);

    -- I don't think this is actually necessary. Feel free to remove and just uncomment the line in process p_is_valid()
    signal g_channel_id_s : std_logic_vector(5 downto 0);       --! 6 bit channel ID as an STD_LOGIC_VECTOR
    attribute keep of g_channel_id_s : signal is "true";        --! Prevent the signal from being optimized away during synthesis.
    attribute dont_touch of g_channel_id_s : signal is "true";  --! Prevent the signal from being optimized away during synthesis.


begin

    -- Assign the channel ID signal the proper value based on the generic 
    g_channel_id_s <= std_logic_vector(to_unsigned(g_channel_id, 6));

    --! \brief Register the coarse time counter, fine time hit pattern, and clk_0 period counter signals.
    p_shift : process(all)
    begin 
        if rising_edge(clk_0) then
            fine_last <= fine_i;
            coarse_s <= coarse_i;
            -- The fine period (0-3) in which the hit arrived is sent from the sampler as-is, with no need for any calculation. We therefore only need to wire the 2 LSBs from the sampler to the true_fine_period signal
            true_fine_period <= unsigned(fine_i(1 downto 0));
        end if;
    end process p_shift;
    
    --! \brief FSM for determining hit validity based on input pulse duration.
    --! \details The FSM has three different states: IDLE, READY, and DONE. 
    --! These states correspond to the status of the sampler, which is recording the hit pattern from the front-end electronics. 
    --! <br> * IDLE: Sampler is not saturated, waiting for a hit to arrive
    --! <br> * READY: Sampler has been saturated for `g_sat_duration` `clk_0` periods
    --! <br> * DONE: Sampler has been saturated for long enough, wait for hit pulse to go low before sending the encoded data for further processing
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

    --! \brief Encode the fine arrival time of the hit within the coarse (RF) clock period. 
    --! \details The fine time will be encoded by a 5-bit value representing one of the 32 0.58ns time intervals making up the RF clock period.
    --! To implement this, we use a lookup table that checks the hit pattern from the sampler (`fine_i[9:2]`) at the current and previous clk_0 
    --! cycle, the clk_0 period during which the hit arrived (`true_fine_period`), and the coarse (RF) clock period during which the hit arrived.
    --! Some logic is performed to ensure that hits arriving near the end of the RF clock period are not mistakenly attributed to the next RF bucket.
    --! There is also treatment of the edge case where the hit arrives exactly on the rising edge of the RF clock, which would otherwise lead to the 
    --! hit being erroneously attributed to the previous RF bucket.
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

