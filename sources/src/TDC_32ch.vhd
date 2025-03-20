----------------------------------------------------------------------------------
-- 32-channel TDC block
--
-- 4x TDC channels -> Arbiter   -|
-- 4x TDC channels -> Arbiter   -|\___________ buffer _____
-- 4x TDC channels -> Arbiter   -|/                        \
-- 4x TDC Channels -> Arbiter   -|                          |
--                                                          |--------- arbiter
-- 4x TDC channels -> Arbiter   -|                          |
-- 4x TDC channels -> Arbiter   -|\___________ buffer _____/
-- 4x TDC channels -> Arbiter   -|/                           
-- 4x TDC Channels -> Arbiter   -|                           

--
-- ###########################################################################
-- Top-level TDC design for the 32-channel implementation
-- ############################################################################
-- UNUSED ************************************************************
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.common_types.all;

entity TDC_32ch is 
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
        hits    : in std_logic_vector(0 to 31);
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
        DEBUG_grant : out std_logic_vector(31 downto 0);    -- read enable from arbiter to ring buffers
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
end TDC_32ch;

architecture RTL of TDC_32ch is 

    -- Preserve architecture
    attribute keep_hierarchy : string;
    attribute keep_hierarchy of RTL : architecture is "true";

    attribute keep : string;
    attribute dont_touch : string;

    -------------------------------------------------
    -- Signal naming conventions:
    --      from_to_purpose_s
    -------------------------------------------------
    type int_array is array(0 to 31) of integer;
    -- Signals from TDC channel -> ring buffers
    signal tdc_buf_data_s  : SlvArray(0 to 31)(g_coarse_bits+10 downto 0);
    signal tdc_buf_valid_s : std_logic_vector(0 to 31);
    -- Signals between ring buffers and arbiter.
    signal arb_buf_ren_s       : std_logic_vector(0 to 31);
    signal buf_arb_rvalid_s    : std_logic_vector(0 to 31);
    signal buf_arb_data_s      : SlvArray(0 to 31)(g_coarse_bits+10 downto 0);
    signal buf_arb_empty_s     : std_logic_vector(0 to 31);
    signal buf_arb_emptyNext_s : std_logic_vector(0 to 31);
    signal buf_arb_full_s      : std_logic_vector(0 to 31);
    signal buf_arb_fullNext_s  : std_logic_vector(0 to 31);
    signal buf_arb_fillCount_s : IntArray(0 to 31);

    ------------------------------------------------------------------------
    -- Signals
    ------------------------------------------------------------------------
    signal tdc32ch_valid_s : std_logic;
    signal tdc32ch_valid_s_last : std_logic;
    signal tdc32ch_data_s  : std_logic_vector(g_coarse_bits+10 downto 0);
    signal tdc_data_dummy : std_logic_vector(62-(g_coarse_bits+10) downto 0) := (others => '1');

    attribute keep of tdc_data_dummy : signal is "true";
    attribute dont_touch of tdc_data_dummy : signal is "true";
    
    -- reduce fanout
    signal reset_s : std_logic;
    attribute max_fanout : integer;
    attribute max_fanout of reset_s  : signal is 50;
    
    signal trig_last  : std_logic;  -- used as trigger 
    signal busy_last  : std_logic;
    signal missed_trigs : unsigned(5 downto 0) := (others => '0'); -- also overkill for counting missed triggers
    type t_state is (
        s_idle,  -- Waiting for trigger accept, writing data to one of the BRAMs
        s_trigd, -- trigger received, send out interrupt request and wait for busy flag from PS 
        s_busy   -- PS is busy reading from one of the BRAMs, await busy low from PS
    );
    signal state : t_state := s_idle;
    signal addr  : unsigned(31 downto 0) := (others => '0');
    signal addr1 : unsigned(31 downto 0) := (others => '0');
    signal addr2 : unsigned(31 downto 0) := (others => '0');
    signal which_bram_s : unsigned(1 downto 0) := "10";

