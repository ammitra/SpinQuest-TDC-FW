-----------------------------------------------------------------------------------
-- sampler.vhd
--
-- Uses four rising and four falling edge FFs to sample the arrival time of a hit
-- to within one of 32 0.58ns intervals within an RF clock period.
--
-- V0: 23/09/2024
--  * first version, passed behavioral simulation tests
-- V0.1 09/12/2024
--  * added second layer of sampling FFs to meet timing constraints on clks90,135 FE
--  * calculate true hit fine time period and send it in data output
-- V0.2 17/12/2024
--  * use Xilinx FDRE primitives for rising/falling edge sampling DFFs
--  * manual placement of sampling + synchronization DFFs using RLOC
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
    -- Preserve architecture
    attribute keep_hierarchy : string;
    attribute keep : string;
    attribute dont_touch : string;
    attribute rloc : string;
    attribute keep_hierarchy of Behavioral : architecture is "true";
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
	-- FDRE primitives for sampling and clock domain transfer 
	component FDRE
        generic (
           INIT          : bit := '0'; -- Initial value of register, '0', '1'
           IS_C_INVERTED : bit := '0'; -- Optional inversion for C
           IS_D_INVERTED : bit := '0'; -- Optional inversion for D
           IS_R_INVERTED : bit := '0'  -- Optional inversion for R
        );
        port (
           Q  : out std_logic;   -- 1-bit output: Data
           C  : in std_logic;   -- 1-bit input: Clock
           CE : in std_logic; -- 1-bit input: Clock enable
           D  : in std_logic;   -- 1-bit input: Data
           R  : in std_logic    -- 1-bit input: Synchronous reset
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
    attribute keep of b0_out  : signal is "true";
    attribute keep of b1A_out : signal is "true";
    attribute keep of b1B_out : signal is "true";
    attribute keep of b2A_out : signal is "true";
    attribute keep of b2B_out : signal is "true";
    attribute keep of b2C_out : signal is "true";
    attribute keep of b2D_out : signal is "true";
    attribute dont_touch of b0_out  : signal is "true";
    attribute dont_touch of b1A_out : signal is "true";
    attribute dont_touch of b1B_out : signal is "true";
    attribute dont_touch of b2A_out : signal is "true";
    attribute dont_touch of b2B_out : signal is "true";
    attribute dont_touch of b2C_out : signal is "true";
    attribute dont_touch of b2D_out : signal is "true";
	-- Signals for latching on the rising and falling edges of the four clocks
	signal register_rising  : std_logic_vector(3 downto 0);
	signal register_falling : std_logic_vector(3 downto 0);
	signal register_rising_ss  : std_logic_vector(3 downto 0);
	signal register_falling_ss : std_logic_vector(3 downto 0);
    attribute keep of register_rising : signal is "true";
    attribute keep of register_falling : signal is "true";
    attribute keep of register_rising_ss : signal is "true";
    attribute keep of register_falling_ss : signal is "true";
	signal register_cdc : std_logic_vector(7 downto 0);
	attribute keep of register_cdc : signal is "true";
	-- Signals for fine counter which counts number of fast periods in an RF period
	signal shift_reg  : std_logic_vector(3 downto 0) := (others => '0');
	signal shift_lst  : std_logic_vector(3 downto 0) := (others => '0');
	signal toggle     : std_logic := '0';
	signal startup_true : std_logic := '0';
	signal clk0_count : unsigned(1 downto 0) := (others => '0'); -- clk0 will be 4x faster than RF (coarse) clock
	signal clk0_count_store : unsigned(1 downto 0) := (others => '0');    -- store the clk0 count at time of hit arrival
    signal hit_last : std_logic;
    attribute keep of shift_reg : signal is "true";
    attribute keep of shift_lst : signal is "true";
    attribute keep of toggle : signal is "true";
    attribute keep of startup_true : signal is "true";
    attribute keep of clk0_count : signal is "true";
    attribute keep of clk0_count_store : signal is "true";
    attribute keep of hit_last : signal is "true";
    
    -- manual placement of hit signal routing LUTs
    attribute rloc of b2_A : label is "X8Y156";
    attribute rloc of b2_B : label is "X8Y155";
    attribute rloc of b1_A : label is "X8Y154";
    attribute rloc of b0   : label is "X8Y153";
    attribute rloc of b1_B : label is "X8Y152";
    attribute rloc of b2_C : label is "X8Y151";
    attribute rloc of b2_D : label is "X8Y150";
    -- manual placement of sampling DFFs
    attribute rloc of ff_clk0_re : label is "X9Y155"; 
    attribute rloc of ff_clk0_fe : label is "X9Y155"; 
    attribute rloc of ff_clk1_re : label is "X9Y154"; 
    attribute rloc of ff_clk1_fe : label is "X9Y154"; 
    attribute rloc of ff_clk2_re : label is "X9Y153"; 
    attribute rloc of ff_clk2_fe : label is "X9Y153"; 
    attribute rloc of ff_clk3_re : label is "X9Y152"; 
    attribute rloc of ff_clk3_fe : label is "X9Y152"; 
    -- manual placement of CDC register FFs
    attribute rloc of ff_ss_clk_0re_0re : label is "X10Y155"; 
    attribute rloc of ff_ss_clk_0fe_0re : label is "X10Y155"; 
    attribute rloc of ff_ss_clk_45re_0re : label is "X10Y154"; 
    attribute rloc of ff_ss_clk_45fe_0re : label is "X10Y154"; 
    attribute rloc of ff_ss_clk_90re_0re : label is "X10Y153"; 
    attribute rloc of ff_ss_clk_90fe_90re : label is "X10Y153"; 
    attribute rloc of ff_ss_clk_135re_0re : label is "X10Y152"; 
    attribute rloc of ff_ss_clk_135fe_90re : label is "X10Y152"; 
    

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
	ff_clk0_re : FDRE
	generic map (
       INIT => '0',          -- Initial value of register, '0', '1'
       IS_C_INVERTED => '0'  -- Optional inversion for C
	)
	port map (
       Q  => register_rising(3),    -- 1-bit output: Data
       C  => clk0,                  -- 1-bit input: Clock
       CE => enable_i,              -- 1-bit input: Clock enable
       D  => b2A_out,               -- 1-bit input: Data
       R  => reset_i                -- 1-bit input: Synchronous reset
	);
	ff_clk0_fe : FDRE
	generic map (
       INIT => '0',          -- Initial value of register, '0', '1'
       IS_C_INVERTED => '1'  -- Optional inversion for C
	)
	port map (
       Q  => register_falling(3),   -- 1-bit output: Data
       C  => clk0,                  -- 1-bit input: Clock
       CE => enable_i,              -- 1-bit input: Clock enable
       D  => b2A_out,               -- 1-bit input: Data
       R  => reset_i                -- 1-bit input: Synchronous reset
	);
	
	ff_clk1_re : FDRE
	generic map (
       INIT => '0',          -- Initial value of register, '0', '1'
       IS_C_INVERTED => '0'  -- Optional inversion for C
	)
	port map (
       Q  => register_rising(2),    -- 1-bit output: Data
       C  => clk1,                  -- 1-bit input: Clock
       CE => enable_i,              -- 1-bit input: Clock enable
       D  => b2B_out,               -- 1-bit input: Data
       R  => reset_i                -- 1-bit input: Synchronous reset
	);
	ff_clk1_fe : FDRE
	generic map (
       INIT => '0',          -- Initial value of register, '0', '1'
       IS_C_INVERTED => '1'  -- Optional inversion for C
	)
	port map (
       Q  => register_falling(2),   -- 1-bit output: Data
       C  => clk1,                  -- 1-bit input: Clock
       CE => enable_i,              -- 1-bit input: Clock enable
       D  => b2B_out,               -- 1-bit input: Data
       R  => reset_i                -- 1-bit input: Synchronous reset
	);
	
	ff_clk2_re : FDRE
	generic map (
       INIT => '0',          -- Initial value of register, '0', '1'
       IS_C_INVERTED => '0'  -- Optional inversion for C
	)
	port map (
       Q  => register_rising(1),    -- 1-bit output: Data
       C  => clk2,                  -- 1-bit input: Clock
       CE => enable_i,              -- 1-bit input: Clock enable
       D  => b2C_out,               -- 1-bit input: Data
       R  => reset_i                -- 1-bit input: Synchronous reset
	);
	ff_clk2_fe : FDRE
	generic map (
       INIT => '0',          -- Initial value of register, '0', '1'
       IS_C_INVERTED => '1'  -- Optional inversion for C
	)
	port map (
       Q  => register_falling(1),   -- 1-bit output: Data
       C  => clk2,                  -- 1-bit input: Clock
       CE => enable_i,              -- 1-bit input: Clock enable
       D  => b2C_out,               -- 1-bit input: Data
       R  => reset_i                -- 1-bit input: Synchronous reset
	);
	
	ff_clk3_re : FDRE
	generic map (
       INIT => '0',          -- Initial value of register, '0', '1'
       IS_C_INVERTED => '0'  -- Optional inversion for C
	)
	port map (
       Q  => register_rising(0),    -- 1-bit output: Data
       C  => clk3,                  -- 1-bit input: Clock
       CE => enable_i,              -- 1-bit input: Clock enable
       D  => b2D_out,               -- 1-bit input: Data
       R  => reset_i                -- 1-bit input: Synchronous reset
	);
	ff_clk3_fe : FDRE
	generic map (
       INIT => '0',          -- Initial value of register, '0', '1'
       IS_C_INVERTED => '1'  -- Optional inversion for C
	)
	port map (
       Q  => register_falling(0),   -- 1-bit output: Data
       C  => clk3,                  -- 1-bit input: Clock
       CE => enable_i,              -- 1-bit input: Clock enable
       D  => b2D_out,               -- 1-bit input: Data
       R  => reset_i                -- 1-bit input: Synchronous reset
	);
	
	-------------------------------------------------------
	-- Second stage sampling FFs.
	-- These FFs will be connected to the CDC register that 
	-- takes everything to the clk0 domain. This means that 
	-- full encoding takes 1cc longer than before and so the 
	-- encoding algorithm must be changed.
	-- Naming convention:
	--     ff_ss_clk_[from clk]_[to clk]
	-------------------------------------------------------
    ff_ss_clk_0re_0re : FDRE         -- clk0 RE -> clk0 RE           (1 clk0 pd setup/hold = 4.7ns)
	generic map (
       INIT => '0', 
       IS_C_INVERTED => '0'
	)
    port map (
        C  => clk0,
        CE => enable_i, 
        D  => register_rising(3),
        Q  => register_rising_ss(3),
        R  => reset_i
    );
    ff_ss_clk_0fe_0re : FDRE         -- clk0 FE -> clk0 RE           (4/8 clk0 pd s/h = 2.3ns)
	generic map (
       INIT => '0', 
       IS_C_INVERTED => '0'
	)
    port map (
        C  => clk0,
        CE => enable_i, 
        D  => register_falling(3),
        Q  => register_falling_ss(3),
        R  => reset_i
    );
    ff_ss_clk_45re_0re : FDRE         -- clk45 RE -> clk0 RE          (7/8 clk0 pd s/h = 4.1ns)
	generic map (
       INIT => '0', 
       IS_C_INVERTED => '0'
	)
    port map (
        C  => clk0,
        CE => enable_i, 
        D  => register_rising(2),
        Q  => register_rising_ss(2),
        R  => reset_i
    );
    ff_ss_clk_45fe_0re : FDRE         -- clk45 FE -> clk0 RE          (3/8 clk0 pd s/h = 1.74ns)
	generic map (
       INIT => '0', 
       IS_C_INVERTED => '0'
	)
    port map (
        C  => clk0,
        CE => enable_i, 
        D  => register_falling(2),
        Q  => register_falling_ss(2),
        R  => reset_i
    );
    ff_ss_clk_90re_0re : FDRE         -- clk90 RE -> clk0 RE          (6/8 clk0 pd s/h = 3.5ns)
	generic map (
       INIT => '0', 
       IS_C_INVERTED => '0'
	)
    port map (
        C  => clk0,
        CE => enable_i, 
        D  => register_rising(1),
        Q  => register_rising_ss(1),
        R  => reset_i
    );
    ff_ss_clk_90fe_90re : FDRE         -- clk90 FE -> **clk90 RE**     (4/8 clk0 pd s/h = 2.3ns)
	generic map (
       INIT => '0', 
       IS_C_INVERTED => '0'
	)
    port map (
        C  => clk2, -- 90 degree clk RE
        CE => enable_i, 
        D  => register_falling(1),
        Q  => register_falling_ss(1),
        R  => reset_i
    );
    ff_ss_clk_135re_0re : FDRE         -- clk135 RE -> clk0 RE         (5/8 clk0 pd s/h = 2.9ns)
	generic map (
       INIT => '0', 
       IS_C_INVERTED => '0'
	)
    port map (
        C  => clk0,
        CE => enable_i, 
        D  => register_rising(0),
        Q  => register_rising_ss(0),
        R  => reset_i
    );
    ff_ss_clk_135fe_90re : FDRE         -- clk135 FE -> **clk90 RE**    (3/8 clk0 pd s/h = 1.74 ns)
	generic map (
       INIT => '0', 
       IS_C_INVERTED => '0'
	)
    port map (
        C  => clk2, -- 90 degree clk RE
        CE => enable_i, 
        D  => register_falling(0),
        Q  => register_falling_ss(0),
        R  => reset_i
    );
    
	--------------------------------------------------------------------
	-- FFs to bring all RE/FE samples to 0degree domain from the second
	-- stage (SS) registers.
	--------------------------------------------------------------------
	p_latch_cdc : process(all)
	begin 
        if rising_edge(clk0) then 
            if reset_i = '1' then
                register_cdc <= (others => '0');
            else
                register_cdc(7 downto 4) <= register_rising_ss;    -- rising edges are 4 MSBs
                register_cdc(3 downto 0) <= register_falling_ss;   -- falling edges are 4 LSBs
            end if;
        end if;
	end process p_latch_cdc;
	
	-- Connect the cdc register to the data output port. 4 LSBs will be the fine counter
	-- Data output format: 8-bit hit pattern + 2-bit fine counter (0,1,2,3 representing hit arrival fine period)
    data_o <= register_cdc & std_logic_vector(clk0_count_store);
    
    -- on the rising edge of the RF clock, set a toggle for resetting the fast counter
    p_toggle : process(all)
    begin 
        if rising_edge(clk_RF) then 
            toggle <= not toggle;
        end if;
    end process p_toggle;
    
    -- on the rising edge of the clk0, store the last value of the hit 
    process(all)
    begin 
        if rising_edge(clk0) then 
            if reset_i = '1' then
                hit_last <= '0';
            else
                hit_last <= hit_i;
            end if;
        end if;
    end process;
    
    -- On the rising edge of the RF clock, latch in the fine clk0 counter value when a hit arrives.
    -- Since there are two CDC stages before everything gets shifted to the clk0 domain, there are 
    -- enough CCs for this value to stabilize before the 10-bit data is sent out. Therefore, there 
    -- is no need to correct it on the encoder end - the encoder can use the result as-is.
    p_store_clk0 : process(all)
    begin 
        if rising_edge(clk0) then 
            if reset_i = '1' then 
                clk0_count_store <= (others => '0');
            else
                if (hit_last = '0') and (hit_i = '1') then 
                    clk0_count_store <= clk0_count;
                end if;
            end if;
        end if;
    end process p_store_clk0;
    
    -- fine counter logic to determine during which of the four fast periods that make up a coarse period the hit arrived 
    p_fine_count : process(all)
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

