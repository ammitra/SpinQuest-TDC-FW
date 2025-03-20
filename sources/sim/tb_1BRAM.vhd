---------------------------------------------------------------------------------------------------------
--! \file tb_1BRAM.vhd
--! \brief Testbench for the 64 channel TDC implementation which writes to one BRAM only.
--! \author Amitav Mitra, amitra3@jhu.edu
---------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity test_1BRAM is
--  Port ( );
end test_1BRAM;

architecture Behavioral of test_1BRAM is

    --! Procedure for generating a clock signal of a given frequency and phase.
    --! Used in this testbench to generate an input clock signal to the MMCM clk_wiz_0 component
    --! 
    --! \param CLK      Signal that will act as the desired clock.
    --! \param FREQ     Desired frequency for the generated clock.
    --! \param PHASE    Phase offset for the clock.
    --! 
    --! **Example:**
    --! ```vhdl
    --! signal clk_rf   : std_logic;        -- The signal used as a clock
    --! constant freq   : real := 50.000E6; -- 50 MHz
    --! constant phase  : time := 0 ns;     -- No phase offset
    --! clk_gen(clk_rf, freq, phase);
    --! ```
    procedure clk_gen(signal CLK : out std_logic; constant FREQ : real; PHASE : time := 1 ns) is
        constant PERIOD    : time := 1 sec / FREQ;        --! Full period
        constant HIGH_TIME : time := PERIOD / 2;          --! High time
        constant LOW_TIME  : time := PERIOD - HIGH_TIME;  --! Low time; always >= HIGH_TIME
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
    
    signal clk_sys : std_logic; --! Signal representing the RF clock. Used as input to the MMCM component
    signal clk0    : std_logic; --! 0-degree phase-shifted output clock from MMCM
    signal clk45   : std_logic; --! 45-degree phase-shifted output clock from MMCM
    signal clk90   : std_logic; --! 90-degree phase-shifted output clock from MMCM
    signal clk135  : std_logic; --! 135-degree phase-shifted output clock from MMCM

    signal reset  : std_logic := '1';   --! Reset signal sent to MMCM and TDC_64ch
    signal locked : std_logic;          --! Locked signal sent from MMCM to TDC_64ch enable

    signal hits : std_logic_vector(0 to 63) := (others => '0'); --! External hits sent to TDC_64ch
    signal trig : std_logic := '0';                             --! External trigger sent to TDC_64ch
    signal busy : std_logic := '0';                             --! PS -> PL read busy signal
    signal irq  : std_logic;                                    --! PL -> PS rising-edge triggered interrupt
    signal which_bram : std_logic_vector(1 downto 0);           --! PL -> PS signal indicating which BRAM is *currently* being written to
    signal BRAM_1_addr_b   : std_logic_vector(31 downto 0);     --! BRAM 1 port B address signal. Byte-addressed
    signal BRAM_1_clk_b    : std_logic;                         --! BRAM 1 port B clock. Should be running at 212.4 MHz (clk0)
    signal BRAM_1_rddata_b : std_logic_vector(63 downto 0);     --! BRAM 1 port B read data. Not used in this testbench. In actual design, reports the value last written on port B.
    signal BRAM_1_wrdata_b : std_logic_vector(63 downto 0);     --! BRAM 1 port B write data. 64-bit TDC data 
    signal BRAM_1_en_b     : std_logic;                         --! BRAM 1 port B enable. Always high for the 1 BRAM implementation unless reset active 
    signal BRAM_1_rst_b    : std_logic;                         --! BRAM 1 port B reset.
    signal BRAM_1_we_b     : std_logic_vector(7 downto 0);      --! BRAM 1 port B write enable. Pulses high when arbiter receives valid data.

    -- clock periods
    constant tdc_pd : time := 1 sec / 212.400E6;    --! clk0 period = 1 / 212.4 MHz ~= 4.71 ns
    constant sys_pd : time := 1 sec / 53.100E6;     --! RF clock period = 1 / 53.1 MHz ~= 18.83 ns
    
begin

    clk_gen(clk_sys, 53.100E6, 0 ns); 
    
    --! MMCM IP from the Xilinx clocking wizard.

    --! This IP is specifically added to the project for this testbench and is different from the one instantiated in the block design.
    --! It is configured to take an input clock of 53.1 MHz and output four 212.4 MHz clocks, each phase-shifted 45 degrees from each other.
    --! It is therefore used to test the 64 channel implementation writing to BRAM at 212.4 MHz.
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
    
    --! 64-channel TDC entity instantiation 

    --! This is the 64-channel TDC entity that writes to only one BRAM. This entity is described using VHDL 2008 and 
    --! must therefore be wrapped by a VHDL 93 file in order to be used in the block design. See, e.g. \ref top_1BRAM.vhd "`sources/src/top_1BRAM.vhd`". 
    uut : entity work.TDC_64ch_1BRAM
    generic map (
        g_chID_start   => 0,      -- Channel ID of the lowest channel in the group of 16
        g_coarse_bits  => 28,     -- Number of coarse bits to use 
        g_sat_duration => 3,      -- Number of clk0 cycles hit must remain high to be digitized
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
        ---------------------------------------------
        -- DEBUG ILA
        ---------------------------------------------
        DEBUG_data  => open,
        DEBUG_valid => open,
        DEBUG_grant => open,
        ---------------------------------------------
        -- Output to BRAM 1
        ---------------------------------------------
        BRAM_1_addr_b   => BRAM_1_addr_b,
        BRAM_1_clk_b    => BRAM_1_clk_b,
        BRAM_1_rddata_b => BRAM_1_rddata_b, 
        BRAM_1_wrdata_b => BRAM_1_wrdata_b, 
        BRAM_1_en_b     => BRAM_1_en_b,
        BRAM_1_rst_b    => BRAM_1_rst_b, 
        BRAM_1_we_b     => BRAM_1_we_b
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
