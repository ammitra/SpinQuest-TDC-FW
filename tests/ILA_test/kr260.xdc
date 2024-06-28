######################## PMOD 1 Upper ########################
set_property -dict { PACKAGE_PIN H12 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4 } [get_ports {pmod1_io_0}];

######################## PMOD 1 Lower ########################
set_property -dict { PACKAGE_PIN B10 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4 } [get_ports {pmod1_io_4}];

######################## PMOD 2 Upper ########################
#set_property -dict { PACKAGE_PIN J11 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4 } [get_ports {pmod2_io_0}];
#set_property -dict { PACKAGE_PIN J10 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4 } [get_ports {pmod2_io_1}];
#set_property -dict { PACKAGE_PIN K13 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4 } [get_ports {pmod2_io_2}];
#set_property -dict { PACKAGE_PIN K12 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4 } [get_ports {pmod2_io_3}];

######################## PMOD 2 Lower ########################
#set_property -dict { PACKAGE_PIN H11 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4 } [get_ports {pmod2_io_4}];
#set_property -dict { PACKAGE_PIN G10 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4 } [get_ports {pmod2_io_5}];
#set_property -dict { PACKAGE_PIN F12 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4 } [get_ports {pmod2_io_6}];
#set_property -dict { PACKAGE_PIN F11 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4 } [get_ports {pmod2_io_7}];

######################## PMOD 3 Upper ########################
#set_property -dict { PACKAGE_PIN AE12 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4 } [get_ports {pmod3_io_0}];

##############################################################
# Prohibit placing delays in certain regions of the PL fabric
set_property PROHIBIT 1 [get_sites -of [get_package_pins W9]]
set_property PROHIBIT 1 [get_sites -of [get_package_pins AD6]]
set_property PROHIBIT 1 [get_sites -of [get_package_pins G4]]