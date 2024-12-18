----------------------------------------------------------------------------------
-- 16-channel TDC block
--
-- TDC_4ch -> 4-hit pipeline \
-- TDC_4ch -> 4-hit pipeline  \___________ Arbiter
-- TDC_4ch -> 4-hit pipeline  /
-- TDC_4ch -> 4-hit pipeline /
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.common_types.all;

entity TDC_16ch is
    generic (
        g_chID_start   : natural := 0;
        g_coarse_bits  : natural := 28;
        g_sat_duration : natural := 3;
        g_pipe_depth   : natural := 5
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
        hit     : in std_logic_vector(0 to 15);
        -- Data outputs (timestamp + valid) from arbiter
        valid_o : out std_logic;
        data_o  : out std_logic_vector(g_coarse_bits+10 downto 0)
    );
end TDC_16ch;

architecture Behavioral of TDC_16ch is
    -------------------------------------------------
    -- Signal naming conventions:
    --      from_to_purpose_s
    -------------------------------------------------
    type int_array is array(0 to 3) of integer;
    -- Signals from 4ch TDC module -> ring buffers
    signal tdc_buf_data_s  : slv39_array(0 to 3);
    signal tdc_buf_valid_s : std_logic_vector(0 to 3);
    -- Signals between ring buffers and arbiter.
    signal arb_buf_ren_s       : std_logic_vector(0 to 3);
    signal buf_arb_rvalid_s    : std_logic_vector(0 to 3);
    signal buf_arb_data_s      : slv39_array(0 to 3);
    signal buf_arb_empty_s     : std_logic_vector(0 to 3);
    signal buf_arb_emptyNext_s : std_logic_vector(0 to 3);
    signal buf_arb_full_s      : std_logic_vector(0 to 3);
    signal buf_arb_fullNext_s  : std_logic_vector(0 to 3);
    signal buf_arb_fillCount_s : int_array;

begin

    -- Instantiate TDC channels. The channel IDs obey the following algorithm:
    -- ------------------------------------
    -- channels    | ch  | calculation 
    -- ------------------------------------
    -- 0  1  2  3  |  0  | 0 + (4*0) = 0    \
    -- 4  5  6  7  |  1  | 0 + (4*1) = 4     \___________ 16 channels starting with g_chID_start => 0
    -- 8  9  10 11 |  2  | 0 + (4*2) = 8     /
    -- 12 13 14 15 |  3  | 0 + (4*3) = 12   /
    --
    -- 16 17 18 19 |  0  | 16 + (4*0) = 16  \
    -- 20 21 22 23 |  1  | 16 + (4*1) = 20   \___________ 16 channels starting with g_chID_start => 16
    -- 24 25 26 27 |  2  | 16 + (4*2) = 24   /
    -- 28 29 30 31 |  3  | 16 + (4*3) = 28  /
    --
    -- The below loop generates the first value in each row. The TDC_4ch modules 
    -- have their own generate loop that loops again 0->3 but gives the channels IDs 
    -- by g_chID_start + ch.
    TDC_4chs : for ch in 0 to 3 generate
    begin 
        TDC_4ch_inst : entity work.TDC_4ch
            generic map (
                g_chID_start   => g_chID_start + (4 * ch), 
                g_sat_duration => g_sat_duration,
                g_coarse_bits  => g_coarse_bits,
                g_pipe_depth   => g_pipe_depth
            )
            port map (
                clk0      => clk0,
                clk45     => clk45,
                clk90     => clk90,
                clk135    => clk135,
                clk_sys   => clk_sys,
                reset     => reset,
                enable    => enable, 
                hit       => hit( (4*ch) to (4*ch+3) ),
                valid_o   => tdc_buf_valid_s(ch),
                data_o    => tdc_buf_data_s(ch)
            );
        TDC_4ch_buf_inst : entity work.ring_buffer
            generic map (
                RAM_WIDTH => g_coarse_bits + 11,
                RAM_DEPTH => g_pipe_depth
            )
            port map (
                clk             => clk0,
                rst             => reset, 
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
    end generate TDC_4chs;

    -- connect ring buffers to arbiter
    arbiter_16ch : entity work.rr_arbiter_41
        generic map ( DWIDTH => g_coarse_bits + 11 )
        port map (
            empty_in    => buf_arb_empty_s,
            valid_in    => buf_arb_rvalid_s,
            data_in     => buf_arb_data_s,
            enable_out  => arb_buf_ren_s,
            clk         => clk0,
            rst         => reset,
            data_out    => data_o,
            valid_out   => valid_o
        );

end Behavioral;
