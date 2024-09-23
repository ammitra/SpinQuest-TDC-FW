-----------------------------------------------------------------------------------
-- sampler.vhd
--
-- Uses four rising and four falling edge FFs to sample the arrival time of a hit
-- to within one of 32 0.58ns intervals within an RF clock period.
--
-- V0: 23/09/2024
--  * first version, passed behavioral simulation tests
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity sampler is
    port (
        -- TDC and system clocks 
        clk0 : in std_logic;    -- 0 degree (212.4 MHz, 4x RF clock)
        clk1 : in std_logic;    -- 45 degree
        clk2 : in std_logic;    -- 90 degree
        clk3 : in std_logic;    -- 135 degree
        clk_RF : in std_logic;  -- 53.1 MHz
        -- Control 
        reset_i  : in std_logic;    -- active high
        enable_i : in std_logic;    -- active high
        -- Data input
        hit_i : in std_logic;
        -- Data output (to encoder)
        data_o  : out std_logic_vector(9 downto 0) -- 8-bit hit pattern + 2-bit fine counter
    );
end sampler;

architecture Behavioral of sampler is
    ---------------------------------------------------------------------------
    -- PRIMITIVES
    ---------------------------------------------------------------------------
	-- LUT1 primitives for hit signal routing
	component LUT1
		generic (
			INIT : bit_vector := "10"
		);
		port (
			I0	: in std_logic;
			O 	: out std_logic
		);
	end component;
	-- FDCE primitives for sampling and clock domain transfer
    component FDCE
        generic(
            INIT : bit := '0';           -- Initial value of Q
            IS_C_INVERTED : bit := '0';  -- 0: positive edge
            IS_D_INVERTED : bit := '0';  -- 0: active high
            IS_CLR_INVERTED : bit := '0' -- 0: active high
        );
        port(
            C   : in std_logic;  -- Clock input
            CE  : in std_logic;  -- Active high register clock enable
            CLR : in std_logic;  -- Asynchronous clear.
            D   : in std_logic;  -- Data input
            Q   : out std_logic  -- Data output
        );
    end component;
    
    ---------------------------------------------------------------------------
    -- SIGNALS
    ---------------------------------------------------------------------------
    -- Signals for hit routing (branching structure using LUTs)
	signal b0_out  : std_logic;    -- from b0 LUT -> b1A, b1B
	signal b1A_out : std_logic;    -- from b1A -> b2A, b2B
	signal b1B_out : std_logic;    -- from b1B -> b2C, b2D
	signal b2A_out : std_logic;    -- from b2A -> ff0RE, ff0FE
	signal b2B_out : std_logic;    -- from b2B -> ff1RE, ff1FE
	signal b2C_out : std_logic;    -- from b2C -> ff2RE, ff2FE
	signal b2D_out : std_logic;    -- from b2D -> ff3RE, ff3FE
	-- Signals for latching on the rising and falling edges of the four clocks
	signal register_rising  : std_logic_vector(3 downto 0);
	signal register_falling : std_logic_vector(3 downto 0);
	-- Signal for latching everything to 0 degree domain (rising edge)
	signal register_cdc : std_logic_vector(7 downto 0);
	-- Signals for fine counter which counts number of fast periods in an RF period
	signal shift_reg  : std_logic_vector(3 downto 0) := (others => '0');
	signal shift_lst  : std_logic_vector(3 downto 0) := (others => '0');
	signal toggle     : std_logic := '0';
	signal startup_true : std_logic := '0';
	signal clk0_count : unsigned(1 downto 0) := (others => '0'); -- clk0 will be 4x faster than RF (coarse) clock
	
