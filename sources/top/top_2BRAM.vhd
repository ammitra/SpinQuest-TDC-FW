library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
use work.common_types.all;

entity top is 
    generic (
        GLOBAL_DATE    : std_logic_vector(31 downto 0) := (others => '0');
        GLOBAL_TIME    : std_logic_vector(31 downto 0) := (others => '0');
        GLOBAL_VER     : std_logic_vector(31 downto 0) := (others => '0');
        GLOBAL_SHA     : std_logic_vector(31 downto 0) := (others => '0')
    );
    port (
        -- Specified in the XDC!
        tdc_hit : in std_logic_vector(0 downto 0);
        trigger : in std_logic
    );
end top;

architecture structure of top is 
    --The 64 channel TDC module
    component TDC_64ch_2BRAM_wrapper is
    generic (
        GLOBAL_DATE    : std_logic_vector(31 downto 0);
        GLOBAL_TIME    : std_logic_vector(31 downto 0);
        GLOBAL_VER     : std_logic_vector(31 downto 0);
        GLOBAL_SHA     : std_logic_vector(31 downto 0);
        g_chID_start   : natural;
        g_coarse_bits  : natural;
        g_sat_duration : natural;
        g_pipe_depth   : natural
    );
    port (
        clk0            : in std_logic;
        clk45           : in std_logic;
        clk90           : in std_logic;
        clk135          : in std_logic;
        clk_sys         : in std_logic;
        reset           : in std_logic;
        enable          : in std_logic;
        hits            : in std_logic_vector(0 to 63);
        trigger         : in std_logic;
        rd_busy         : in std_logic;
        irq_o           : out std_logic;
        which_bram      : out std_logic_vector(1 downto 0);
        DEBUG_data      : out std_logic_vector(g_coarse_bits+10 downto 0);
        DEBUG_valid     : out std_logic;
        DEBUG_grant     : out std_logic_vector(3 downto 0);
        BRAM_1_addr_b   : out std_logic_vector(31 downto 0);
        BRAM_1_clk_b    : out std_logic;
        BRAM_1_rddata_b : in std_logic_vector(63 downto 0);
        BRAM_1_wrdata_b : out std_logic_vector(63 downto 0);
        BRAM_1_en_b     : out std_logic;
        BRAM_1_rst_b    : out std_logic;
        BRAM_1_we_b     : out std_logic_vector(7 downto 0);
        BRAM_2_addr_b   : out std_logic_vector(31 downto 0);
        BRAM_2_clk_b    : out std_logic;
        BRAM_2_rddata_b : in std_logic_vector(63 downto 0);
        BRAM_2_wrdata_b : out std_logic_vector(63 downto 0);
        BRAM_2_en_b     : out std_logic;
        BRAM_2_rst_b    : out std_logic;
        BRAM_2_we_b     : out std_logic_vector(7 downto 0)
    );
    end component TDC_64ch_2BRAM_wrapper;
    -- The Zynq PS
    component ZynqPS_wrapper is
    port (
        BRAM_1_B_addr : in STD_LOGIC_VECTOR ( 31 downto 0 );
        BRAM_1_B_clk  : in STD_LOGIC;
        BRAM_1_B_din  : in STD_LOGIC_VECTOR ( 63 downto 0 );
        BRAM_1_B_dout : out STD_LOGIC_VECTOR ( 63 downto 0 );
        BRAM_1_B_en   : in STD_LOGIC;
        BRAM_1_B_rst  : in STD_LOGIC;
        BRAM_1_B_we   : in STD_LOGIC_VECTOR ( 7 downto 0 );
        BRAM_2_B_addr : in STD_LOGIC_VECTOR ( 31 downto 0 );
        BRAM_2_B_clk  : in STD_LOGIC;
        BRAM_2_B_din  : in STD_LOGIC_VECTOR ( 63 downto 0 );
        BRAM_2_B_dout : out STD_LOGIC_VECTOR ( 63 downto 0 );
        BRAM_2_B_en   : in STD_LOGIC;
        BRAM_2_B_rst  : in STD_LOGIC;
        BRAM_2_B_we   : in STD_LOGIC_VECTOR ( 7 downto 0 );
        gpio_io_i_0   : in STD_LOGIC_VECTOR ( 1 downto 0 );
        gpio_io_o_0   : out STD_LOGIC_VECTOR ( 0 to 0 );
        pl_ps_irq0_0  : in STD_LOGIC_VECTOR ( 0 to 0 );
        ps_aresetn    : out STD_LOGIC_VECTOR ( 0 to 0 );
        clk_out1_0    : out STD_LOGIC;
        clk_out2_0    : out STD_LOGIC;
        clk_out3_0    : out STD_LOGIC;
        clk_out4_0    : out STD_LOGIC;
        clk_sys       : out STD_LOGIC;
        locked_0      : out STD_LOGIC
    );
    end component ZynqPS_wrapper;
    
    attribute dont_touch : string;

    -- Signals
    -- BRAM
    signal BRAM_1_B_addr_s : STD_LOGIC_VECTOR ( 31 downto 0 );
    signal BRAM_1_B_clk_s  : STD_LOGIC;
    signal BRAM_1_B_din_s  : STD_LOGIC_VECTOR ( 63 downto 0 );
    signal BRAM_1_B_dout_s : STD_LOGIC_VECTOR ( 63 downto 0 );
    signal BRAM_1_B_en_s   : STD_LOGIC;
    signal BRAM_1_B_rst_s  : STD_LOGIC;
    signal BRAM_1_B_we_s   : STD_LOGIC_VECTOR ( 7 downto 0 );
    signal BRAM_2_B_addr_s : STD_LOGIC_VECTOR ( 31 downto 0 );
    signal BRAM_2_B_clk_s  : STD_LOGIC;
    signal BRAM_2_B_din_s  : STD_LOGIC_VECTOR ( 63 downto 0 );
    signal BRAM_2_B_dout_s : STD_LOGIC_VECTOR ( 63 downto 0 );
    signal BRAM_2_B_en_s   : STD_LOGIC;
    signal BRAM_2_B_rst_s  : STD_LOGIC;
    signal BRAM_2_B_we_s   : STD_LOGIC_VECTOR ( 7 downto 0 );
    -- PLL
    signal clk1_s : std_logic; 
    signal clk2_s : std_logic; 
    signal clk3_s : std_logic;
    signal clk4_s : std_logic;
    signal clk_sys_s : std_logic;
    signal locked_s : std_logic;
    -- TDC
    signal resetn_s     : std_logic_vector(0 downto 0);
    signal reset_s      : std_logic;
    signal rd_busy_slv  : std_logic_vector(0 downto 0);
    signal rd_busy_s    : std_logic;
    signal irq_slv      : std_logic_vector(0 downto 0);
    signal irq_s        : std_logic;
    signal which_bram_s : std_logic_vector(1 downto 0);
    signal hits_s       : std_logic_vector(63 downto 0);

    -- unused
    signal DEBUG_data_s : std_logic_vector(38 downto 0);
    signal DEBUG_valid_s : std_logic;
    signal DEBUG_grant_s : std_logic_vector(3 downto 0);

    -- Prevent optimizations
    attribute dont_touch of BRAM_1_B_addr_s : signal is "true";
    attribute dont_touch of BRAM_1_B_clk_s : signal is "true";
    attribute dont_touch of BRAM_1_B_din_s : signal is "true";
    attribute dont_touch of BRAM_1_B_dout_s : signal is "true";
    attribute dont_touch of BRAM_1_B_en_s : signal is "true";
    attribute dont_touch of BRAM_1_B_rst_s : signal is "true";
    attribute dont_touch of BRAM_1_B_we_s : signal is "true";
    attribute dont_touch of BRAM_2_B_addr_s : signal is "true";
    attribute dont_touch of BRAM_2_B_clk_s : signal is "true";
    attribute dont_touch of BRAM_2_B_din_s : signal is "true";
    attribute dont_touch of BRAM_2_B_dout_s : signal is "true";
    attribute dont_touch of BRAM_2_B_en_s : signal is "true";
    attribute dont_touch of BRAM_2_B_rst_s : signal is "true";
    attribute dont_touch of clk1_s : signal is "true";
    attribute dont_touch of clk2_s : signal is "true";
    attribute dont_touch of clk3_s : signal is "true";
    attribute dont_touch of clk4_s : signal is "true";
    attribute dont_touch of clk_sys_s : signal is "true";
    attribute dont_touch of locked_s : signal is "true";
    attribute dont_touch of resetn_s : signal is "true";
    attribute dont_touch of reset_s : signal is "true";




