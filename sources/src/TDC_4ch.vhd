-------------------------------------------------------------------------------------------------------------------------------------
--! \file TDC_4ch.vhd
--! \brief A group of four TDC channels writing data to buffer FIFOs, whose data streams are serialized by a 4:1 round robin arbiter.
--!
--! \details This module contains four single \ref TDC_channel "`TDC_channel`" modules whose outputs are connected to intermediate 
--! ring buffers to store a record of valid hits. The ring buffers are read out by the \ref rr_arbiter_41.vhd "4:1 arbiter" in round
--! robin priority for further processing. A block diagram of the model can be found below.
--! 
--! \verbatim
--! ```
--! TDC channel -> ring buffer -|
--! TDC channel -> ring buffer -|_______ arbiter
--! TDC channel -> ring buffer -|
--! TDC Channel -> ring buffer -|
--! ```
--! \endverbatim
--! 
--! \author Amitav Mitra, amitra3@jhu.edu
-------------------------------------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--! Use arrays of SLVs for the ring buffer in/outputs
use work.common_types.all;


--! \brief A group of four TDC channels writing data to buffer FIFOs, whose data streams are serialized by a 4:1 round robin arbiter.
--!
--! \details This module contains four single \ref TDC_channel "`TDC_channel`" modules whose outputs are connected to intermediate 
--! ring buffers to store a record of valid hits. The ring buffers are read out by the \ref rr_arbiter_41.vhd "4:1 arbiter" in round
--! robin priority for further processing. A block diagram of the model can be found below.
--! 
--! \verbatim
--! TDC channel -> ring buffer -|
--! TDC channel -> ring buffer -|_______ arbiter
--! TDC channel -> ring buffer -|
--! TDC Channel -> ring buffer -|
--! \endverbatim
entity TDC_4ch is
    generic (
        g_chID_start   : natural := 0;  --! Channel ID of the first TDC channel. A for loop assigns the next three channels' IDs starting from `g_chID_start`
        g_coarse_bits  : natural := 28; --! Number of bits in the \ref CoarseCounter.vhd "coarse counter"
        g_sat_duration : natural := 3;  --! Minimum duration (in clk0 periods) that hit must remain high to be considered valid
        g_pipe_depth   : natural := 5   --! Max number of hits stored in intermediate ring buffer pipeline
    );
    port (
        -- TDC and system clocks sent to all 4 channels
        clk0    : in std_logic; --! 0 degree (212.4 MHz, 4x RF) clock
        clk45   : in std_logic; --! 45 degree clock
        clk90   : in std_logic; --! 90 degree clock
        clk135  : in std_logic; --! 135 degree clock
        clk_sys : in std_logic; --! RF clock (53.1 MHz)
        -- Control 
        reset   : in std_logic; --! Active high reset
        enable  : in std_logic; --! Active high enable
        -- Data input from detector
        hit     : in std_logic_vector(0 to 3);  --! Front-end discriminator hits
        -- Data outputs (timestamp + valid) from arbiter
        valid_o : out std_logic;                                    --! Write enable pulse sent from arbiter downstream
        data_o  : out std_logic_vector(g_coarse_bits+10 downto 0)   --! Timestamp data from FIFOs
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
    signal tdc_buf_data_s  : SlvArray(0 to 3)(g_coarse_bits+10 downto 0);       --! [TDC channel -> ring buffer] SLV array with each channels' digitized hit data
    signal tdc_buf_valid_s : std_logic_vector(0 to 3);                          --! [TDC channel -> ring buffer] SLV with each channels' data valid flag to be sent to ring buffer write enable

    -- Signals between ring buffers and arbiter.
    signal arb_buf_ren_s       : std_logic_vector(0 to 3);                      --! [arbiter -> ring buffer] SLV to issue ring buffers readout grants from the arbiter
    signal buf_arb_rvalid_s    : std_logic_vector(0 to 3);                      --! [ring buffer -> arbiter] SLV to issue readout valid flags from the buffer to arbiter
    signal buf_arb_data_s      : SlvArray(0 to 3)(g_coarse_bits+10 downto 0);   --! [ring buffer -> arbiter] SLV array with each buffers' exposed digitized hit data
    signal buf_arb_empty_s     : std_logic_vector(0 to 3);                      --! [ring buffer -> arbiter] SLV containing empty status of all TDC channels' hit buffers
    signal buf_arb_emptyNext_s : std_logic_vector(0 to 3);                      --! UNUSED
    signal buf_arb_full_s      : std_logic_vector(0 to 3);                      --! UNUSED
    signal buf_arb_fullNext_s  : std_logic_vector(0 to 3);                      --! UNUSED
    signal buf_arb_fillCount_s : IntArray(0 to 3);                              --! UNUSED


begin

    --! Register the reset signal to avoid high fanout on the reset net
    p_RegRst : process(all)
    begin 
        if rising_edge(clk0) then 
            reset_s <= reset;
        end if;
    end process p_RegRst;

    
    tdc_channels : for ch in 0 to 3 generate
    begin
        --! Instantiate the four TDC channels
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
        --! Instantiate the intermediate hit buffer FIFOs reading from the TDC channels and writing to the arbiter
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

    --! Connect the 4 TDC channel ring buffers to the arbiter
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
