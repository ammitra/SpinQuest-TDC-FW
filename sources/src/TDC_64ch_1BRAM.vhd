----------------------------------------------------------------------------------
-- 64-channel TDC block
--
--           layer 1                 layer 2            layer 3 (top)
--  |----------------------||-----------------------||-----------------|
--
--   4x TDC_4ch -> buffer -|
--   4x TDC_4ch -> buffer -|\___arbiter__buffer____
--   4x TDC_4ch -> buffer -|/                      \
--   4x TDC_4ch -> buffer -|                        |
--                                                  |
--   4x TDC_4ch -> buffer -|                        |
--   4x TDC_4ch -> buffer -|\___arbiter__buffer_____|
--   4x TDC_4ch -> buffer -|/                       | 
--   4x TDC_4ch -> buffer -|                        |
--                                                  |--------- output
--   4x TDC_4ch -> buffer -|                        |
--   4x TDC_4ch -> buffer -|\___arbiter__buffer_____|
--   4x TDC_4ch -> buffer -|/                       |
--   4x TDC_4ch -> buffer -|                        |
--                                                  |
--   4x TDC_4ch -> buffer -|                        |
--   4x TDC_4ch -> buffer -|\___arbiter__buffer____/
--   4x TDC_4ch -> buffer -|/                           
--   4x TDC_4ch -> buffer -|           
--
-- ###########################################################################
-- Top-level TDC design for the 64-channel implementation
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.common_types.all;

entity TDC_64ch_1BRAM is 
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
        ---------------------------------------------
        -- DEBUG ILA
        ---------------------------------------------
        DEBUG_data  : out std_logic_vector(g_coarse_bits+10 downto 0);
        DEBUG_valid : out std_logic; 
        DEBUG_grant : out std_logic_vector(3 downto 0);    -- read enable from arbiter to ring buffers
        ---------------------------------------------
        -- Output to BRAM 1
        ---------------------------------------------
        BRAM_1_addr_b : out std_logic_vector(31 downto 0);
        BRAM_1_clk_b  : out std_logic;
        BRAM_1_rddata_b : in std_logic_vector(63 downto 0);
        BRAM_1_wrdata_b : out std_logic_vector(63 downto 0);
        BRAM_1_en_b   : out std_logic;
        BRAM_1_rst_b  : out std_logic;
        BRAM_1_we_b   : out std_logic_vector(7 downto 0)
    );
end TDC_64ch_1BRAM;

