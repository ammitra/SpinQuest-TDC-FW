library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity test_2BRAM is
--  Port ( );
end test_2BRAM;

architecture Behavioral of test_2BRAM is

    -- clock generation
    procedure clk_gen(signal clk : out std_logic; constant FREQ : real; PHASE : time := 1 ns) is
        constant PERIOD    : time := 1 sec / FREQ;        -- Full period
        constant HIGH_TIME : time := PERIOD / 2;          -- High time
        constant LOW_TIME  : time := PERIOD - HIGH_TIME;  -- Low time; always >= HIGH_TIME
    begin
        report "clk started";
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
    
    
        -- clocking
        signal clk_sys : std_logic;
        signal clk0    : std_logic;
        signal clk45   : std_logic;
        signal clk90   : std_logic;
        signal clk135  : std_logic;
        -- control
        signal reset  : std_logic := '1';
        signal locked : std_logic;
        -- UUT
        signal hits : std_logic_vector(0 to 63) := (others => '0');
        signal trig : std_logic := '0';
        signal busy : std_logic := '0';
        signal irq  : std_logic;
        signal which_bram : std_logic_vector(1 downto 0);
        signal BRAM_1_addr_b   : std_logic_vector(31 downto 0);
        signal BRAM_1_clk_b    : std_logic;
        signal BRAM_1_rddata_b : std_logic_vector(63 downto 0);
        signal BRAM_1_wrdata_b : std_logic_vector(63 downto 0);
        signal BRAM_1_en_b     : std_logic;
        signal BRAM_1_rst_b    : std_logic;
        signal BRAM_1_we_b     : std_logic_vector(7 downto 0);
        signal BRAM_2_addr_b   : std_logic_vector(31 downto 0);
        signal BRAM_2_clk_b    : std_logic;
        signal BRAM_2_rddata_b : std_logic_vector(63 downto 0);
        signal BRAM_2_wrdata_b : std_logic_vector(63 downto 0);
        signal BRAM_2_en_b     : std_logic;
        signal BRAM_2_rst_b    : std_logic;
        signal BRAM_2_we_b     : std_logic_vector(7 downto 0);
    
        -- clock periods
        constant tdc_pd : time := 1 sec / 212.400E6;
        constant sys_pd : time := 1 sec / 53.100E6;
    
    

