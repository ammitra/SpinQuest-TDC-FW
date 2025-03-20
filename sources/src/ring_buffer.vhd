---------------------------------------------------------------------------------------------------------
--! \file ring_buffer.vhd
--! \brief Circular (ring) buffer of configurable depth and width.
--! 
--! \details Ring buffer used as intermediate hit buffers between data producers (TDC channels) and arbiters. This module communicates with the 
--! arbiters to request access to a shared resource in which to write the stored hit information. This module was taken directly from <a href="https://vhdlwhiz.com/ring-buffer-fifo/">vhdlwiz.com.</a>
--! \author Jonas Julian Jensen, jonas@vhdlwhiz.com
---------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

--! \brief Circular (ring) buffer of configurable depth and width.
--! 
--! \details Ring buffer used as intermediate hit buffers between data producers (TDC channels) and arbiters. This module communicates with the 
--! arbiters to request access to a shared resource in which to write the stored hit information. This module was taken directly from <a href="https://vhdlwhiz.com/ring-buffer-fifo/">vhdlwiz.com.</a>
entity ring_buffer is
  generic (
    RAM_WIDTH : natural;  --! Width of the data in the buffer
    RAM_DEPTH : natural   --! Depth of the ring buffer
  );
  port (
    clk : in std_logic;   --! Input clock
    rst : in std_logic;   --! Active high reset
  
    -- Write port
    wr_en : in std_logic;                                   --! Write enable from data producer to ring buffer.
    wr_data : in std_logic_vector(RAM_WIDTH - 1 downto 0);  --! Data sent from producer to ring buffer.
  
    -- Read port
    rd_en : in std_logic;                                   --! Read enable from arbiter to ring buffer.
    rd_valid : out std_logic;                               --! Read valid from buffer to arbiter. Indicates that read enable was received.
    rd_data : out std_logic_vector(RAM_WIDTH - 1 downto 0); --! Data sent from end of buffer to arbiter. 
  
    -- Flags
    empty : out std_logic;        --! High if buffer is empty, low otherwise. Used by arbiter to indicate a request to write to shared memory.
    empty_next : out std_logic;   --! High if buffer will be empty after next read transaction (currently unused).
    full : out std_logic;         --! High if buffer is full, low otherwise (currently unused).
    full_next : out std_logic;    --! High if buffer will be full after next write transaction (currently unused).
  
    fill_count : out integer range RAM_DEPTH - 1 downto 0     --! The number of data words in the FIFO (currently unused).
  );
end ring_buffer;
  
architecture rtl of ring_buffer is
  
  type ram_type is array (0 to RAM_DEPTH - 1) of
    std_logic_vector(wr_data'range);
  signal ram : ram_type;
  
  subtype index_type is integer range ram_type'range;
  signal head : index_type;
  signal tail : index_type;
  
  signal empty_i : std_logic;
  signal full_i : std_logic;
  signal fill_count_i : integer range RAM_DEPTH - 1 downto 0;
  
  --! \brief Increment and wrap the index signal.
  procedure incr(signal index : inout index_type) is
  begin
    if index = index_type'high then
      index <= index_type'low;
    else
      index <= index + 1;
    end if;
  end procedure;
  
begin
  
  -- Copy internal signals to output
  empty <= empty_i;
  full <= full_i;
  fill_count <= fill_count_i;
  
  -- Set the flags
  empty_i <= '1' when fill_count_i = 0 else '0';
  empty_next <= '1' when fill_count_i <= 1 else '0';
  full_i <= '1' when fill_count_i >= RAM_DEPTH - 1 else '0';
  full_next <= '1' when fill_count_i >= RAM_DEPTH - 2 else '0';
  
  --! \brief Update the head pointer after a write transaction, if not full.
  PROC_HEAD : process(all)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        head <= 0;
      else
  
        if wr_en = '1' and full_i = '0' then
          incr(head);
        end if;
  
      end if;
    end if;
  end process;
  
  --! \brief Update the tail pointer on arbiter read and pulse valid
  PROC_TAIL : process(all)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        tail <= 0;
        rd_valid <= '0';
      else
        rd_valid <= '0';
  
        if rd_en = '1' and empty_i = '0' then
          incr(tail);
          rd_valid <= '1';
        end if;
  
      end if;
    end if;
  end process;
  
  --! \brief Write to and read from the RAM
  PROC_RAM : process(all)
  begin
    if rising_edge(clk) then
      ram(head) <= wr_data;
      rd_data <= ram(tail);
    end if;
  end process;
  
  --! \brief Update the fill count
  PROC_COUNT : process(all)
  begin
    if head < tail then
      fill_count_i <= head - tail + RAM_DEPTH;
    else
      fill_count_i <= head - tail;
    end if;
  end process;
  
end architecture;
