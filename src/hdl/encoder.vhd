-----------------------------------------------------------------------------------
-- encoder.vhd
--
-- Encodes the arrival time of valid hits into a N+11-bit data word
--  * N = g_coarse_bits == length of coarse counter (RF bucket ID)
--  * 11 = (5-bit fine time) + (6-bit channelID)
--
-- V0: 23/09/2024
--  * first version, passed behavioral simulation tests
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity encoder is
    generic (
        g_coarse_bits : natural := 28;
        g_channel_id  : natural := 0
    );
    port (
        clk_0       : in std_logic; -- 4x RF clock 0degree phase
        fine_i      : in std_logic_vector(9 downto 0);  -- [9:2] are hit pattern [1:0] are fine counter
        reset_i     : in std_logic;
        coarse_i    : in std_logic_vector(g_coarse_bits-1 downto 0);
        timestamp_o : out std_logic_vector(g_coarse_bits+10 downto 0)   -- (coarse) + (5-bit fine) + (6-bit channel id) - 1
        --valid_o     : out std_logic
    );
end encoder;

architecture Behavioral of encoder is

    -- Signals for the current and previous input from sampler module
    signal fine_last  : std_logic_vector(9 downto 0);
    signal fine_count : std_logic_vector(1 downto 0);
    -- Signals for output 
    --signal valid_s : std_logic;
    signal encoded_fine_time : std_logic_vector(4 downto 0);
    -- Signals for the fine period calculation
    signal true_fine_period : unsigned(1 downto 0);
    -- Signals for coarse time calculation
    signal true_coarse_period : std_logic_vector(g_coarse_bits-1 downto 0);

