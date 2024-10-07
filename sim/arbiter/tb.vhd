----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/02/2024 01:41:15 PM
-- Design Name: 
-- Module Name: tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.common_types.all;

entity tb is
--  Port ( );
end tb;

architecture Behavioral of tb is

  -- Procedure for clock generation
  procedure clk_gen(signal clk : out std_logic; constant FREQ : real; PHASE : time := 1 ns) is
    constant PERIOD    : time := 1 sec / FREQ;        -- Full period
    constant HIGH_TIME : time := PERIOD / 2;          -- High time
    constant LOW_TIME  : time := PERIOD - HIGH_TIME;  -- Low time; always >= HIGH_TIME
  begin
    -- Check the arguments
    assert (HIGH_TIME /= 0 fs) report "clk_plain: High time is zero; time resolution to large for frequency" severity FAILURE;
    -- initial phase shift 
    wait for PHASE;
    -- Generate a clock cycle
    loop
      clk <= '1';
      wait for HIGH_TIME;
      clk <= '0';
      wait for LOW_TIME;
    end loop;
  end procedure;
  
  signal clk : std_logic;
  signal din : slv2_array(0 to 3);
  signal data_valid : std_logic;
  signal rst : std_logic := '1';
  signal dout_2 : std_logic_vector(1 downto 0);
  
  
  -- FIFO signals 
  signal wr_ens : std_logic_vector(0 to 3) := (others => '0');
  signal wr_datas : slv2_array(0 to 3) := (others => (others => '0'));
  signal rd_ens : std_logic_vector(0 to 3);
  signal rd_valids : std_logic_vector(0 to 3);
  signal rd_datas : slv2_array(0 to 3);
  signal empties : std_logic_vector(0 to 3);
  signal empty_nexts : std_logic_vector(0 to 3);
  signal fulls : std_logic_vector(0 to 3);
  signal full_nexts : std_logic_vector(0 to 3);
  signal fill_counts : int4_array(0 to 3);
  
  
  constant tdc_pd : time := 1 sec / 212.400E6;
  
