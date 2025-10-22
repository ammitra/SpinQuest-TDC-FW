--Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
--Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2024.2 (lin64) Build 5239630 Fri Nov 08 22:34:34 MST 2024
--Date        : Wed Mar  5 18:41:08 2025
--Host        : amitav-P15sG5 running 64-bit Ubuntu 24.04.2 LTS
--Command     : generate_target design_1_wrapper.bd
--Design      : design_1_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity design_64ch_2BRAM_wrapper is
  port (
    tdc_hit : in STD_LOGIC_VECTOR ( 0 to 0 );
    trigger : in STD_LOGIC
  );
end design_64ch_2BRAM_wrapper;

architecture STRUCTURE of design_64ch_2BRAM_wrapper is
  component design_64ch_2BRAM is
  port (
    trigger : in STD_LOGIC;
    tdc_hit : in STD_LOGIC_VECTOR ( 0 to 0 )
  );
  end component design_64ch_2BRAM;
begin
design_1_i: component design_64ch_2BRAM
     port map (
      tdc_hit(0) => tdc_hit(0),
      trigger => trigger
    );
end STRUCTURE;
