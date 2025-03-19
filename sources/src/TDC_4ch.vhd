----------------------------------------------------------------------------------
-- 4-channel TDC block
--
-- TDC channel -> 4-hit pipeline \
-- TDC channel -> 4-hit pipeline  \___________ Arbiter
-- TDC channel -> 4-hit pipeline  /
-- TDC Channel -> 4-hit pipeline /
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.common_types.all;

entity TDC_4ch is
    generic (
        g_chID_start   : natural := 0;
        g_coarse_bits  : natural := 28;
        g_sat_duration : natural := 3;  -- Minimum duration (in clk0 periods) that hit must remain high to be considered valid
        g_pipe_depth   : natural := 5   -- Max number of hits stored in pipeline
    );
    port (
        -- TDC and system clocks sent to all 4 channels
        clk0    : in std_logic;
        clk45   : in std_logic;
        clk90   : in std_logic;
        clk135  : in std_logic;
        clk_sys : in std_logic;
        -- Control 
        reset   : in std_logic; -- active high
        enable  : in std_logic; -- active high
        -- Data input from detector
        hit     : in std_logic_vector(0 to 3);
        -- Data outputs (timestamp + valid) from arbiter
        valid_o : out std_logic;
        data_o  : out std_logic_vector(g_coarse_bits+10 downto 0)
    );
end TDC_4ch;

architecture Behavioral of TDC_4ch is
    -- Reset signal
    signal reset_s : std_logic;

    -------------------------------------------------
    -- Signal naming conventions:
    --      from_to_purpose_s
    -------------------------------------------------
    type int_array is array(0 to 3) of integer;
    -- Signals from TDC channel -> ring buffers
    signal tdc_buf_data_s  : SlvArray(0 to 3)(g_coarse_bits+10 downto 0);
    signal tdc_buf_valid_s : std_logic_vector(0 to 3);
    -- Signals between ring buffers and arbiter.
    signal arb_buf_ren_s       : std_logic_vector(0 to 3);
    signal buf_arb_rvalid_s    : std_logic_vector(0 to 3);
    signal buf_arb_data_s      : SlvArray(0 to 3)(g_coarse_bits+10 downto 0);
    signal buf_arb_empty_s     : std_logic_vector(0 to 3);
    signal buf_arb_emptyNext_s : std_logic_vector(0 to 3);
    signal buf_arb_full_s      : std_logic_vector(0 to 3);
    signal buf_arb_fullNext_s  : std_logic_vector(0 to 3);
    signal buf_arb_fillCount_s : IntArray(0 to 3);


begin

    -- Register the reset
    process(all)
    begin 
        if rising_edge(clk0) then 
            reset_s <= reset;
        end if;
    end process;

    -- Instantiate the TDC channels and their output to ring buffers
    tdc_channels : for ch in 0 to 3 generate
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
                hit       => hit(ch),
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
                empty           => buf_arb_empty_s(ch), -- Empty signal from buffer to arbiter
                -- FOLLOWING ARE UNUSED FOR NOW
                empty_next      => buf_arb_emptyNext_s(ch),
                full            => buf_arb_full_s(ch),
                full_next       => buf_arb_fullNext_s(ch),
                fill_count      => buf_arb_fillCount_s(ch)
            );
    end generate tdc_channels;

    -- Connect ring buffers to arbiter
    arbiter_4ch : entity work.rr_arbiter_41
        generic map ( DWIDTH => g_coarse_bits + 11 )
        port map (
            empty_in    => buf_arb_empty_s,
            valid_in    => buf_arb_rvalid_s,
            data_in     => buf_arb_data_s,
            enable_out  => arb_buf_ren_s,
            clk         => clk0,
            rst         => reset_s,
            data_out    => data_o,
            valid_out   => valid_o
        );

end Behavioral;