begin

    clk_gen(clk, 212.400E6, 0 ns);
    
    -- dummy FIFOs for the fake TDC channel hits 
    fifo0 : entity work.ring_buffer 
        generic map (
            RAM_WIDTH => 2,
            RAM_DEPTH => 4
        )
        port map (
            clk => clk,
            rst => rst, 
            wr_en => wr_ens(0),
            wr_data => wr_datas(0),
            rd_en => rd_ens(0),
            rd_valid => rd_valids(0),
            rd_data => rd_datas(0),     -- THIS INDEXING IS WEIRD
            empty => empties(0),
            empty_next => empty_nexts(0),
            full => fulls(0),
            full_next => full_nexts(0),
            fill_count => fill_counts(0)
        );
    fifo1 : entity work.ring_buffer 
        generic map (
            RAM_WIDTH => 2,
            RAM_DEPTH => 4
        )
        port map (
            clk => clk,
            rst => rst, 
            wr_en => wr_ens(1),
            wr_data => wr_datas(1),
            rd_en => rd_ens(1),
            rd_valid => rd_valids(1),
            rd_data => rd_datas(1),     -- THIS INDEXING IS WEIRD
            empty => empties(1),
            empty_next => empty_nexts(1),
            full => fulls(1),
            full_next => full_nexts(1),
            fill_count => fill_counts(1)
        );
    fifo2 : entity work.ring_buffer 
        generic map (
            RAM_WIDTH => 2,
            RAM_DEPTH => 4
        )
        port map (
            clk => clk,
            rst => rst, 
            wr_en => wr_ens(2),
            wr_data => wr_datas(2),
            rd_en => rd_ens(2),
            rd_valid => rd_valids(2),
            rd_data => rd_datas(2),     -- THIS INDEXING IS WEIRD
            empty => empties(2),
            empty_next => empty_nexts(2),
            full => fulls(2),
            full_next => full_nexts(2),
            fill_count => fill_counts(2)
        );
    fifo3 : entity work.ring_buffer 
        generic map (
            RAM_WIDTH => 2,
            RAM_DEPTH => 4
        )
        port map (
            clk => clk,
            rst => rst, 
            wr_en => wr_ens(3),
            wr_data => wr_datas(3),
            rd_en => rd_ens(3),
            rd_valid => rd_valids(3),
            rd_data => rd_datas(3),     -- THIS INDEXING IS WEIRD
            empty => empties(3),
            empty_next => empty_nexts(3),
            full => fulls(3),
            full_next => full_nexts(3),
            fill_count => fill_counts(3)
        );

    uut2 : entity work.rr_arbiter_41_new_idx
        generic map ( DWIDTH => 2 )
        port map (
            empty_in   => empties,
            valid_in   => rd_valids,
            data_in    => rd_datas,
            clk        => clk, 
            rst        => rst, 
            enable_out => rd_ens,
            data_out   => dout_2,
            valid_out  => data_valid
        );

    psim : process
    begin 
        -- disable active high reset 
        wait for 50 * tdc_pd;
        rst <= '0';
        wait for 50 * tdc_pd;
        
        -- check what happens when one of the inputs has a valid hit 
        wr_ens(1)   <= '1';
        wr_datas(1) <= "11";
        wait for tdc_pd;
        wr_ens(1)   <= '0';
        wr_datas(1) <= "00";
        
        wait for 10 * tdc_pd;
        
        -- now see what happens when two of the inputs have a valid hit simultaneously 
        wr_ens(2)   <= '1';
        wr_datas(2) <= "01";
        wr_ens(3)   <= '1';
        wr_datas(3) <= "10";
        wait for tdc_pd;
        wr_ens(2)   <= '0';
        wr_datas(2) <= "00";
        wr_ens(3)   <= '0';
        wr_datas(3) <= "00";
        
        wait for 10 * tdc_pd;
        
        -- now test two "non-consecutive" FIFOs
        wr_ens(0)   <= '1';
        wr_datas(0) <= "01";
        wr_ens(2)   <= '1';
        wr_datas(2) <= "10";
        wait for tdc_pd;
        wr_ens(0)   <= '0';
        wr_datas(0) <= "00";
        wr_ens(2)   <= '0';
        wr_datas(2) <= "00";
        
        wait for 10 * tdc_pd;        
        
        -- now test all four FIFOs having a simultaneous hit 
        wr_ens(0)   <= '1';
        wr_datas(0) <= "01";
        wr_ens(1)   <= '1';
        wr_datas(1) <= "10";
        wr_ens(2)   <= '1';
        wr_datas(2) <= "11";
        wr_ens(3)   <= '1';
        wr_datas(3) <= "10";
        wait for tdc_pd;
        wr_ens(0)   <= '0';
        wr_datas(0) <= "00";
        wr_ens(1)   <= '0';
        wr_datas(1) <= "00";
        wr_ens(2)   <= '0';
        wr_datas(2) <= "00";
        wr_ens(3)   <= '0';
        wr_datas(3) <= "00";

        wait for 10 * tdc_pd;
        
        -- now test multiple hits at once, with some FIFOs having two hits stored 
        -- NOTE: in actual TDC operation two hits would not arrive sequentially like this
        -- since there is latency in the encoding. This is just meant to simulate 
        -- backpressure in the FIFO and whether or not the arbiter logic can handle it.
        wr_ens(0)   <= '1';
        wr_datas(0) <= "01";
        wr_ens(2)   <= '1';
        wr_datas(2) <= "11";
        wait for tdc_pd;
        wr_ens(0)   <= '1';
        wr_datas(0) <= "10";
        wr_ens(2)   <= '0';
        wr_datas(2) <= "00";
        wait for tdc_pd; 
        wr_ens(0)   <= '0';
        wr_datas(0) <= "00";
        
        wait;
    end process;

end Behavioral;
