----------------------------------------------------------------------------------
-- tapped_delay_line.vhd
----------------------------------------------------------------------------------
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;  -- CARRY8 primitive

entity tapped_delay_line is
    generic(
        -- Number of CARRY8 elements
        n_carries   : positive  := 64
        -- X and Y offsets for precise location of CARRY elements
        --Xoff        : integer   :=0;
        --Yoff        : integer   :=0
    );
    port(
        clk_i        : in std_logic; -- high frequency clock used for logic operation, e.g. coarse counter + latching
        reset_i      : in std_logic;
        signal_i     : in std_logic; -- input signal (hits from a single channel)
        taps_o       : out std_logic_vector(31 downto 0)
        --taps_o       : out std_logic_vector(8*n_carries-1 downto 0)  -- TDC converter output, to be converted to binary
        -- to debug the design in hardware, assign these as outputs which will be wired directly to PMOD outputs
        --oTap_0       : out std_logic;
        --oTap_1       : out std_logic;
        --oTap_2       : out std_logic;
        --oTap_3       : out std_logic;
        --oTap_4       : out std_logic;
        --oTap_5       : out std_logic;
        --oTap_6       : out std_logic;
        --oTap_7       : out std_logic;
        --oTap_8       : out std_logic
    );
end entity;

architecture arch of tapped_delay_line is 
-- don't let vivado remove any primitives
--attribute loc : string;
attribute keep_hierarchy : string;
attribute keep_hierarchy of arch : architecture is "true";
attribute dont_touch : string;
attribute dont_touch of arch : architecture is "yes";

-- internal signals 
signal unreg    : std_logic_vector(8*n_carries-1 downto 0); 
signal reg      : std_logic_vector(8*n_carries-1 downto 0);
signal taps     : std_logic_vector(8*n_carries-1 downto 0);
--signal os       : std_logic_vector(8*n_carries-1 downto 0); -- just use to collect the "O" outputs of CARRY8

begin
    -- Generate the carry chain
    -- The first CARRY8 gets fed the information directly from the LVDS/ECL channel:
    carry8chain: for i in 0 to n_carries-1 generate
        first_carry8: if i = 0 generate
            -- choose position
            --attribute LOC OF delay_line : label is "SLICE_X"&integer'image(Xoff)&"Y"&integer'image(Yoff+i);
            --begin 
            delay_line: CARRY8 
            generic map(
                CARRY_TYPE => "SINGLE_CY8" -- 8-bit or dual 4-bit carry (DUAL_CY4, SINGLE_CY8)
            )
            port map(
                CI      => signal_i,
                CI_TOP  => '0', -- Upper carry input when CARRY_TYPE=DUAL_CY4. Tie to ground if CARRY_TYPE=SINGLE_CY8.
                CO      => unreg(7 downto 0),
                DI      => "00000000",
                --O       => os(7 downto 0),
                S       => "11111111"
            );
        end generate;
        next_carry8s: if i > 0 generate
            --attribute loc of delay_line : label is "SLICE_X"&integer'image(Xoff)&"Y"&integer'image(Yoff+i);
            --begin 
            delay_line: CARRY8 
            generic map(
                CARRY_TYPE => "SINGLE_CY8"
            )
            port map(
                CI      => unreg(8*i-1),
                CI_TOP  => '0',
                CO      => unreg(8*(i+1)-1 downto 8*i),
                DI      => "00000000",
                --O       => os(8*(i+1)-1 downto 8*i),
                S       => "11111111"
            );
        end generate;
    end generate;
    
    -- Double-latch the output for stability
    -- Use D Flip-Flop with Synchronous Reset % clock enable (FDRE)
    latch: for j in 0 to 8*n_carries-1 generate
        FDR1: FDRE
            generic map(
                INIT => '0'
            )
            port map (
                C => clk_i,
                CE => '1',
                R => reset_i,
                D => unreg(j),
                Q => reg(j)
            );
        FDR2: FDRE
            generic map(
                INIT => '0'
            )
            port map (
                C => clk_i,
                CE => '1',
                R => reset_i,
                D => reg(j),
                Q => taps(j)
            );
    end generate;

    
    taps_o <= taps(31 downto 0);     -- in the real design this would be sent to encoder, hit detector, etc
    -- for debug, send these to PMOD outputs
    --oTap_0 <= taps(0);              -- first tap in chain
    --oTap_1 <= taps(8*n_carries-1);   -- last tap in chain
    --oTap_0 <= os(0);
    --oTap_1 <= os(8*n_carries-1);
    
--    oTap_0 <= taps(0);                  -- first tap
--    oTap_1 <= taps(1*n_carries-1);      -- 64th tap
--    oTap_2 <= taps(2*n_carries-1);
--    oTap_3 <= taps(3*n_carries-1);
--    oTap_4 <= taps(4*n_carries-1);
--    oTap_5 <= taps(5*n_carries-1);
--    oTap_6 <= taps(6*n_carries-1);
--    oTap_7 <= taps(7*n_carries-1);
--    oTap_8 <= taps(8*n_carries-1);      -- 512th tap
    
end architecture;