architecture RTL of TDC_64ch_1BRAM is 

    -- Preserve architecture
    attribute keep_hierarchy : string;
    attribute keep_hierarchy of RTL : architecture is "true";
    attribute keep : string;
    attribute dont_touch : string;
    
    -------------------------------------------------
    -- Low-level TDC channel signals.
    -- Naming conventions:
    --      layer_from_to_purpose_s
    -------------------------------------------------
    -- Layer 1: 16x TDC_4ch modules -> ring buffers -> arbiter
    signal layer1_tdc_buf_data_s      : SlvArray(0 to 15)(g_coarse_bits+10 downto 0);
    signal layer1_tdc_buf_valid_s     : std_logic_vector(0 to 15);
    signal layer1_arb_buf_ren_s       : std_logic_vector(0 to 15);
    signal layer1_buf_arb_rvalid_s    : std_logic_vector(0 to 15);
    signal layer1_buf_arb_data_s      : SlvArray(0 to 15)(g_coarse_bits+10 downto 0);
    signal layer1_buf_arb_empty_s     : std_logic_vector(0 to 15); -- unused
    signal layer1_buf_arb_emptyNext_s : std_logic_vector(0 to 15); -- unused
    signal layer1_buf_arb_full_s      : std_logic_vector(0 to 15); -- unused
    signal layer1_buf_arb_fullNext_s  : std_logic_vector(0 to 15); -- unused
    signal layer1_buf_arb_fillCount_s : IntArray(0 to 15); -- unused
    -- Layer 2
    signal layer2_buf_arb_data_s  : SlvArray(0 to 3)(g_coarse_bits+10 downto 0);
    signal layer2_buf_arb_valid_s : std_logic_vector(0 to 3);
    -- Layer 3
    signal layer3_arb_buf_rd_en  : std_logic_vector(0 to 3);
    signal layer3_arb_buf_rvalid : std_logic_vector(0 to 3);
    signal layer3_buf_arb_data_s : SlvArray(0 to 3)(g_coarse_bits+10 downto 0);
    signal layer3_buf_arb_empty_s     : std_logic_vector(0 to 3); -- unused
    signal layer3_buf_arb_emptyNext_s : std_logic_vector(0 to 3); -- unused
    signal layer3_buf_arb_full_s      : std_logic_vector(0 to 3); -- unused
    signal layer3_buf_arb_fullNext_s  : std_logic_vector(0 to 3); -- unused
    signal layer3_buf_arb_fillCount_s : IntArray(0 to 3); -- unused

    ------------------------------------------------------------------------
    -- Top-level data signals
    ------------------------------------------------------------------------
    signal tdc64ch_valid_s : std_logic;
    signal tdc64ch_valid_s_last : std_logic;
    signal tdc64ch_data_s  : std_logic_vector(g_coarse_bits+10 downto 0);
    signal tdc64ch_data_s_last : std_logic_vector(g_coarse_bits+10 downto 0);
    signal tdc_data_dummy : std_logic_vector(62-(g_coarse_bits+10) downto 0) := (others => '1');

    attribute keep of tdc_data_dummy : signal is "true";
    attribute dont_touch of tdc_data_dummy : signal is "true";
    
    -- reduce fanout
    signal reset_s : std_logic;
    attribute max_fanout : integer;
    attribute max_fanout of reset_s  : signal is 55;
    
    signal trig_last  : std_logic;  -- used as trigger 
    signal busy_last  : std_logic;
    signal missed_trigs : unsigned(5 downto 0) := (others => '0'); -- also overkill for counting missed triggers
    type t_state is (
        s_idle,  -- Waiting for trigger accept, writing data to one of the BRAMs
        s_trigd, -- trigger received, send out interrupt request and wait for busy flag from PS 
        s_busy   -- PS is busy reading from one of the BRAMs, await busy low from PS
    );
    signal state : t_state := s_idle;
    signal addr1 : unsigned(31 downto 0) := (others => '0');

