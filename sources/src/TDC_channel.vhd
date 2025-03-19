----------------------------------------------------------------------------------
--  Single TDC channel
--
--  In this design, every channel has its own coarse counter to avoid high fanout.
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TDC_channel is
    generic (
        g_channel_id : natural := 0;
        g_sat_duration : natural := 3;
        g_coarse_bits : natural := 28
    );
    port (
        -- TDC and system clocks 
        clk0 : in std_logic;    -- 0 degree (212.4 MHz)
        clk45 : in std_logic;    -- 45 degree
        clk90 : in std_logic;    -- 90 degree
        clk135 : in std_logic;    -- 135 degree
        clk_sys : in std_logic;  -- 53.1 MHz
        -- Control 
        reset  : in std_logic;
        enable : in std_logic;
        -- Data input
        --coarse_i : in std_logic_vector(g_coarse_bits-1 downto 0);
        hit : in std_logic;
        -- Data output (timestamp + valid)
        valid      : out std_logic;
        timestamp  : out std_logic_vector(g_coarse_bits+10 downto 0)
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

