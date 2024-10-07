library ieee;
use ieee.std_logic_1164.all; 

package common_types is

    --type slv_array is array(integer range <>) of std_logic_vector;  -- requires VHDL 2008
    
    -- just hard code these, since unconstrained slv requires vhdl 2008 and vivado is a pain in the ass
    type slv39_array is array(integer range <>) of std_logic_vector(38 downto 0);
    type slv2_array is array(integer range <>) of std_logic_vector( 1 downto 0); 
    type int4_array is array(integer range <>) of integer range 0 to 4; 

end package;