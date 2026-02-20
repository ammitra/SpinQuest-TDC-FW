########################################################################
# MLVDS sync bus
########################################################################

# HDA16_CC (JA1 B21)
set_property PACKAGE_PIN E12 [get_ports mlvds_sync_clkRF]
set_property IOSTANDARD LVCMOS33 [get_ports mlvds_sync_clkRF]
# Have to set some clock constraints when using external clock through clock-capable pin on HDIO bank
# https://adaptivesupport.amd.com/s/question/0D54U00006rWndCSAS/why-hdio-banks-have-global-clock-pins-if-they-are-not-directly-connected-to-a-global-clock-net-?language=en_US
# https://adaptivesupport.amd.com/s/question/0D52E00006hpgiwSAA/drc-2320-rule-violation-plhdio4-hdio-drc-checks-the-following-io-terminals-are-locked-to-highdensity-io-banks-but-they-drive-a-pllmmcmbufgctrlbufgcediv-instance-which-cannot-be-placed-in?language=en_US
#set_property CLOCK_DEDICATED_ROUTE ANY_CMT_COLUMN [get_nets design_64ch_2BRAM_i/clk_wiz_0/inst/clk_in1_design_64ch_2BRAM_clk_wiz_0_0]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets mlvds_sync_clkRF_IBUF_inst/O]
set_property CLOCK_DEDICATED_ROUTE ANY_CMT_COLUMN [get_nets xlnx_opt_]
# HDA18 (JA1 C22)
set_property PACKAGE_PIN B11 [get_ports mlvds_sync_trigger]
set_property IOSTANDARD LVCMOS33 [get_ports mlvds_sync_trigger]

# HDA19 (JA1 C23)
#set_property PACKAGE_PIN A10 [get_ports {mlvds_sync[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {mlvds_sync[2]}]

# HDA20 (JA1 C24)
#set_property PACKAGE_PIN A12 [get_ports {mlvds_sync[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {mlvds_sync[3]}]




########################################################################
# Data (64ch)
########################################################################

