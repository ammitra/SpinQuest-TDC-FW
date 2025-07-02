--Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
--Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2024.2 (lin64) Build 5239630 Fri Nov 08 22:34:34 MST 2024
--Date        : Wed Jul  2 17:39:24 2025
--Host        : amitav-P15sG5 running 64-bit Ubuntu 24.04.2 LTS
--Command     : generate_target ZynqPS_wrapper.bd
--Design      : ZynqPS_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity ZynqPS_wrapper is
  port (
    BRAM_1_B_addr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    BRAM_1_B_clk : in STD_LOGIC;
    BRAM_1_B_din : in STD_LOGIC_VECTOR ( 63 downto 0 );
    BRAM_1_B_dout : out STD_LOGIC_VECTOR ( 63 downto 0 );
    BRAM_1_B_en : in STD_LOGIC;
    BRAM_1_B_rst : in STD_LOGIC;
    BRAM_1_B_we : in STD_LOGIC_VECTOR ( 7 downto 0 );
    BRAM_2_B_addr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    BRAM_2_B_clk : in STD_LOGIC;
    BRAM_2_B_din : in STD_LOGIC_VECTOR ( 63 downto 0 );
    BRAM_2_B_dout : out STD_LOGIC_VECTOR ( 63 downto 0 );
    BRAM_2_B_en : in STD_LOGIC;
    BRAM_2_B_rst : in STD_LOGIC;
    BRAM_2_B_we : in STD_LOGIC_VECTOR ( 7 downto 0 );
    clk_out1_0 : out STD_LOGIC;
    clk_out2_0 : out STD_LOGIC;
    clk_out3_0 : out STD_LOGIC;
    clk_out4_0 : out STD_LOGIC;
    clk_sys : out STD_LOGIC;
    gpio_io_i_0 : in STD_LOGIC_VECTOR ( 1 downto 0 );
    gpio_io_o_0 : out STD_LOGIC_VECTOR ( 0 to 0 );
    locked_0 : out STD_LOGIC;
    pl_ps_irq0_0 : in STD_LOGIC_VECTOR ( 0 to 0 );
    ps_aresetn : out STD_LOGIC_VECTOR ( 0 to 0 )
  );
end ZynqPS_wrapper;

architecture STRUCTURE of ZynqPS_wrapper is
  component ZynqPS is
  port (
    BRAM_1_B_addr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    BRAM_1_B_clk : in STD_LOGIC;
    BRAM_1_B_din : in STD_LOGIC_VECTOR ( 63 downto 0 );
    BRAM_1_B_dout : out STD_LOGIC_VECTOR ( 63 downto 0 );
    BRAM_1_B_en : in STD_LOGIC;
    BRAM_1_B_rst : in STD_LOGIC;
    BRAM_1_B_we : in STD_LOGIC_VECTOR ( 7 downto 0 );
    BRAM_2_B_addr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    BRAM_2_B_clk : in STD_LOGIC;
    BRAM_2_B_din : in STD_LOGIC_VECTOR ( 63 downto 0 );
    BRAM_2_B_dout : out STD_LOGIC_VECTOR ( 63 downto 0 );
    BRAM_2_B_en : in STD_LOGIC;
    BRAM_2_B_rst : in STD_LOGIC;
    BRAM_2_B_we : in STD_LOGIC_VECTOR ( 7 downto 0 );
    ps_aresetn : out STD_LOGIC_VECTOR ( 0 to 0 );
    gpio_io_o_0 : out STD_LOGIC_VECTOR ( 0 to 0 );
    gpio_io_i_0 : in STD_LOGIC_VECTOR ( 1 downto 0 );
    pl_ps_irq0_0 : in STD_LOGIC_VECTOR ( 0 to 0 );
    clk_out3_0 : out STD_LOGIC;
    clk_out1_0 : out STD_LOGIC;
    locked_0 : out STD_LOGIC;
    clk_out2_0 : out STD_LOGIC;
    clk_out4_0 : out STD_LOGIC;
    clk_sys : out STD_LOGIC
  );
  end component ZynqPS;
begin
ZynqPS_i: component ZynqPS
     port map (
      BRAM_1_B_addr(31 downto 0) => BRAM_1_B_addr(31 downto 0),
      BRAM_1_B_clk => BRAM_1_B_clk,
      BRAM_1_B_din(63 downto 0) => BRAM_1_B_din(63 downto 0),
      BRAM_1_B_dout(63 downto 0) => BRAM_1_B_dout(63 downto 0),
      BRAM_1_B_en => BRAM_1_B_en,
      BRAM_1_B_rst => BRAM_1_B_rst,
      BRAM_1_B_we(7 downto 0) => BRAM_1_B_we(7 downto 0),
      BRAM_2_B_addr(31 downto 0) => BRAM_2_B_addr(31 downto 0),
      BRAM_2_B_clk => BRAM_2_B_clk,
      BRAM_2_B_din(63 downto 0) => BRAM_2_B_din(63 downto 0),
      BRAM_2_B_dout(63 downto 0) => BRAM_2_B_dout(63 downto 0),
      BRAM_2_B_en => BRAM_2_B_en,
      BRAM_2_B_rst => BRAM_2_B_rst,
      BRAM_2_B_we(7 downto 0) => BRAM_2_B_we(7 downto 0),
      clk_out1_0 => clk_out1_0,
      clk_out2_0 => clk_out2_0,
      clk_out3_0 => clk_out3_0,
      clk_out4_0 => clk_out4_0,
      clk_sys => clk_sys,
      gpio_io_i_0(1 downto 0) => gpio_io_i_0(1 downto 0),
      gpio_io_o_0(0) => gpio_io_o_0(0),
      locked_0 => locked_0,
      pl_ps_irq0_0(0) => pl_ps_irq0_0(0),
      ps_aresetn(0) => ps_aresetn(0)
    );
end STRUCTURE;