begin

	-------------------------------------------------------
	-- Hit signal routing LUTs
	-------------------------------------------------------
	b0 : LUT1      -- Goes to b1A and b1B
	generic map (INIT => "10") port map (I0 => hit_i, O => b0_out);
	b1_A : LUT1    -- Goes to b2A, b2B
	generic map (INIT => "10") port map (I0 => b0_out,O => b1A_out);
	b1_B : LUT1    -- goes to b2C, b2D
	generic map (INIT => "10") port map (I0 => b0_out,O => b1B_out);
	b2_A : LUT1    -- goes to ff0RE, ff0FE
	generic map (INIT => "10") port map (I0 => b1A_out, O => b2A_out);
	b2_B : LUT1    -- goes to ff1RE, ff1FE
	generic map (INIT => "10") port map (I0 => b1A_out, O => b2B_out);
	b2_C : LUT1    -- goes to ff2RE, ff2FE
	generic map (INIT => "10") port map (I0 => b1B_out, O => b2C_out);
	b2_D : LUT1    -- goes to ff3RE, ff3FE
	generic map (INIT => "10") port map (I0 => b1B_out, O => b2D_out);

	-------------------------------------------------------
	-- First stage sampling FFs
	-------------------------------------------------------
	ff_clk0_re : entity work.FDRE_RE   -- rising edge of clk0
    port map (
        C  => clk0,
        CE => enable_i, 
        D  => b2A_out,
        Q  => register_rising(3),
        R  => reset_i
    );
    ff_clk0_fe : entity work.FDRE_FE    -- falling edge of clk0
    port map (
        C  => clk0,
        CE => enable_i, 
        D  => b2A_out,
        Q  => register_falling(3),
        R  => reset_i
    );
    -------------------------------------------------------------
	ff_clk1_re : entity work.FDRE_RE   -- rising edge of clk1
    port map (
        C  => clk1,
        CE => enable_i, 
        D  => b2B_out,
        Q  => register_rising(2),
        R  => reset_i
    );
    ff_clk1_fe : entity work.FDRE_FE    -- falling edge of clk1
    port map (
        C  => clk1,
        CE => enable_i, 
        D  => b2B_out,
        Q  => register_falling(2),
        R  => reset_i
    );
    -------------------------------------------------------------
	ff_clk2_re : entity work.FDRE_RE   -- rising edge of clk2
    port map (
        C  => clk2,
        CE => enable_i, 
        D  => b2C_out,
        Q  => register_rising(1),
        R  => reset_i
    );
    ff_clk2_fe : entity work.FDRE_FE    -- falling edge of clk2
    port map (
        C  => clk2,
        CE => enable_i, 
        D  => b2C_out,
        Q  => register_falling(1),
        R  => reset_i
    );
    -------------------------------------------------------------
	ff_clk3_re : entity work.FDRE_RE   -- rising edge of clk3
    port map (
        C  => clk3,
        CE => enable_i, 
        D  => b2D_out,
        Q  => register_rising(0),
        R  => reset_i
    );
    ff_clk3_fe : entity work.FDRE_FE    -- falling edge of clk3
    port map (
        C  => clk3,
        CE => enable_i, 
        D  => b2D_out,
        Q  => register_falling(0),
        R  => reset_i
    );
    
	--------------------------------------------------------------------
	-- FFs to bring all RE/FE samples to 0degree domain (on rising edge).
	-- This part might really be difficult to meet timing constraints given
	-- that the ff_clk3_fe signal will only have 1/8 of a fast clock period 
	-- to be latched in. 
	-- One alternative is to have a second array of (RE-triggered) FFs 
	-- that are clocked by clk0,clk0,clk2,clk3 before finally latching everything
	-- in with the four clk0 (RE) flip flops. This gives setup times of 
	-- 2.3ns, 1.76ns, 2.3ns, and 2.3ns (NEED TO CHECK IMPLEMENTATION)
	--------------------------------------------------------------------
	p_latch_cdc : process(clk0, reset_i)
	begin 
        if rising_edge(clk0) then 
            if reset_i = '1' then
                register_cdc <= (others => '0');
            else
                register_cdc(7 downto 4) <= register_rising;    -- rising edges are 4 MSBs
                register_cdc(3 downto 0) <= register_falling;   -- falling edges are 4 LSBs
            end if;
        end if;
	end process p_latch_cdc;
	
	-- Connect the cdc register to the data output port. 4 LSBs will be the fine counter
    data_o <= register_cdc & std_logic_vector(clk0_count);
    
    -- on the rising edge of the RF clock, set a toggle for resetting the fast counter
    p_toggle : process(clk_RF)
    begin 
        if rising_edge(clk_RF) then 
            toggle <= not toggle;
        end if;
    end process p_toggle;
    
    -- fine counter logic to determine during which of the four fast periods that make up a coarse period the hit arrived 
    p_fine_count : process(clk0)
    begin 
        if rising_edge(clk0) then 
            -- check to see if shift register changed. If not, then fast clocks haven't started yet - do not start counter
            shift_lst <= shift_reg;
            if shift_lst = shift_reg then 
                clk0_count <= (others => '0');
                startup_true <= '1';
            else
                -- check if we have the startup condition, otherwise run normally 
                if startup_true = '1' then 
                    -- Detect a clock edge in the RF clock domain 3 cycles ago, using the last shift register
                    if (shift_lst(shift_lst'high) XOR shift_lst(shift_reg'high-1)) = '1' then 
                        clk0_count <= (others => '0');
                    else 
                        clk0_count <= clk0_count +1;
                    end if;
                else
                    -- Detect a clock edge in the RF clock domain 3 cycles ago
                    if (shift_reg(shift_reg'high) XOR shift_reg(shift_reg'high-1)) = '1' then 
                        -- since the fast clk_0 is generated from the MMCM using clk_sys as input, the edges will always be aligned and this will always run 
                        clk0_count <= (others => '0');
                    else 
                        clk0_count <= clk0_count + 1;
                    end if;
                end if;
            end if;
            shift_reg <= shift_reg(shift_reg'high-1 downto 0) & toggle;
        end if;
    end process p_fine_count;
	
end Behavioral;