# HDA00_CC (JA1 D16)
set_property PACKAGE_PIN G11 [get_ports {tdc_hit[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[0]}]


# HDA01 (JA1 D17)
set_property PACKAGE_PIN F10 [get_ports {tdc_hit[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[1]}]


# HDA02 (JA1 D18)
set_property PACKAGE_PIN J11 [get_ports {tdc_hit[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[2]}]


# HDA03 (JA1 B16)
set_property PACKAGE_PIN J10 [get_ports {tdc_hit[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[3]}]


# HDA04 (JA1 B17)
set_property PACKAGE_PIN K13 [get_ports {tdc_hit[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[4]}]


# HDA05 (JA1 B18)
set_property PACKAGE_PIN K12 [get_ports {tdc_hit[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[5]}]


# HDA06 (JA1 C18)
set_property PACKAGE_PIN H11 [get_ports {tdc_hit[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[6]}]


# HDA07 (JA1 C19)
set_property PACKAGE_PIN G10 [get_ports {tdc_hit[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[7]}]


# HDA08_CC (JA1 C20)
set_property PACKAGE_PIN F12 [get_ports {tdc_hit[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[8]}]


# HDA09 (JA1 A15)
set_property PACKAGE_PIN F11 [get_ports {tdc_hit[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[9]}]


# HDA10 (JA1 A16)
set_property PACKAGE_PIN J12 [get_ports {tdc_hit[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[10]}]


# HDA11 (JA1 A17)
set_property PACKAGE_PIN H12 [get_ports {tdc_hit[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[11]}]


# HDA12 (JA1 D20)
set_property PACKAGE_PIN E10 [get_ports {tdc_hit[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[12]}]


# HDA13 (JA1 D21)
set_property PACKAGE_PIN D10 [get_ports {tdc_hit[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[13]}]


# HDA14 (JA1 D22)
set_property PACKAGE_PIN C11 [get_ports {tdc_hit[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[14]}]


# HDA15 (JA1 B20)
set_property PACKAGE_PIN B10 [get_ports {tdc_hit[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[15]}]


# HDB00_CC (JA2 D44)
set_property PACKAGE_PIN AE12 [get_ports {tdc_hit[16]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[16]}]


# HDB01 (JA2 D45)
set_property PACKAGE_PIN AF12 [get_ports {tdc_hit[17]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[17]}]


# HDB02 (JA2 D46)
set_property PACKAGE_PIN AG10 [get_ports {tdc_hit[18]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[18]}]


# HDB03 (JA2 D48)
set_property PACKAGE_PIN AH10 [get_ports {tdc_hit[19]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[19]}]


# HDB04 (JA2 D49)
set_property PACKAGE_PIN AF11 [get_ports {tdc_hit[20]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[20]}]


# HDB05 (JA2 D50)
set_property PACKAGE_PIN AG11 [get_ports {tdc_hit[21]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[21]}]


# HDB06 (JA2 C46)
set_property PACKAGE_PIN AH12 [get_ports {tdc_hit[22]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[22]}]


# HDB07 (JA2 C47)
set_property PACKAGE_PIN AH11 [get_ports {tdc_hit[23]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[23]}]


# HDB08_CC (JA2 C48)
set_property PACKAGE_PIN AC12 [get_ports {tdc_hit[24]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[24]}]


# HDB09 (JA2 C50)
set_property PACKAGE_PIN AD12 [get_ports {tdc_hit[25]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[25]}]


# HDB10 (JA2 C51)
set_property PACKAGE_PIN AE10 [get_ports {tdc_hit[26]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[26]}]


# HDB11 (JA2 C52)
set_property PACKAGE_PIN AF10 [get_ports {tdc_hit[27]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[27]}]


# HDB12 (JA2 B44)
set_property PACKAGE_PIN AD11 [get_ports {tdc_hit[28]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[28]}]


# HDB13 (JA2 B45)
set_property PACKAGE_PIN AD10 [get_ports {tdc_hit[29]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[29]}]


# HDB14 (JA2 B46)
set_property PACKAGE_PIN AA11 [get_ports {tdc_hit[30]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[30]}]


# HDB15 (JA2 B48)
set_property PACKAGE_PIN AA10 [get_ports {tdc_hit[31]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[31]}]


# HDB16_CC (JA2 B49)
set_property PACKAGE_PIN AB11 [get_ports {tdc_hit[32]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[32]}]


# HDB17 (JA2 B50)
set_property PACKAGE_PIN AC11 [get_ports {tdc_hit[33]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[33]}]


# HDB18 (JA2 A46)
set_property PACKAGE_PIN W10 [get_ports {tdc_hit[34]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[34]}]


# HDB19 (JA2 A47)
set_property PACKAGE_PIN Y10 [get_ports {tdc_hit[35]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[35]}]


# HDB20 (JA2 A48)
set_property PACKAGE_PIN Y9 [get_ports {tdc_hit[36]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[36]}]


# HDB21 (JA2 A50)
set_property PACKAGE_PIN AA8 [get_ports {tdc_hit[37]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[37]}]


# HDB22 (JA2 A51)
set_property PACKAGE_PIN AB10 [get_ports {tdc_hit[38]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[38]}]


# HDB23 (JA2 A52)
set_property PACKAGE_PIN AB9 [get_ports {tdc_hit[39]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[39]}]


# HDC00_CC (JA2 D52)
set_property PACKAGE_PIN AD15 [get_ports {tdc_hit[40]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[40]}]


# HDC01 (JA2 D53)
set_property PACKAGE_PIN AD14 [get_ports {tdc_hit[41]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[41]}]


# HDC02 (JA2 D54)
set_property PACKAGE_PIN AE15 [get_ports {tdc_hit[42]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[42]}]


# HDC03 (JA2 D56)
set_property PACKAGE_PIN AE14 [get_ports {tdc_hit[43]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[43]}]


# HDC04 (JA2 D57)
set_property PACKAGE_PIN AG14 [get_ports {tdc_hit[44]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[44]}]


# HDC05 (JA2 D58)
set_property PACKAGE_PIN AH14 [get_ports {tdc_hit[45]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[45]}]


# HDC06 (JA2 C54)
set_property PACKAGE_PIN AG13 [get_ports {tdc_hit[46]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[46]}]


# HDC07 (JA2 C55)
set_property PACKAGE_PIN AH13 [get_ports {tdc_hit[47]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[47]}]


# HDC08_CC (JA2 C56)
set_property PACKAGE_PIN AC14 [get_ports {tdc_hit[48]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[48]}]


# HDC09 (JA2 C58)
set_property PACKAGE_PIN AC13 [get_ports {tdc_hit[49]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[49]}]


# HDC10 (JA2 C59)
set_property PACKAGE_PIN AE13 [get_ports {tdc_hit[50]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[50]}]


# HDC11 (JA2 C60)
set_property PACKAGE_PIN AF13 [get_ports {tdc_hit[51]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[51]}]


# HDC12 (JA2 B52)
set_property PACKAGE_PIN AA13 [get_ports {tdc_hit[52]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[52]}]


# HDC13 (JA2 B53)
set_property PACKAGE_PIN AB13 [get_ports {tdc_hit[53]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[53]}]


# HDC14 (JA2 B54)
set_property PACKAGE_PIN W14 [get_ports {tdc_hit[54]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[54]}]


# HDC15 (JA2 B56)
set_property PACKAGE_PIN W13 [get_ports {tdc_hit[55]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[55]}]


# HDC16_CC (JA2 B57)
set_property PACKAGE_PIN AB15 [get_ports {tdc_hit[56]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[56]}]


# HDC17 (JA2 B58)
set_property PACKAGE_PIN AB14 [get_ports {tdc_hit[57]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[57]}]


# HDC18 (JA2 A54)
set_property PACKAGE_PIN Y14 [get_ports {tdc_hit[58]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[58]}]


# HDC19 (JA2 A55)
set_property PACKAGE_PIN Y13 [get_ports {tdc_hit[59]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[59]}]


# HDC20 (JA2 A56)
set_property PACKAGE_PIN W12 [get_ports {tdc_hit[60]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[60]}]


# HDC21 (JA2 A58)
set_property PACKAGE_PIN W11 [get_ports {tdc_hit[61]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[61]}]


# HDC22 (JA2 A59)
set_property PACKAGE_PIN Y12 [get_ports {tdc_hit[62]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[62]}]


# HDC23 (JA2 A60)
set_property PACKAGE_PIN AA12 [get_ports {tdc_hit[63]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[63]}]