begin

    -- Shift the hit pattern from the previous clock cycle in
    p_shift : process(clk_0)
    begin 
        if rising_edge(clk_0) then
            fine_last <= fine_i;
        end if;
    end process p_shift;
    
    p_fine_period_id : process(fine_i)
    begin 
        -- Look at the 2 LSBs from the LAST VALUE of the sampler - this is the fine time counter. Since the counter is incremented on the 
        -- rising edge of the fast clock, it will always be one value higher than when the hit arrived. Simple MUX to 
        -- determine the real time can then be implemented. The result will be an offset of 2 from the current clk0 fine counter
        case fine_last(1 downto 0) is
            when "00" =>    -- hit arrived during previous RF bucket
                true_fine_period <= "11";
            when "01" =>
                true_fine_period <= "00";
            when "10" =>
                true_fine_period <= "01";
            when "11" =>
                true_fine_period <= "10";
            when others =>
                null;
        end case;
    end process p_fine_period_id;
    
    p_encode : process(clk_0, reset_i, true_fine_period)
    begin 
        if rising_edge(clk_0) then
            if reset_i = '1' then 
                --encoded_fine_time <= (others => '0');
                null;
            else
                -- First check if the sampler output is saturated - this indicates a hit has fully been latched in
                if fine_i(9 downto 2) = "11111111" then
                    -- Now we have to look at the previous hit state using the fine_last signal which has been delayed by one clk0 cycle.
                    -- Because of the 2 clock0 cycle latency, if the true fine period is 10 or 11 (hit arrived in second half of RF bucket), 
                    -- then we need to decrement the coarse counter (RF bucket ID). Otherwise, use the current RF bucket ID. 
                    if fine_last(9 downto 2) = "00000000" then   -- hit arrived b/w 135fe and 0re
                        case true_fine_period is 
                            when "00" =>    -- Range 0-7
                                encoded_fine_time <= std_logic_vector(to_unsigned(7, encoded_fine_time'length));
                                true_coarse_period <= coarse_i;
                            when "01" =>    -- Range 8-15 
                                encoded_fine_time <= std_logic_vector(to_unsigned(15, encoded_fine_time'length));
                                true_coarse_period <= coarse_i;
                            when "10" =>    -- Range 16-23
                                encoded_fine_time <= std_logic_vector(to_unsigned(23, encoded_fine_time'length));
                                true_coarse_period <= std_logic_vector(unsigned(coarse_i)-1);
                            when "11" =>    -- Range 24-31
                                encoded_fine_time <= std_logic_vector(to_unsigned(31, encoded_fine_time'length));
                                true_coarse_period <= std_logic_vector(unsigned(coarse_i)-1);
                            when others => 
                                null;
                        end case;
                    elsif fine_last(9 downto 2) = "00000001" then   -- hit arrived b/w 90fe and 135fe
                        case true_fine_period is 
                            when "00" =>    -- Range 0-7
                                encoded_fine_time <= std_logic_vector(to_unsigned(6, encoded_fine_time'length));
                                true_coarse_period <= coarse_i;
                            when "01" =>    -- Range 8-15 
                                encoded_fine_time <= std_logic_vector(to_unsigned(14, encoded_fine_time'length));
                                true_coarse_period <= coarse_i;
                            when "10" =>    -- Range 16-23
                                encoded_fine_time <= std_logic_vector(to_unsigned(22, encoded_fine_time'length));
                                true_coarse_period <= std_logic_vector(unsigned(coarse_i)-1);
                            when "11" =>    -- Range 24-31
                                encoded_fine_time <= std_logic_vector(to_unsigned(30, encoded_fine_time'length));
                                true_coarse_period <= std_logic_vector(unsigned(coarse_i)-1);
                            when others => 
                                null;
                        end case;
                    elsif fine_last(9 downto 2) = "00000011" then   -- hit arrived b/w 45fe and 90fe
                        case true_fine_period is 
                            when "00" =>    -- Range 0-7
                                encoded_fine_time <= std_logic_vector(to_unsigned(5, encoded_fine_time'length));
                                true_coarse_period <= coarse_i;
                            when "01" =>    -- Range 8-15 
                                encoded_fine_time <= std_logic_vector(to_unsigned(13, encoded_fine_time'length));
                                true_coarse_period <= coarse_i;
                            when "10" =>    -- Range 16-23
                                encoded_fine_time <= std_logic_vector(to_unsigned(21, encoded_fine_time'length));
                                true_coarse_period <= std_logic_vector(unsigned(coarse_i)-1);
                            when "11" =>    -- Range 24-31
                                encoded_fine_time <= std_logic_vector(to_unsigned(29, encoded_fine_time'length));
                                true_coarse_period <= std_logic_vector(unsigned(coarse_i)-1);
                            when others => 
                                null;
                        end case;
                    elsif fine_last(9 downto 2) = "00000111" then   -- hit arrived b/w 0fe and 45fe
                        case true_fine_period is 
                            when "00" =>    -- Range 0-7
                                encoded_fine_time <= std_logic_vector(to_unsigned(4, encoded_fine_time'length));
                                true_coarse_period <= coarse_i;
                            when "01" =>    -- Range 8-15 
                                encoded_fine_time <= std_logic_vector(to_unsigned(12, encoded_fine_time'length));
                                true_coarse_period <= coarse_i;
                            when "10" =>    -- Range 16-23
                                encoded_fine_time <= std_logic_vector(to_unsigned(20, encoded_fine_time'length));
                                true_coarse_period <= std_logic_vector(unsigned(coarse_i)-1);
                            when "11" =>    -- Range 24-31
                                encoded_fine_time <= std_logic_vector(to_unsigned(28, encoded_fine_time'length));
                                true_coarse_period <= std_logic_vector(unsigned(coarse_i)-1);
                            when others => 
                                null;
                        end case;
                    elsif fine_last(9 downto 2) = "00001111" then   -- hit arrived b/w 135re and 0fe
                        case true_fine_period is 
                            when "00" =>    -- Range 0-7
                                encoded_fine_time <= std_logic_vector(to_unsigned(3, encoded_fine_time'length));
                                true_coarse_period <= coarse_i;
                            when "01" =>    -- Range 8-15 
                                encoded_fine_time <= std_logic_vector(to_unsigned(11, encoded_fine_time'length));
                                true_coarse_period <= coarse_i;
                            when "10" =>    -- Range 16-23
                                encoded_fine_time <= std_logic_vector(to_unsigned(19, encoded_fine_time'length));
                                true_coarse_period <= std_logic_vector(unsigned(coarse_i)-1);
                            when "11" =>    -- Range 24-31
                                encoded_fine_time <= std_logic_vector(to_unsigned(27, encoded_fine_time'length));
                                true_coarse_period <= std_logic_vector(unsigned(coarse_i)-1);
                            when others => 
                                null;
                        end case;
                    elsif fine_last(9 downto 2) = "00011111" then   -- hit arrived b/w 90re and 135re
                        case true_fine_period is 
                            when "00" =>    -- Range 0-7
                                encoded_fine_time <= std_logic_vector(to_unsigned(2, encoded_fine_time'length));
                                true_coarse_period <= coarse_i;
                            when "01" =>    -- Range 8-15 
                                encoded_fine_time <= std_logic_vector(to_unsigned(10, encoded_fine_time'length));
                                true_coarse_period <= coarse_i;
                            when "10" =>    -- Range 16-23
                                encoded_fine_time <= std_logic_vector(to_unsigned(18, encoded_fine_time'length));
                                true_coarse_period <= std_logic_vector(unsigned(coarse_i)-1);
                            when "11" =>    -- Range 24-31
                                encoded_fine_time <= std_logic_vector(to_unsigned(26, encoded_fine_time'length));
                                true_coarse_period <= std_logic_vector(unsigned(coarse_i)-1);
                            when others => 
                                null;
                        end case;
                    elsif fine_last(9 downto 2) = "00111111" then   -- hit arrived b/w 45re and 90re
                        case true_fine_period is 
                            when "00" =>    -- Range 0-7
                                encoded_fine_time <= std_logic_vector(to_unsigned(1, encoded_fine_time'length));
                                true_coarse_period <= coarse_i;
                            when "01" =>    -- Range 8-15 
                                encoded_fine_time <= std_logic_vector(to_unsigned(9, encoded_fine_time'length));
                                true_coarse_period <= coarse_i;
                            when "10" =>    -- Range 16-23
                                encoded_fine_time <= std_logic_vector(to_unsigned(17, encoded_fine_time'length));
                                true_coarse_period <= std_logic_vector(unsigned(coarse_i)-1);
                            when "11" =>    -- Range 24-31
                                encoded_fine_time <= std_logic_vector(to_unsigned(25, encoded_fine_time'length));
                                true_coarse_period <= std_logic_vector(unsigned(coarse_i)-1);
                            when others => 
                                null;
                        end case;
                    elsif fine_last(9 downto 2) = "01111111" then   -- hit arrived b/w 0re and 45re
                        case true_fine_period is 
                            when "00" =>    -- Range 0-7
                                encoded_fine_time <= std_logic_vector(to_unsigned(0, encoded_fine_time'length));
                                true_coarse_period <= coarse_i;
                            when "01" =>    -- Range 8-15 
                                encoded_fine_time <= std_logic_vector(to_unsigned(8, encoded_fine_time'length));
                                true_coarse_period <= coarse_i;
                            when "10" =>    -- Range 16-23
                                encoded_fine_time <= std_logic_vector(to_unsigned(16, encoded_fine_time'length));
                                true_coarse_period <= std_logic_vector(unsigned(coarse_i)-1);
                            when "11" =>    -- Range 24-31
                                encoded_fine_time <= std_logic_vector(to_unsigned(24, encoded_fine_time'length));
                                true_coarse_period <= std_logic_vector(unsigned(coarse_i)-1);
                            when others => 
                                null;
                        end case;
                    end if; -- if fine_last[9:2] = "XXXXXXXX"
                end if; -- if fine_i[9:2] = "11111111"
            end if; -- if reset_i, else
        end if; -- rising_edge(clk0)
    end process p_encode;
    
    
    timestamp_o <= true_coarse_period & encoded_fine_time & std_logic_vector(to_unsigned(g_channel_id, 6));
    
end Behavioral;

