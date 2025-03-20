---------------------------------------------------------------------------------------------------------
--! \file TDC_channel.vhd
--! \brief A round-robin 4:1 arbiter that sends 4 parallel data streams to one serial output stream.
--!
--! \details A single TDC channel made up of a hit sampler and encoder. Specifically, this design assigns 
--! a \ref CoarseCounter.vhd "`CoarseCounter`" module to every channel to reduce fanout on the coarse 
--! counter signal.
--! 
--! \author Amitav Mitra, amitra3@jhu.edu
---------------------------------------------------------------------------------------------------------



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--! \brief A round-robin 4:1 arbiter that sends 4 parallel data streams to one serial output stream.
--! \details A single TDC channel made up of a hit sampler and encoder.
entity TDC_channel is
    generic (
        g_channel_id : natural := 0;    --! Channel ID
        g_sat_duration : natural := 3;  --! Minumum number of `clk0` periods the hit must remain high to be considered valid and digitized
        g_coarse_bits : natural := 28   --! The number of bits in the \ref CoarseCounter.vhd "coarse time counter".
    );
    port (
        -- TDC and system clocks 
        clk0 : in std_logic;    --! 0 degree (212.4 MHz, 4x RF) clock
        clk45 : in std_logic;   --! 45 degree clock
        clk90 : in std_logic;   --! 90 degree clock
        clk135 : in std_logic;  --! 135 degree clock
        clk_sys : in std_logic; --! RF clock (53.1 MHz)
        -- Control 
        reset  : in std_logic;  --! Active high reset
        enable : in std_logic;  --! Active high enable
        -- Data input
        --coarse_i : in std_logic_vector(g_coarse_bits-1 downto 0);
        hit : in std_logic;     --! Front-end discriminator hit
        -- Data output (timestamp + valid)
        valid      : out std_logic;                                     --! Data valid flag from \ref encoder.vhd "encoder"
        timestamp  : out std_logic_vector(g_coarse_bits+10 downto 0)    --! 
    );
end TDC_channel;

architecture Behavioral of TDC_channel is

    -- Preserve architecture
    attribute keep_hierarchy : string;
    attribute keep_hierarchy of Behavioral : architecture is "true";

    ---------------------------------------------------------------
    -- SIGNALS
    ---------------------------------------------------------------
    signal sampler_o_s : std_logic_vector(9 downto 0);  -- output from sampler
    signal heartbeat_s : std_logic; -- heartbeat signal from coarse counter (unused)
    signal coarse_s    : std_logic_vector(g_coarse_bits-1 downto 0); -- output from coarse counter
    
begin

    e_sampler : entity work.sampler
    port map (
        -- TDC and system clocks 
        clk0 => clk0,
        clk1 => clk45,
        clk2 => clk90,
        clk3 => clk135,
        clk_RF => clk_sys,
        -- Control 
        reset_i  => reset,
        enable_i => enable,
        -- Data input
        hit_i => hit,
        -- Data output (to encoder)
        data_o => sampler_o_s
    );
    
   e_CoarseCounter : entity work.CoarseCounter
   generic map (
       g_coarse_bits => g_coarse_bits
   )
   port map (
       clk_RF      => clk_sys,
       reset_i     => reset,
       heartbeat_o => heartbeat_s,
       coarse_o    => coarse_s
   );
    
    e_encoder : entity work.encoder
    generic map (
        g_coarse_bits  => g_coarse_bits,
        g_sat_duration => g_sat_duration,
        g_channel_id   => g_channel_id
    )
    port map (
        clk_0       => clk0,
        fine_i      => sampler_o_s,
        reset_i     => reset,
        coarse_i    => coarse_s,
        timestamp_o => timestamp,
        valid_o     => valid
    );

end Behavioral;