begin

    clk_gen(clk_sys, 53.100E6, 0 ns);
    
    mmcm : clk_wiz_0
    port map (
        reset    => reset, 
        locked   => locked,
        clk_in1  => clk_sys,
        clk_out1 => clk0,
        clk_out2 => clk45,
        clk_out3 => clk90,
        clk_out4 => clk135
    );
    
    uut : entity work.TDC_64ch
    generic map (
        g_chID_start   => 0,      -- Channel ID of the lowest channel in the group of 16
        g_coarse_bits  => 28,     -- Number of coarse bits to use 
        g_sat_duration => 3,      -- Number of 0deg clock cycles signal must be high to be valid
        g_pipe_depth   => 5       -- Number of hits stored in the intermediate buffers
    )
    port map (
        -- TDC and system clocks sent to all 4 channels
        clk0    => clk0,
        clk45   => clk45,
        clk90   => clk90,
        clk135  => clk135,
        clk_sys => clk_sys,
        -- Control 
        reset   => reset,   -- active high
        enable  => locked,  -- active high, only enable when MMCM locks
        -- Data input from detector
        hits     => hits,
        trigger => trig,
        -- PL <--> PS communication 
        rd_busy    => busy,       -- PS -> PL indicating read in progress
        irq_o      => irq,        -- PL -> PS interrupt request
        which_bram => which_bram, -- tell PS which BRAM is being written to currently
        ---------------------------------------------
        -- Output to BRAM 1
        ---------------------------------------------
        BRAM_1_addr_b   => BRAM_1_addr_b,
        BRAM_1_clk_b    => BRAM_1_clk_b,
        BRAM_1_rddata_b => BRAM_1_rddata_b, 
        BRAM_1_wrdata_b => BRAM_1_wrdata_b, 
        BRAM_1_en_b     => BRAM_1_en_b,
        BRAM_1_rst_b    => BRAM_1_rst_b, 
        BRAM_1_we_b     => BRAM_1_we_b,
        ---------------------------------------------
        -- Output to BRAM 2
        ---------------------------------------------
        BRAM_2_addr_b   => BRAM_2_addr_b,
        BRAM_2_clk_b    => BRAM_2_clk_b,
        BRAM_2_rddata_b => BRAM_2_rddata_b, 
        BRAM_2_wrdata_b => BRAM_2_wrdata_b, 
        BRAM_2_en_b     => BRAM_2_en_b,
        BRAM_2_rst_b    => BRAM_2_rst_b, 
        BRAM_2_we_b     => BRAM_2_we_b
    );
    
    psim : process
    begin 
        wait for 200 ns;
        reset <= '0';
        
        wait for 2000 ns;
        
        -- CASE 1
        -- simulate all TDC channels firing at once 
        wait for 3.765 * tdc_pd;
        hits <= (others => '1');
        wait for 4.356 * tdc_pd;
        hits <= (others => '0');
        -- simulate a trigger arrival (async)
        wait for 400 * tdc_pd;
        trig <= '1';
        wait for 3.358 * tdc_pd;
        trig <= '0';
        -- wait a bit for read busy to arrive
        wait for 4.1 * tdc_pd;
        busy <= '1';
        wait for 15.5 * tdc_pd;
        busy <= '0';
       
        -- CASE 2 
        -- simulate all TDC channels firing at once
        wait for 100 * tdc_pd;
        hits <= (others => '1');
        wait for 4.356 * tdc_pd;
        hits <= (others => '0');
        -- simulate a trigger arrival (async)
        wait for 100.23 ns;
        trig <= '1';
        wait for 3.358 * tdc_pd;
        trig <= '0';
        -- wait a bit for read busy to arrive
        wait for 4.1 * tdc_pd;
        busy <= '1';
        wait for 15.5 * tdc_pd;
        busy <= '0';
        
        -- CASE 2 
        -- simulate all TDC channels firing at once
        wait for 100 * tdc_pd;
        hits <= (others => '1');
        wait for 4.356 * tdc_pd;
        hits <= (others => '0');
        -- simulate a trigger arrival (async)
        wait for 100.23 ns;
        trig <= '1';
        wait for 3.358 * tdc_pd;
        trig <= '0';
        -- wait a bit for read busy to arrive
        wait for 4.1 * tdc_pd;
        busy <= '1';
        -- send another trigger 
        wait for 2.6 * tdc_pd;
        trig <= '1';
        wait for 3.5 * tdc_pd;
        trig <= '0';
        wait for 4.2 * tdc_pd;
        trig <= '1';
        wait for 2.4 * tdc_pd;
        trig <= '0';
        wait for 15.5 * tdc_pd;
        busy <= '0';
        
        
        -- wait a while then perform frequency tests at 10MHz
        wait for 100 * tdc_pd;
        hits <= (others => '1');
        wait for 3.1 * tdc_pd;
        hits <= (others => '0');
        wait for 100 ns;
        hits <= (others => '1');
        wait for 3.1 * tdc_pd;
        hits <= (others => '0');
        wait for 100 ns;
        hits <= (others => '1');
        wait for 3.1 * tdc_pd;
        hits <= (others => '0');
        wait for 100 ns;   
        -- simulate a trigger arrival (async)
        wait for 62.6 * tdc_pd;
        trig <= '1';
        wait for 3.358 * tdc_pd;
        trig <= '0';
        -- wait a bit for read busy to arrive
        wait for 4.1 * tdc_pd;
        busy <= '1';
        wait for 15.5 * tdc_pd;
        busy <= '0';
        
        -- now just try a sending to a single channel
        wait for 600 * tdc_pd;
        hits(0) <= '1';
        wait for 3.1 * tdc_pd;
        hits <= (others => '0');
        wait for 100 ns;
      
        
        wait;
    end process psim;


end Behavioral;
