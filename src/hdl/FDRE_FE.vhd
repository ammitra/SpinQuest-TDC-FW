-- Flip-Flop with
-- Falling-edge Clock
-- Active-high Synchronous Clear
-- Active-high Clock Enable

library IEEE;
use IEEE.std_logic_1164.all;

entity FDRE_FE is
port(
    C   : in std_logic;
    CE  : in std_logic;
    D   : in std_logic;
    Q   : out std_logic;
    R   : in std_logic
);
end entity FDRE_FE;

architecture rtl of FDRE_FE is
begin
    process(C) is
    begin
        if falling_edge(C) then
            if R = '1' then
                Q <= '0';
            elsif CE = '1' then
                Q <= D;
            end if;
        end if;
    end process;
end architecture rtl;
