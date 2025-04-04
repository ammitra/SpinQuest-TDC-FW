---------------------------------------------------------------------------------------------------------
--! \file CoarseCounter.vhd
--! \brief Module that produces a counter running at a given frequency.
--!
--! \details User-configurable counter synced to RF clock. Optional (unused) heartbeat pulse
--! can be sent at the end of `2^(g_coarse_bits)\f` RF clock cycles, indicating end of 
--! counter. This module is used to generate the coarse time, aligned with a given RF bucket.
--! The generic `g_coarse_bits` sets the length of the counter and thus the dynamic time range.
--! The default value of `g_coarse_bits = 28`, running at 53.1 MHz, yields a dynamic range of ~5s, 
--! which covers the duration of a typical spill.
--!
--! \author Amitav Mitra, amitra3@jhu.edu
--! /** \anchor CoarseCounter.vhd */
---------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--! \brief Module that produces a counter running at a given frequency.
--!
--! \details User-configurable counter synced to RF clock. Optional (unused) heartbeat pulse
--! can be sent at the end of `2^(g_coarse_bits)\f` RF clock cycles, indicating end of 
--! counter. This module is used to generate the coarse time, aligned with a given RF bucket.
--! The generic `g_coarse_bits` sets the length of the counter and thus the dynamic time range.
--! The default value of `g_coarse_bits = 28`, running at 53.1 MHz, yields a dynamic range of ~5s, 
--! which covers the duration of a typical spill.
entity CoarseCounter is
    generic (
        g_coarse_bits : natural := 28   --! Number of bits in the counter 
    );
    port (
        clk_RF      : in std_logic;     --! 53.1 MHz RF clock 
        reset_i     : in std_logic;     --! Active high reset
        heartbeat_o : out std_logic;    --! Signifies the end of the counter (unused)
        coarse_o    : out std_logic_vector(g_coarse_bits-1 downto 0)    --! Counter value output
    );
end CoarseCounter;

architecture Behavioral of CoarseCounter is
    signal coarse_count : std_logic_vector(g_coarse_bits-1 downto 0) := (others => '0');
begin
    process(all)
    begin 
        if reset_i = '1' then 
            coarse_count <= (others => '0');
            heartbeat_o <= '0';
        elsif rising_edge(clk_RF) then
            coarse_count <= std_logic_vector(unsigned(coarse_count) + 1);
            if unsigned(coarse_count) = (2**g_coarse_bits)-1 then 
                heartbeat_o <= '1';
            else
                heartbeat_o <= '0';
            end if;
        end if; 
    end process;
    
    coarse_o <= std_logic_vector(coarse_count);

end Behavioral;

