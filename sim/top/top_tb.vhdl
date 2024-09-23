library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sampler_tb is
--  Port ( );
end sampler_tb;

architecture Behavioral of sampler_tb is

  -- Procedure for clock generation
  procedure clk_gen(signal clk : out std_logic; constant FREQ : real; PHASE : time := 1 ns) is
    constant PERIOD    : time := 1 sec / FREQ;        -- Full period
    constant HIGH_TIME : time := PERIOD / 2;          -- High time
    constant LOW_TIME  : time := PERIOD - HIGH_TIME;  -- Low time; always >= HIGH_TIME
  begin
    -- Check the arguments
    assert (HIGH_TIME /= 0 fs) report "clk_plain: High time is zero; time resolution to large for frequency" severity FAILURE;
    -- initial phase shift 
    wait for PHASE;
    -- Generate a clock cycle
    loop
      clk <= '1';
      wait for HIGH_TIME;
      clk <= '0';
      wait for LOW_TIME;
    end loop;
  end procedure;

  -- Clock frequency and signal
  signal clk_0 : std_logic;
  signal clk_1 : std_logic;
  signal clk_2 : std_logic;
  signal clk_3 : std_logic;
  signal clk_sys : std_logic;
  -- test signals
  signal hit_s : std_logic := '0';
  signal ena_s : std_logic := '0';
  signal rst_s : std_logic := '1';
  signal locked_s : std_logic;
  signal timestamp_s : std_logic_vector(38 downto 0);
  signal valid_s : std_logic;
  signal coarse_s : std_logic_vector(27 downto 0);
  signal heartbeat_s : std_logic;
  -- clock periods
  constant tdc_pd : time := 1 sec / 212.400E6;
  constant sys_pd : time := 1 sec / 53.100E6;
  -- data out
  signal data_s : std_logic_vector(9 downto 0) := (others => '0');
  
    component clk_wiz_0 is
    port (    
        clk_RF      : in std_logic;
        reset       : in std_logic;
        clk_out0    : out std_logic;
        clk_out45   : out std_logic;
        clk_out90   : out std_logic;
        clk_out135  : out std_logic;
        locked      : out std_logic
    );
    end component;

begin

  --clk_gen(clk_0, 212.400E6, 0 ns);
  --clk_gen(clk_1, 212.400E6, 0.125 * tdc_pd);
  --clk_gen(clk_2, 212.400E6, 0.25 * tdc_pd);
  --clk_gen(clk_3, 212.400E6, 0.375 * tdc_pd);
  clk_gen(clk_sys, 53.100E6, 0 ns);
  
    mmcm : clk_wiz_0
    port map (
        clk_RF => clk_sys,
        clk_out0 => clk_0,
        clk_out45 => clk_1,
        clk_out90 => clk_2,
        clk_out135 => clk_3,
        reset => rst_s,
        locked => locked_s
    );
  
  uut_sampler : entity work.sampler
    port map (
        -- TDC and system clocks 
        clk0 => clk_0,
        clk1 => clk_1,
        clk2 => clk_2,
        clk3 => clk_3,
        clk_RF => clk_sys,
        -- Control 
        reset_i  => rst_s,
        enable_i => ena_s,
        -- Data input
        hit_i => hit_s,
        -- Data output (to encoder)
        data_o  => data_s
    );
  
  uut_encoder : entity work.encoder
    generic map ( g_coarse_bits => 28, g_channel_id => 0)
    port map (
        clk_0       => clk_0,
        fine_i      => data_s,
        reset_i     => rst_s,
        coarse_i    => coarse_s,
        timestamp_o => timestamp_s
        --valid_o     => valid_s
    );
    
    uut_coarse : entity work.CoarseCounter
    generic map ( g_coarse_Bits => 28)
    port map(
        clk_RF      => clk_sys,
        reset_i     => rst_s,
        heartbeat_o => heartbeat_s,
        coarse_o    => coarse_s
    );
  p_sim : process
  begin
    wait for 100 ns;
    ena_s <= '1';
    rst_s <= '0';
    wait for 2000 ns;
    hit_s <= '1';
    wait for 30 ns;
    hit_s <= '0';
    wait for 58.2 ns;
    hit_s <= '1';
    wait for 30 ns;
    hit_s <= '0';
    wait for 74.3 ns;
    hit_s <= '1';
    wait for 30 ns;
    hit_s <= '0';
    

    wait;
  end process;

end Behavioral;

