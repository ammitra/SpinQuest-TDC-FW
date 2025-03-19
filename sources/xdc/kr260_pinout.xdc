######################## PMOD 1 Upper ########################
# HIT IN
set_property PACKAGE_PIN H12 [get_ports {tdc_hit[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {tdc_hit[0]}]

# TRIGGER IN
set_property PACKAGE_PIN E10 [get_ports trigger]
set_property IOSTANDARD LVCMOS33 [get_ports trigger]

# MMCM LOCKED (DEBUG)
#set_property PACKAGE_PIN D10 [get_ports {pmod_upper_3}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_upper_3}]

#set_property PACKAGE_PIN C11 [get_ports {pmod_upper_4}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_upper_4}]

######################## PMOD 1 Lower ########################
#set_property PACKAGE_PIN B10 [get_ports {pmod_lower[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_lower[0]}]

#set_property PACKAGE_PIN E12 [get_ports {pmod_lower[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_lower[1]}]

#set_property PACKAGE_PIN D11 [get_ports {pmod_lower[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_lower[2]}]

#set_property PACKAGE_PIN B11 [get_ports {pmod_lower[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_lower[3]}]

######################## PMOD 2 Upper ########################
#set_property PACKAGE_PIN J11 [get_ports {pmod_upper[4]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_upper[4]}]

#set_property PACKAGE_PIN J10 [get_ports {pmod_upper[5]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_upper[5]}]

#set_property PACKAGE_PIN K13 [get_ports {pmod_upper[6]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_upper[6]}]

#set_property PACKAGE_PIN K12 [get_ports {pmod_upper[7]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_upper[7]}]

######################## PMOD 2 Lower ########################
#set_property PACKAGE_PIN H11 [get_ports {pmod_lower[4]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_lower[4]}]

#set_property PACKAGE_PIN G10 [get_ports {pmod_lower[5]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_lower[5]}]

#set_property PACKAGE_PIN F12 [get_ports {pmod_lower[6]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_lower[6]}]

#set_property PACKAGE_PIN F11 [get_ports {pmod_lower[7]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_lower[7]}]

######################## PMOD 3 Upper ########################
#set_property PACKAGE_PIN AE12 [get_ports {pmod_upper[8]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_upper[8]}]

#set_property PACKAGE_PIN AF12 [get_ports {pmod_upper[9]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_upper[9]}]

#set_property PACKAGE_PIN AG10 [get_ports {pmod_upper[10]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_upper[10]}]

#set_property PACKAGE_PIN AH10 [get_ports {pmod_upper[11]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_upper[11]}]

######################## PMOD 3 Lower ########################
#set_property PACKAGE_PIN AF11 [get_ports {pmod_lower[8]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_lower[8]}]

#set_property PACKAGE_PIN AG11 [get_ports {pmod_lower[9]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_lower[9]}]

#set_property PACKAGE_PIN AH12 [get_ports {pmod_lower[10]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_lower[10]}]

#set_property PACKAGE_PIN AH11 [get_ports {pmod_lower[11]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_lower[11]}]

######################## PMOD 4 Upper ########################
#set_property PACKAGE_PIN AC12 [get_ports {pmod_upper[12]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_upper[12]}]

#set_property PACKAGE_PIN AD12 [get_ports {pmod_upper[13]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_upper[13]}]

#set_property PACKAGE_PIN AE10 [get_ports {pmod_upper[14]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_upper[14]}]

#set_property PACKAGE_PIN AF10 [get_ports {pmod_upper[15]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_upper[15]}]

######################## PMOD 4 Lower ########################
#set_property PACKAGE_PIN AD11 [get_ports {pmod_lower[12]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_lower[12]}]

#set_property PACKAGE_PIN AD10 [get_ports {pmod_lower[13]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_lower[13]}]

#set_property PACKAGE_PIN AA11 [get_ports {pmod_lower[14]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_lower[14]}]

#set_property PACKAGE_PIN AA10 [get_ports {pmod_lower[15]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_lower[15]}]


######################## Raspberry Pi GPIO Header ########################
### AXI GPIO ###
# 50 MHZ CLK (DEBUG)
#set_property PACKAGE_PIN AD15 [get_ports {rpi_gpio_HDC00}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio_HDC00}]

#set_property PACKAGE_PIN AD14 [get_ports {rpi_gpio[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio[1]}]

#set_property PACKAGE_PIN AE15 [get_ports {rpi_gpio[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio[2]}]

#set_property PACKAGE_PIN AE14 [get_ports {rpi_gpio[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio[3]}]

#set_property PACKAGE_PIN AG14 [get_ports {rpi_gpio[4]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio[4]}]

#set_property PACKAGE_PIN AH14 [get_ports {rpi_gpio[5]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio[5]}]

#set_property PACKAGE_PIN AG13 [get_ports {rpi_gpio[6]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio[6]}]

#set_property PACKAGE_PIN AH13 [get_ports {rpi_gpio[7]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio[7]}]

#set_property PACKAGE_PIN AC14 [get_ports {rpi_gpio[8]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio[8]}]

#set_property PACKAGE_PIN AC13 [get_ports {rpi_gpio[9]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio[9]}]

#set_property PACKAGE_PIN AE13 [get_ports {rpi_gpio[10]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio[10]}]

#set_property PACKAGE_PIN AF13 [get_ports {rpi_gpio[11]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio[11]}]

#set_property PACKAGE_PIN AA13 [get_ports {rpi_gpio[12]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio[12]}]

#set_property PACKAGE_PIN AB13 [get_ports {rpi_gpio[13]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio[13]}]

#set_property PACKAGE_PIN W14 [get_ports {rpi_gpio[14]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio[14]}]

#set_property PACKAGE_PIN W13 [get_ports {rpi_gpio[15]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio[15]}]

#set_property PACKAGE_PIN AB15 [get_ports {rpi_gpio[16]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio[16]}]

#set_property PACKAGE_PIN AB14 [get_ports {rpi_gpio_17}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio_17}]

#set_property PACKAGE_PIN Y14 [get_ports {rpi_gpio[18]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio[18]}]

#set_property PACKAGE_PIN Y13 [get_ports {rpi_gpio[19]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio[19]}]

#set_property PACKAGE_PIN W12 [get_ports {rpi_gpio[20]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio[20]}]

#set_property PACKAGE_PIN W11 [get_ports {rpi_gpio[21]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio[21]}]

#set_property PACKAGE_PIN Y12 [get_ports {rpi_gpio[22]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio[22]}]

#set_property PACKAGE_PIN AA12 [get_ports {rpi_gpio[23]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio[23]}]

#set_property PACKAGE_PIN Y9 [get_ports {rpi_gpio[24]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio[24]}]

#set_property PACKAGE_PIN AA8 [get_ports {rpi_gpio[25]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio[25]}]

#set_property PACKAGE_PIN AB10 [get_ports {rpi_gpio[26]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio[26]}]

#set_property PACKAGE_PIN AB9 [get_ports {rpi_gpio[27]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio[27]}]

### Special Functions ###
#set_property PACKAGE_PIN AD15 [get_ports {rpi_gpio0_id_sd}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio0_id_sd}]

#set_property PACKAGE_PIN AD14 [get_ports {rpi_gpio1_id_sc}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio1_id_sc}]

#set_property PACKAGE_PIN AE15 [get_ports {rpi_gpio2_sda}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio2_sda}]

#set_property PACKAGE_PIN AE14 [get_ports {rpi_gpio3_scl}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio3_scl}]

#set_property PACKAGE_PIN AG14 [get_ports {rpi_gpio4_gpclk0}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio4_gpclk0}]

#set_property PACKAGE_PIN AH14 [get_ports {rpi_gpio5}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio5}]

#set_property PACKAGE_PIN AG13 [get_ports {rpi_gpio6}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio6}]

#set_property PACKAGE_PIN AH13 [get_ports {rpi_gpio7_ce1}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio7_ce1}]

#set_property PACKAGE_PIN AC14 [get_ports {rpi_gpio8_ce0}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio8_ce0}]

#set_property PACKAGE_PIN AC13 [get_ports {rpi_gpio9_miso}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio9_miso}]

#set_property PACKAGE_PIN AE13 [get_ports {rpi_gpio10_mosi}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio10_mosi}]

#set_property PACKAGE_PIN AF13 [get_ports {rpi_gpio11_sclk}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio11_sclk}]

#set_property PACKAGE_PIN AA13 [get_ports {rpi_gpio12_pwm0}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio12_pwm0}]

#set_property PACKAGE_PIN AB13 [get_ports {rpi_gpio13_pwm1}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio13_pwm1}]

#set_property PACKAGE_PIN W14 [get_ports {rpi_gpio14_txd}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio14_txd}]

#set_property PACKAGE_PIN W13 [get_ports {rpi_gpio15_rxd}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio15_rxd}]

#set_property PACKAGE_PIN AB15 [get_ports {rpi_gpio16}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio16}]

#set_property PACKAGE_PIN AB14 [get_ports {rpi_gpio17}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio17}]

#set_property PACKAGE_PIN Y14 [get_ports {rpi_gpio18_pcm_clk}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio18_pcm_clk}]

#set_property PACKAGE_PIN Y13 [get_ports {rpi_gpio19_pcm_fs}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio19_pcm_fs}]

#set_property PACKAGE_PIN W12 [get_ports {rpi_gpio20_pcm_din}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio20_pcm_din}]

#set_property PACKAGE_PIN W11 [get_ports {rpi_gpio21_pcm_dout}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio21_pcm_dout}]

#set_property PACKAGE_PIN Y12 [get_ports {rpi_gpio22}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio22}]

#set_property PACKAGE_PIN AA12 [get_ports {rpi_gpio23}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio23}]

#set_property PACKAGE_PIN Y9 [get_ports {rpi_gpio24}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio24}]

#set_property PACKAGE_PIN AA8 [get_ports {rpi_gpio25}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio25}]

#set_property PACKAGE_PIN AB10 [get_ports {rpi_gpio26}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio26}]

#set_property PACKAGE_PIN AB9 [get_ports {rpi_gpio27}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rpi_gpio27}]