begin

    -- DEBUG 
    DEBUG_data  <= tdc64ch_data_s;
    DEBUG_valid <= tdc64ch_valid_s;
    DEBUG_grant <= layer3_arb_buf_rd_en;

    -- The channel IDs obey the following algorithm:
    -- ---------------------------------------------------------------
    -- channels    | ch  | calculation          | TDC_4c g_chID_start
    -- ---------------------------------------------------------------
    -- 0  1  2  3  |  0  | g_chID_start + (4*0) = 0    \
    -- 4  5  6  7  |  1  | g_chID_start + (4*1) = 4     \___________ 16 channels starting with g_chID_start => 0
    -- 8  9  10 11 |  2  | g_chID_start + (4*2) = 8     /
    -- 12 13 14 15 |  3  | g_chID_start + (4*3) = 12   /
    --
    -- 16 17 18 19 |  4  | g_chID_start + (4*4) = 16  \
    -- 20 21 22 23 |  5  | g_chID_start + (4*5) = 20   \___________ 16 channels starting with g_chID_start => 16
    -- 24 25 26 27 |  6  | g_chID_start + (4*6) = 24   /
    -- 28 29 30 31 |  7  | g_chID_start + (4*7) = 28  /
    --
    -- 32 33 34 35 |  8  | g_chID_start + (4*8) = 32  \
    -- 36 37 38 39 |  9  | g_chID_start + (4*9) = 36   \___________ 16 channels starting with g_chID_start => 0
    -- 40 41 42 43 | 10  | g_chID_start + (4*10) = 40  /
    -- 44 45 46 47 | 11  | g_chID_start + (4*11) = 44 /
    --
    -- 48 49 50 51 | 12  | g_chID_start + (4*12) = 48 \
    -- 52 53 54 55 | 13  | g_chID_start + (4*13) = 52  \___________ 16 channels starting with g_chID_start => 16
    -- 56 57 58 59 | 14  | g_chID_start + (4*14) = 56  /
    -- 60 61 62 63 | 15  | g_chID_start + (4*15) = 60  /
    --
    -- The below loop generates the first value in each row. The TDC_4ch modules 
    -- have their own generate loop that loops again: ch->ch+3 
    -------------------------------------------------------------------------------------------------------------

    -- Connect the 16 TDC_4ch modules to ring buffers
    layer1 : for ch in 0 to 15 generate
    begin 
        -- First generate 16 TDC_4ch modules..
        TDC4ch_inst : entity work.TDC_4ch
        generic map (
            g_chID_start   => g_chID_start + (4 * ch),
            g_coarse_bits  => g_coarse_bits,
            g_sat_duration => g_sat_duration,
            g_pipe_depth   => 16  -- (4ch) * (4hits / channel) = 16 hits max. Adjustable
        )
        port map (
            clk0      => clk0,
            clk45     => clk45,
            clk90     => clk90,
            clk135    => clk135,
            clk_sys   => clk_sys,
            reset     => reset,
            enable    => enable, 
            hit       => hits( (4*ch) to (4*ch+3) ),
            valid_o   => layer1_tdc_buf_valid_s(ch),
            data_o    => layer1_tdc_buf_data_s(ch)
        );
        -- Now connect the TDC_4ch modules to their hit buffers
        TDC4ch_buf_inst : entity work.ring_buffer
        generic map (
            RAM_WIDTH => g_coarse_bits + 11, -- (N coarse bits) + (6 bit chID) + (5 bit fine)
            RAM_DEPTH => 16
        )
        port map (
            clk             => clk0,
            rst             => reset, 
            wr_en           => layer1_tdc_buf_valid_s(ch), -- Valid signals from TDC channels
            wr_data         => layer1_tdc_buf_data_s(ch),  -- Data word from TDC channels 
            rd_en           => layer1_arb_buf_ren_s(ch),   -- Read enable from arbiter to buffer
            rd_valid        => layer1_buf_arb_rvalid_s(ch),-- Read valid from buffer to arbiter
            rd_data         => layer1_buf_arb_data_s(ch),  -- Data from buffer to arbiter
            -- FOLLOWING ARE UNUSED FOR NOW
            empty           => layer1_buf_arb_empty_s(ch),
            empty_next      => layer1_buf_arb_emptyNext_s(ch),
            full            => layer1_buf_arb_full_s(ch),
            full_next       => layer1_buf_arb_fullNext_s(ch),
            fill_count      => layer1_buf_arb_fillCount_s(ch)
        );
    end generate layer1;

    -- Now connect the 16 ring buffers to four 4:1 arbiters and buffers
    layer2 : for idx in 0 to 3 generate
    -- Algorithm:
    --      idx      |    connections
    --  ----------------------------------
    --      0        |    [4 * idx : (4 * idx) + 3] = [0:3]
    --      1        |    [4 * idx : (4 * idx) + 3] = [4:7]
    --      2        |    [4 * idx : (4 * idx) + 3] = [8:11]
    --      3        |    [4 * idx : (4 * idx) + 3] = [12:15]
    begin
        -- First connect layer 1 buffers -> layer 2 arbiters
        L2_arb_inst : entity work.rr_arbiter_41
        generic map (
            DWIDTH => g_coarse_bits + 11
        )
        port map (
            clk         => clk0,
            rst         => reset,
            -- Connect to the layer 1 buffers
            empty_in    => layer1_buf_arb_empty_s( (4*idx) to (4*idx+3) ),
            valid_in    => layer1_buf_arb_rvalid_s( (4*idx) to (4*idx+3) ),
            data_in     => layer1_buf_arb_data_s((4*idx) to (4*idx+3) ),
            enable_out  => layer1_arb_buf_ren_s( (4*idx) to (4*idx+3) ),
            -- Connect to the layer 2 buffers
            data_out    => layer2_buf_arb_data_s(idx),
            valid_out   => layer2_buf_arb_valid_s(idx)
        );
        -- Then connect layer 2 arbiters -> layer 2 buffers
        L2_buf_inst : entity work.ring_buffer
        generic map (
            RAM_WIDTH => g_coarse_bits + 11,
            RAM_DEPTH => 128
        )
        port map (
            clk             => clk0,
            rst             => reset,
            wr_en           => layer2_buf_arb_valid_s(idx),
            wr_data         => layer2_buf_arb_data_s(idx),
            rd_en           => layer3_arb_buf_rd_en(idx),
            rd_valid        => layer3_arb_buf_rvalid(idx),
            rd_data         => layer3_buf_arb_data_s(idx),
            empty           => layer3_buf_arb_empty_s(idx),
            -- FOLLOWING ARE UNUSED FOR NOW
            empty_next      => layer3_buf_arb_emptyNext_s(idx),  -- unused
            full            => layer3_buf_arb_full_s(idx),       -- unused
            full_next       => layer3_buf_arb_fullNext_s(idx),   -- unused
            fill_count      => layer3_buf_arb_fillCount_s(idx)   -- unused
        );
    end generate layer2;

    -- Finally, connect the layer 2 buffers to the final arbiter
    layer3_arbiter : entity work.rr_arbiter_41
    generic map ( DWIDTH => g_coarse_bits + 11 )
    port map (
        clk         => clk0,
        rst         => reset,
        empty_in    => layer3_buf_arb_empty_s,
        valid_in    => layer3_arb_buf_rvalid,
        data_in     => layer3_buf_arb_data_s,
        enable_out  => layer3_arb_buf_rd_en,
        data_out    => tdc64ch_data_s,  -- final top level output
        valid_out   => tdc64ch_valid_s  -- final top level output
    );

    -- Store asynchronous busy and trigger signals for one CC, as well as data ready
    process(all)
    begin
        if rising_edge(clk0) then
            reset_s   <= reset;
            busy_last <= rd_busy;
            trig_last <= trigger;
            tdc64ch_valid_s_last <= tdc64ch_valid_s;
            tdc64ch_data_s_last <= tdc64ch_data_s;
        end if;
    end process;

    -- Handle BRAM writing and switching 
    process(all)
    begin
        if rising_edge(clk0) then 
            if (reset_s = '1') then 
                -- disable writing
                BRAM_1_rst_b <= '1';
                BRAM_1_we_b  <= (others => '0');
                BRAM_1_en_b  <= '0';
                addr1 <= (others => '0');
                -- Clear PL -> PS interrupt flag
                irq_o <= '0';
            else
                -- BRAM_1_wrdata_b <= tdc_data_dummy & tdc64ch_data_s;
                -- if (tdc64ch_data_s_last = (tdc64ch_data_s_last'range => '0')) and (tdc64ch_data_s_last )

                if (tdc64ch_valid_s_last = '0') and (tdc64ch_valid_s = '1') then
                    BRAM_1_we_b <= (others => '1');
                    BRAM_1_wrdata_b <= tdc_data_dummy & tdc64ch_data_s;
                else 
                    BRAM_1_we_b <= (others => '0');
                    BRAM_1_wrdata_b <= (others => '0');
                end if;

                BRAM_1_en_b <= '1';

                -- When data arrives, increment address at all times
                if (tdc64ch_valid_s_last = '1') and (tdc64ch_valid_s = '0') then 
                    addr1 <= addr1 + 1;
                end if;

                -- FSM to handle trigger accept logic
                case state is 
                    when s_idle =>  -- system collecting data, waiting for trigger
                        irq_o <= '0';           -- Clear PL -> PS interrupt
                        BRAM_1_rst_b <= '0';    -- Clear BRAM resets
                        --  If the trigger has been fired and the BRAM is *not* busy being read by PS, switch the BRAM that's being written to
                        if (trigger = '1') and (trig_last = '0') then 
                            if (rd_busy = '0') then 
                                -- If PS is not busy reading, initiate read transaction
                                state <= s_trigd; -- Send out interrupt request to PS
                            else 
                                -- Otherwise, if PS is busy reading, report that we missed one trigger
                                missed_trigs <= missed_trigs + 1;
                            end if;
                        end if;
                    when s_trigd =>                 -- Trigger received, BRAMs have switched, let PS know and await busy flag.
                        irq_o <= '1';               -- Send out interrupt to PS
                        if (busy_last = '1') then   -- Wait for async PS ready busy signal to arrive before moving to next state
                            irq_o <= '0';           -- Drop interrupt flag (since it will be edge-triggered)
                            state <= s_busy;
                        end if;
                    when s_busy =>  
                        if (trigger = '1') then
                            missed_trigs <= missed_trigs + 1;
                        end if;
                        if (busy_last = '0') then       -- Wait for async PS read busy to go low
                            addr1 <= (others => '0');
                            state <= s_idle;
                        end if;
                    when others =>
                        NULL;
                end case;
            end if;
        end if;
    end process;

    -- Handle byte -> word addressing for both BRAMs
    BRAM_1_addr_b <= std_logic_vector(shift_left(addr1,3));
    -- Send BRAM clocks straight through
    BRAM_1_clk_b <= clk0;

end RTL;