begin

    -- duplicate hit 64x
    hits_s <= (others => tdc_hit(0));

    -- Invert resetn
    reset_s <= not resetn_s(0);
    
    -- convert vectors to logic
    irq_s <= irq_slv(0);
    rd_busy_s <= rd_busy_slv(0);

    -- Instance of the Zynq PS
    zynqPS_i : component ZynqPS_wrapper
    port map (
        BRAM_1_B_addr => BRAM_1_B_addr_s,
        BRAM_1_B_clk  => BRAM_1_B_clk_s,
        BRAM_1_B_din  => BRAM_1_B_din_s,
        BRAM_1_B_dout => BRAM_1_B_dout_s,
        BRAM_1_B_en   => BRAM_1_B_en_s,
        BRAM_1_B_rst  => BRAM_1_B_rst_s,
        BRAM_1_B_we   => BRAM_1_B_we_s,
        BRAM_2_B_addr => BRAM_2_B_addr_s,
        BRAM_2_B_clk  => BRAM_2_B_clk_s,
        BRAM_2_B_din  => BRAM_2_B_din_s,
        BRAM_2_B_dout => BRAM_2_B_dout_s,
        BRAM_2_B_en   => BRAM_2_B_en_s,
        BRAM_2_B_rst  => BRAM_2_B_rst_s,
        BRAM_2_B_we   => BRAM_2_B_we_s,
        gpio_io_i_0   => which_bram_s,
        gpio_io_o_0   => rd_busy_slv,
        pl_ps_irq0_0  => irq_slv,
        ps_aresetn    => resetn_s,
        clk_out1_0    => clk1_s,
        clk_out2_0    => clk2_s,
        clk_out3_0    => clk3_s,
        clk_out4_0    => clk4_s,
        clk_sys       => clk_sys_s,
        locked_0      => locked_s
    );

    -- 64ch TDC instance
    TDC64ch_i : component TDC_64ch_2BRAM_wrapper
    generic map (
        GLOBAL_DATE    => GLOBAL_DATE,
        GLOBAL_TIME    => GLOBAL_TIME,
        GLOBAL_VER     => GLOBAL_VER,
        GLOBAL_SHA     => GLOBAL_SHA,
        g_chID_start   => 0,
        g_coarse_bits  => 28,
        g_sat_duration => 3,
        g_pipe_depth   => 5
    )
    port map (
        clk0            => clk1_s,
        clk45           => clk2_s,
        clk90           => clk3_s,
        clk135          => clk4_s,
        clk_sys         => clk_sys_s,
        reset           => reset_s,
        enable          => locked_s,
        hits            => hits_s,
        trigger         => trigger,
        rd_busy         => rd_busy_s,
        irq_o           => irq_s,
        which_bram      => which_bram_s,
        DEBUG_data      => DEBUG_data_s,
        DEBUG_valid     => debug_valid_s,
        DEBUG_grant     => Debug_grant_s,
        BRAM_1_addr_b   => BRAM_1_B_addr_s,
        BRAM_1_clk_b    => BRAM_1_B_clk_s,
        BRAM_1_rddata_b => BRAM_1_B_dout_s, -- dout from BRAM -> TDC din (not used)
        BRAM_1_wrdata_b => BRAM_1_B_din_s,  -- wrdata from TDC -> BRAM din
        BRAM_1_en_b     => BRAM_1_B_en_s,
        BRAM_1_rst_b    => BRAM_1_B_rst_s,
        BRAM_1_we_b     => BRAM_1_B_we_s,
        BRAM_2_addr_b   => BRAM_2_B_addr_s,
        BRAM_2_clk_b    => BRAM_2_B_clk_s,
        BRAM_2_rddata_b => BRAM_2_B_dout_s,
        BRAM_2_wrdata_b => BRAM_2_B_din_s,
        BRAM_2_en_b     => BRAM_2_B_en_s,
        BRAM_2_rst_b    => BRAM_2_B_rst_s,
        BRAM_2_we_b     => BRAM_2_B_we_s
    );

end structure;

