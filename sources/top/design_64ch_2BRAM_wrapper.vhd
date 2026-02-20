--Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
--Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2024.2 (lin64) Build 5239630 Fri Nov 08 22:34:34 MST 2024
--Date        : Fri Feb 20 12:36:12 2026
--Host        : amitav-P15sG5 running 64-bit Ubuntu 24.04.2 LTS
--Command     : generate_target design_64ch_2BRAM_wrapper.bd
--Design      : design_64ch_2BRAM_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity design_64ch_2BRAM_wrapper is
  port (
    mlvds_sync_clkRF : in STD_LOGIC;
    mlvds_sync_trigger : in STD_LOGIC;
    tdc_hit : in STD_LOGIC_VECTOR ( 0 to 63 )
  );
end design_64ch_2BRAM_wrapper;

architecture STRUCTURE of design_64ch_2BRAM_wrapper is
  component design_64ch_2BRAM is
  port (
    tdc_hit : in STD_LOGIC_VECTOR ( 0 to 63 );
    mlvds_sync_clkRF : in STD_LOGIC;
    mlvds_sync_trigger : in STD_LOGIC
  );
  end component design_64ch_2BRAM;
begin
design_64ch_2BRAM_i: component design_64ch_2BRAM
     port map (
      mlvds_sync_clkRF => mlvds_sync_clkRF,
      mlvds_sync_trigger => mlvds_sync_trigger,
      tdc_hit(0 to 63) => tdc_hit(0 to 63)
    );
end STRUCTURE;
