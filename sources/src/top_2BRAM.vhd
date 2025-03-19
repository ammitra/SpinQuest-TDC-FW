----------------------------------------------------------------------------------------------------------
-- Wrapper around the top-level 64 channel TDC module since VHDL 2008 is not compatible with block design
----------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.common_types.all;

entity top_64ch_2BRAM is 
    generic (
        g_chID_start   : natural := 0;
        g_coarse_bits  : natural := 28;
        g_sat_duration : natural := 3;  -- Minimum duration (in clk0 periods) that hit must remain high to be considered valid
        g_pipe_depth   : natural := 5   -- Max number of hits stored in pipeline
    );
    port (
        -- TDC and system clocks sent to all channels
        clk0    : in std_logic;
        clk45   : in std_logic;
        clk90   : in std_logic;
        clk135  : in std_logic;
        clk_sys : in std_logic;
        -- Control
        reset   : in std_logic; -- active high
        enable  : in std_logic; -- active high
        -- Data input from detector
        hits    : in std_logic_vector(0 to 63);
        trigger : in std_logic;
        -- PL <--> PS communication
        rd_busy : in std_logic;    -- PS -> PL indicating read in progress
        irq_o   : out std_logic;   -- PL -> PS interrupt request
        which_bram : out std_logic_vector(1 downto 0);  -- tell PS which BRAM is being written to currently
        ---------------------------------------------
        -- DEBUG ILA
        ---------------------------------------------
        DEBUG_data  : out std_logic_vector(g_coarse_bits+10 downto 0);
        DEBUG_valid : out std_logic;
        DEBUG_grant : out std_logic_vector(3 downto 0);
        ---------------------------------------------
        -- Output to BRAM 1
        ---------------------------------------------
        BRAM_1_addr_b : out std_logic_vector(31 downto 0);
        BRAM_1_clk_b  : out std_logic;
        BRAM_1_rddata_b : in std_logic_vector(63 downto 0);
        BRAM_1_wrdata_b : out std_logic_vector(63 downto 0);
        BRAM_1_en_b   : out std_logic;
        BRAM_1_rst_b  : out std_logic;
        BRAM_1_we_b   : out std_logic_vector(7 downto 0);
        ---------------------------------------------
        -- Output to BRAM 2
        ---------------------------------------------
        BRAM_2_addr_b : out std_logic_vector(31 downto 0);
        BRAM_2_clk_b  : out std_logic;
        BRAM_2_rddata_b : in std_logic_vector(63 downto 0);
        BRAM_2_wrdata_b : out std_logic_vector(63 downto 0);
        BRAM_2_en_b   : out std_logic;
        BRAM_2_rst_b  : out std_logic;
        BRAM_2_we_b   : out std_logic_vector(7 downto 0)
    );
end top_64ch_2BRAM;

