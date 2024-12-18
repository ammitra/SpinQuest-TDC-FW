library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TDC_4ch_tb is
--  Port ( );
end TDC_4ch_tb;

architecture Behavioral of TDC_4ch_tb is

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
    -- Input signals 
    signal rst_s : std_logic := '1';
    signal en_s  : std_logic := '0';
    signal hit_s : std_logic_vector(0 to 3) := (others => '0');
    -- Output signals
    signal valid_s : std_logic;
    signal data_s  : std_logic_vector(38 downto 0);
    -- clock periods
    constant tdc_pd : time := 1 sec / 212.400E6;
    constant sys_pd : time := 1 sec / 53.100E6;
    -- other 
    signal locked_s : std_logic;

    component clk_wiz_0 is
        port (
            clk_in1  : in std_logic;
            reset    : in std_logic;
            clk_out1 : out std_logic;
            clk_out2 : out std_logic;
            clk_out3 : out std_logic;
            clk_out4 : out std_logic;
            locked   : out std_logic
        );
        end component;
    
begin

    clk_gen(clk_sys, 53.100E6, 0 ns);

    mmcm : clk_wiz_0
    port map (
        clk_in1  => clk_sys,
        clk_out1 => clk_0,
        clk_out2 => clk_1,
        clk_out3 => clk_2,
        clk_out4 => clk_3,
        reset    => rst_s,
        locked   => locked_s
    );

    uut_tdc4ch : entity work.TDC_4ch
    generic map (
        g_chID_start   => 0,
        g_coarse_bits  => 28,
        g_sat_duration => 3,
        g_pipe_depth   => 4
    )
    port map (
        clk0    => clk_0,
        clk45   => clk_1,
        clk90   => clk_2,
        clk135  => clk_3,
        clk_sys => clk_sys,
        reset   => rst_s,
        enable  => en_s,
        hit     => hit_s,
        valid_o => valid_s,
        data_o  => data_s
    );

    p_sim : process
    begin
        wait for 100 ns;
        en_s <= '1';
        rst_s <= '0';
        wait for 2000 ns;

        -- Send out hits on each channel sequentially
        hit_s(0) <= '1';
        wait for 3.5 * tdc_pd;
        hit_s(0) <= '0';
        hit_s(1) <= '1';
        wait for 3.5 * tdc_pd;
        hit_s(1) <= '0';
        hit_s(2) <= '1';
        wait for 3.5 * tdc_pd;
        hit_s(2) <= '0';
        hit_s(3) <= '1';
        wait for 3.5 * tdc_pd;
        hit_s(3) <= '0';
        
        -- Send hits on all channels simultaneously
        wait for 18.3 * tdc_pd;
        hit_s <= (others => '1');
        wait for 3.5 * tdc_pd;
        hit_s <= (others => '0');
        
        -- two channels
        wait for 18.3 * tdc_pd;
        hit_s(1) <= '1';
        hit_s(3) <= '1';
        wait for 8 * tdc_pd;
        hit_s(1) <= '0';
        hit_s(3) <= '0';
        
        -- ultra short pulse (less than g_sat_duration * tdc_pd)
        wait for 15.6 * tdc_pd;
        hit_s(2) <= '1';
        wait for 1.5 * tdc_pd;
        hit_s(2) <= '0';
        
        -- now exactly g_sat_duration * tdc_pd
        wait for 12.7 * tdc_pd;
        hit_s(0) <= '1';
        wait for 3 * tdc_pd;
        hit_s(0) <= '0';
        
        
        
        
        wait;
    end process p_sim;

end Behavioral;