begin

    -- DEBUG 
    DEBUG_data  <= tdc32ch_data_s;
    DEBUG_valid <= tdc32ch_valid_s;
    DEBUG_grant <= arb_buf_ren_s;

    -- connect single TDC channels directly to the 32:1 mux
    tdc_channels : for ch in 0 to 31 generate
    begin
        TDC_ch_inst : entity work.TDC_channel
            generic map (
                g_channel_id   => g_chID_start + ch,
                g_sat_duration => g_sat_duration,
                g_coarse_bits  => g_coarse_bits
            )
            port map (
                clk0      => clk0,
                clk45     => clk45,
                clk90     => clk90,
                clk135    => clk135,
                clk_sys   => clk_sys,
                reset     => reset_s,
                enable    => enable, 
                hit       => hits(ch),
                valid     => tdc_buf_valid_s(ch),
                timestamp => tdc_buf_data_s(ch)
            );
        TDC_ch_buf_inst : entity work.ring_buffer
            generic map (
                RAM_WIDTH => g_coarse_bits + 11, -- (N coarse bits) + (6 bit chID) + (5 bit fine)
                RAM_DEPTH => g_pipe_depth
            )
            port map (
                clk             => clk0,
                rst             => reset_s, 
                wr_en           => tdc_buf_valid_s(ch), -- Valid signals from TDC channels
                wr_data         => tdc_buf_data_s(ch),  -- Data word from TDC channels 
                rd_en           => arb_buf_ren_s(ch),   -- Read enable from arbiter to buffer
                rd_valid        => buf_arb_rvalid_s(ch),-- Read valid from buffer to arbiter
                rd_data         => buf_arb_data_s(ch),  -- Data from buffer to arbiter
                -- FOLLOWING ARE UNUSED FOR NOW
                empty           => buf_arb_empty_s(ch),
                empty_next      => buf_arb_emptyNext_s(ch),
                full            => buf_arb_full_s(ch),
                full_next       => buf_arb_fullNext_s(ch),
                fill_count      => buf_arb_fillCount_s(ch)
            );
    end generate tdc_channels;

    -- Connect the ring buffers to the 32:1 arbiter
    arbiter_32ch : entity work.rr_arbiter_321
        generic map ( DWIDTH => g_coarse_bits + 11 )
        port map (
            empty_in    => buf_arb_empty_s,
            valid_in    => buf_arb_rvalid_s,
            data_in     => buf_arb_data_s,
            enable_out  => arb_buf_ren_s,
            clk         => clk0,
            rst         => reset_s,
            data_out    => tdc32ch_data_s,
            valid_out   => tdc32ch_valid_s
        );

    -- store asynchronous busy and trigger signals for one CC, as well as data ready
    process(all)
    begin
        if rising_edge(clk0) then
            reset_s   <= reset;
            busy_last <= rd_busy;
            trig_last <= trigger;
            tdc32ch_valid_s_last <= tdc32ch_valid_s;
        end if;
    end process;

    -- Wire the selected BRAM ID to output 
    which_bram <= std_logic_vector(which_bram_s);

    -- Handle BRAM writing and switching 
    process(all)
    begin
        if rising_edge(clk0) then 
            if (reset_s = '1') then 
                -- Switch back to BRAM 1
                which_bram_s <= "01";
                -- Clear BRAMs, disable writing
                BRAM_1_rst_b <= '1';
                BRAM_2_rst_b <= '1';
                BRAM_1_we_b  <= (others => '0');
                BRAM_2_we_b  <= (others => '0');
                BRAM_1_en_b  <= '0';
                BRAM_2_en_b  <= '0';
                --addr <= (others => '0');
                addr1 <= (others => '0');
                addr2 <= (others => '0');
                -- Clear PL -> PS interrupt flag
                irq_o <= '0';
            else
                if which_bram_s = "01" then 
                    -- Tie TDC data to the selected BRAM at all times
                    BRAM_1_wrdata_b <= tdc_data_dummy & tdc32ch_data_s;
                    BRAM_2_wrdata_b <= (others => '0');
                    -- Writing to BRAM 1 whenever valid data rxd
                    --BRAM_1_we_b <= (others => tdc32ch_valid_s);
                    if (tdc32ch_valid_s_last = '0') and (tdc32ch_valid_s = '1') then
                        BRAM_1_we_b <= (others => '1');
                    else 
                        BRAM_1_we_b <= (others => '0');
                    end if;
                    BRAM_2_we_b <= (others => '0');
                    BRAM_1_en_b <= '1';
                    BRAM_2_en_b <= '0';
                elsif which_bram_s <= "10" then 
                    BRAM_1_wrdata_b <= (others => '0');
                    BRAM_2_wrdata_b <= tdc_data_dummy & tdc32ch_data_s;
                    BRAM_1_we_b <= (others => '0');
                    if (tdc32ch_valid_s_last = '0') and (tdc32ch_valid_s = '1') then
                        BRAM_2_we_b <= (others => '1');
                    else 
                        BRAM_2_we_b <= (others => '0');
                    end if;
                    --BRAM_2_we_b <= (others => tdc32ch_valid_s);
                    BRAM_1_en_b <= '0';
                    BRAM_2_en_b <= '1';
                end if;
                -- When data arrives, increment address at all times
                if (tdc32ch_valid_s_last = '0') and (tdc32ch_valid_s = '1') then 
                    --addr <= addr + 1;
                    case which_bram_s is
                        when "01" =>
                            addr1 <= addr1 + 1;
                        when "10" =>
                            addr2 <= addr2 + 1;
                        when others => 
                            NULL;
                    end case;
                end if;

                -- FSM to handle trigger accept logic
                case state is 
                    when s_idle =>  -- system collecting data, waiting for trigger
                        irq_o <= '0';           -- Clear PL -> PS interrupt
                        BRAM_1_rst_b <= '0';    -- Clear BRAM resets
                        BRAM_2_rst_b <= '0';
                        --  If the trigger has been fired and the BRAM is *not* busy being read by PS, switch the BRAM that's being written to
                        if (trigger = '1') and (trig_last = '0') then 
                            if (rd_busy = '0') then 
                                -- If PS is not busy reading, then we can switch BRAMs and initiate read transaction
                                case which_bram_s is 
                                    when "01" =>    -- BRAM 1 is currently being written to - move write ptr to BRAM 2, and let PS know
                                        which_bram_s <= "10";
                                        BRAM_2_en_b  <= '1';
                                    when "10" =>    -- BRAM 2 is currently being written to - move write ptr to BRAM 1, and let PS know
                                        which_bram_s <= "01";
                                        BRAM_1_en_b  <= '1';
                                    when others => 
                                        NULL;
                                end case;
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
                            --addr <= (others => '0');    -- Reset address
                            case which_bram_s is 
                                when "01" =>    -- BRAM 1 is being written to, so clear BRAM 2 (it was just read out)
                                    BRAM_2_rst_b <= '1';
                                    addr2 <= (others => '0');
                                when "10" =>    -- BRAM 2 is being written to, so clear BRAM 1 (it was just read out)
                                    BRAM_1_rst_b <= '1';
                                    addr1 <= (others => '0');
                                when others => 
                                    NULL;
                            end case;
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
    BRAM_2_addr_b <= std_logic_vector(shift_left(addr2,3));
    -- Send BRAM clocks straight through
    BRAM_1_clk_b <= clk0;
    BRAM_2_clk_b <= clk0;


end RTL;