architecture RTL of top_64ch_2BRAM is

    ----------------------------------------------------------------------------
    -- Set up bus interface in RTL directly to avoid needing to use IP packager
    ----------------------------------------------------------------------------
    attribute x_interface_info : string;
    attribute x_interface_mode : string;
    attribute x_interface_parameter : string;
    -- Reset attributes (slave, active high)
    attribute x_interface_info of reset : signal is "xilinx.com:signal:reset:1.0 reset RST";
    attribute x_interface_mode of reset : signal is "slave reset";
    attribute x_interface_parameter of reset : signal is "XIL_INTERFACENAME reset, POLARITY ACTIVE_HIGH, INSERT_VIP 0";
    -- Interrupt attributes (master, 1bit, rising edge triggered)
    attribute x_interface_info of irq_o : signal is "xilinx.com:signal:interrupt:1.0 irq_o INTERRUPT";
    attribute x_interface_mode of irq_o : signal is "master irq_o";
    attribute x_interface_parameter of irq_o : signal is "XIL_INTERFACENAME irq_o, SENSITIVITY EDGE_RISING, PortWidth 1";
    -- BRAM 1 and 2 attributes (MEM_WIDTH and MEM_SIZE should eventually be controlled by generics)
    -- NOTE: The rddata ports are INPUTS to this module, but must be described as DOUT in the interface.
    --       Likewise, the wrdata ports are OUTPUTS from this module, but must be described as DIN in the interface.
    --       My guess is that b/c this interface is described as a master, these DIN/DOUT conventions are from the POV of the slave?
    attribute x_interface_info of BRAM_1_addr_b : signal is "xilinx.com:interface:bram:1.0 BRAM_1_b ADDR";
    attribute x_interface_mode of BRAM_1_addr_b : signal is "master BRAM_1_b";
    attribute x_interface_parameter of BRAM_1_addr_b : signal is "XIL_INTERFACENAME BRAM_1_b, MEM_SIZE 8192, MEM_WIDTH 64, MASTER_TYPE BRAM_CTRL, MEM_ECC NONE, READ_LATENCY 1";
    attribute x_interface_info of BRAM_1_clk_b : signal is "xilinx.com:interface:bram:1.0 BRAM_1_b CLK";
    attribute x_interface_info of BRAM_1_rddata_b : signal is "xilinx.com:interface:bram:1.0 BRAM_1_b DOUT";
    attribute x_interface_info of BRAM_1_wrdata_b : signal is "xilinx.com:interface:bram:1.0 BRAM_1_b DIN";
    attribute x_interface_info of BRAM_1_en_b : signal is "xilinx.com:interface:bram:1.0 BRAM_1_b EN";
    attribute x_interface_info of BRAM_1_rst_b : signal is "xilinx.com:interface:bram:1.0 BRAM_1_b RST";
    attribute x_interface_info of BRAM_1_we_b : signal is "xilinx.com:interface:bram:1.0 BRAM_1_b WE";
    attribute x_interface_info of BRAM_2_addr_b : signal is "xilinx.com:interface:bram:1.0 BRAM_2_b ADDR";
    attribute x_interface_mode of BRAM_2_addr_b : signal is "master BRAM_2_b";
    attribute x_interface_parameter of BRAM_2_addr_b : signal is "XIL_INTERFACENAME BRAM_2_b, MEM_SIZE 8192, MEM_WIDTH 64, MASTER_TYPE BRAM_CTRL, MEM_ECC NONE, READ_LATENCY 1";
    attribute x_interface_info of BRAM_2_clk_b : signal is "xilinx.com:interface:bram:1.0 BRAM_2_b CLK";
    attribute x_interface_info of BRAM_2_rddata_b : signal is "xilinx.com:interface:bram:1.0 BRAM_2_b DOUT";
    attribute x_interface_info of BRAM_2_wrdata_b : signal is "xilinx.com:interface:bram:1.0 BRAM_2_b DIN";
    attribute x_interface_info of BRAM_2_en_b : signal is "xilinx.com:interface:bram:1.0 BRAM_2_b EN";
    attribute x_interface_info of BRAM_2_rst_b : signal is "xilinx.com:interface:bram:1.0 BRAM_2_b RST";
    attribute x_interface_info of BRAM_2_we_b : signal is "xilinx.com:interface:bram:1.0 BRAM_2_b WE";
   


begin

    e_tdc_64ch : entity work.TDC_64ch
    generic map (
        g_chID_start   => g_chID_start,
        g_coarse_bits  => g_coarse_bits,
        g_sat_duration => g_sat_duration,
        g_pipe_depth   => g_pipe_depth
    )
    port map (
        -- TDC and system clocks sent to all channels
        clk0    => clk0,
        clk45   => clk45,
        clk90   => clk90,
        clk135  => clk135,
        clk_sys => clk_sys,
        -- Control
        reset   => reset, -- active high
        enable  => enable, -- active high
        -- Data input from detector
        hits    => hits,
        trigger => trigger,
        -- PL <--> PS communication
        rd_busy => rd_busy,    -- PS -> PL indicating read in progress
        irq_o   => irq_o,   -- PL -> PS interrupt request
        which_bram => which_bram,  -- tell PS which BRAM is being written to currently
        ---------------------------------------------
        -- DEBUG ILA
        ---------------------------------------------
        DEBUG_data  => DEBUG_data,
        DEBUG_valid => DEBUG_valid,
        DEBUG_grant => DEBUG_grant, 
        ---------------------------------------------
        -- Output to BRAM 1
        ---------------------------------------------
        BRAM_1_addr_b   => BRAM_1_addr_b,
        BRAM_1_clk_b    => BRAM_1_clk_b,
        BRAM_1_rddata_b => BRAM_1_rddata_b, -- not used
        BRAM_1_wrdata_b => BRAM_1_wrdata_b, -- sends the actual data
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

end RTL;