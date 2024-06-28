#-----------------------------------------------------------
# Vivado v2023.2 (64-bit)
# SW Build 4029153 on Fri Oct 13 20:14:34 MDT 2023
# IP Build 4028589 on Sat Oct 14 00:45:43 MDT 2023
# SharedData Build 4025554 on Tue Oct 10 17:18:54 MDT 2023
# Start of session at: Fri Jun 28 12:52:27 2024
# Process ID: 13864
# Current directory: C:/Users/amita/AppData/Roaming/Xilinx/Vivado
# Command line: vivado.exe -gui_launcher_event rodinguilauncherevent24344
# Log file: C:/Users/amita/AppData/Roaming/Xilinx/Vivado/vivado.log
# Journal file: C:/Users/amita/AppData/Roaming/Xilinx/Vivado\vivado.jou
# Running On: LAPTOP-QTJLMURL, OS: Windows, CPU Frequency: 1697 MHz, CPU Physical cores: 16, Host memory: 33528 MB
#-----------------------------------------------------------
start_gui
create_project for_xinlong C:/Users/amita/FPGA/for_xinlong -part xck26-sfvc784-2LV-c
set_property board_part xilinx.com:kr260_som:part0:1.1 [current_project]
set_property board_connections {som240_1_connector xilinx.com:kr260_carrier:som240_1_connector:1.0 som240_2_connector xilinx.com:kr260_carrier:som240_2_connector:1.0} [current_project]
set_property target_language VHDL [current_project]
create_bd_design "system"
update_compile_order -fileset sources_1
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.5 zynq_ultra_ps_e_0
endgroup
apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1" }  [get_bd_cells zynq_ultra_ps_e_0]
set_property -dict [list \
  CONFIG.PSU__CRL_APB__PL1_REF_CTRL__FREQMHZ {250} \
  CONFIG.PSU__DISPLAYPORT__PERIPHERAL__ENABLE {0} \
  CONFIG.PSU__USE__M_AXI_GP1 {0} \
] [get_bd_cells zynq_ultra_ps_e_0]
import_files -norecurse C:/Users/amita/FPGA/for_xinlong/tapped_delay_line.vhd
update_compile_order -fileset sources_1
add_files -fileset constrs_1 -norecurse C:/Users/amita/FPGA/for_xinlong/kr260.xdc
import_files -fileset constrs_1 C:/Users/amita/FPGA/for_xinlong/kr260.xdc
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0
endgroup
set_property -dict [list \
  CONFIG.C_ALL_OUTPUTS {1} \
  CONFIG.C_GPIO_WIDTH {1} \
] [get_bd_cells axi_gpio_0]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/axi_gpio_0/S_AXI} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_gpio_0/S_AXI]
startgroup
make_bd_pins_external  [get_bd_pins axi_gpio_0/gpio_io_o]
endgroup
open_bd_design {C:/Users/amita/FPGA/for_xinlong/for_xinlong.srcs/sources_1/bd/system/system.bd}
set_property name pmod1_io_0 [get_bd_ports gpio_io_o_0]
create_bd_cell -type module -reference tapped_delay_line tapped_delay_line_0
connect_bd_net [get_bd_pins tapped_delay_line_0/clk_i] [get_bd_pins zynq_ultra_ps_e_0/pl_clk1]
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0
endgroup
connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins tapped_delay_line_0/reset_i]
startgroup
set_property CONFIG.CONST_VAL {0} [get_bd_cells xlconstant_0]
endgroup
set_property name FDRE_synch_rst_0 [get_bd_cells xlconstant_0]
startgroup
make_bd_pins_external  [get_bd_pins tapped_delay_line_0/signal_i]
endgroup
set_property name pmod1_io_4 [get_bd_ports signal_i_0]
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_0
endgroup
set_property -dict [list \
  CONFIG.C_DATA_DEPTH {131072} \
  CONFIG.C_MONITOR_TYPE {Native} \
  CONFIG.C_PROBE0_WIDTH {32} \
] [get_bd_cells ila_0]
connect_bd_net [get_bd_pins ila_0/clk] [get_bd_pins zynq_ultra_ps_e_0/pl_clk1]
connect_bd_net [get_bd_pins ila_0/probe0] [get_bd_pins tapped_delay_line_0/taps_o]
regenerate_bd_layout
validate_bd_design
make_wrapper -files [get_files C:/Users/amita/FPGA/for_xinlong/for_xinlong.srcs/sources_1/bd/system/system.bd] -top
add_files -norecurse c:/Users/amita/FPGA/for_xinlong/for_xinlong.gen/sources_1/bd/system/hdl/system_wrapper.vhd
update_compile_order -fileset sources_1
update_compile_order -fileset sources_1
generate_target all [get_files  C:/Users/amita/FPGA/for_xinlong/for_xinlong.srcs/sources_1/bd/system/system.bd]
catch { config_ip_cache -export [get_ips -all system_zynq_ultra_ps_e_0_0] }
catch { config_ip_cache -export [get_ips -all system_axi_gpio_0_0] }
catch { config_ip_cache -export [get_ips -all system_auto_ds_0] }
catch { config_ip_cache -export [get_ips -all system_auto_pc_0] }
catch { config_ip_cache -export [get_ips -all system_rst_ps8_0_99M_0] }
catch { config_ip_cache -export [get_ips -all system_tapped_delay_line_0_0] }
catch { config_ip_cache -export [get_ips -all system_ila_0_0] }
export_ip_user_files -of_objects [get_files C:/Users/amita/FPGA/for_xinlong/for_xinlong.srcs/sources_1/bd/system/system.bd] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] C:/Users/amita/FPGA/for_xinlong/for_xinlong.srcs/sources_1/bd/system/system.bd]
launch_runs system_auto_ds_0_synth_1 system_auto_pc_0_synth_1 system_axi_gpio_0_0_synth_1 system_ila_0_0_synth_1 system_rst_ps8_0_99M_0_synth_1 system_tapped_delay_line_0_0_synth_1 system_zynq_ultra_ps_e_0_0_synth_1 -jobs 16
wait_on_run system_auto_ds_0_synth_1
wait_on_run system_auto_pc_0_synth_1
wait_on_run system_axi_gpio_0_0_synth_1
wait_on_run system_ila_0_0_synth_1
wait_on_run system_rst_ps8_0_99M_0_synth_1
wait_on_run system_tapped_delay_line_0_0_synth_1
wait_on_run system_zynq_ultra_ps_e_0_0_synth_1
export_simulation -of_objects [get_files C:/Users/amita/FPGA/for_xinlong/for_xinlong.srcs/sources_1/bd/system/system.bd] -directory C:/Users/amita/FPGA/for_xinlong/for_xinlong.ip_user_files/sim_scripts -ip_user_files_dir C:/Users/amita/FPGA/for_xinlong/for_xinlong.ip_user_files -ipstatic_source_dir C:/Users/amita/FPGA/for_xinlong/for_xinlong.ip_user_files/ipstatic -lib_map_path [list {modelsim=C:/Users/amita/FPGA/for_xinlong/for_xinlong.cache/compile_simlib/modelsim} {questa=C:/Users/amita/FPGA/for_xinlong/for_xinlong.cache/compile_simlib/questa} {riviera=C:/Users/amita/FPGA/for_xinlong/for_xinlong.cache/compile_simlib/riviera} {activehdl=C:/Users/amita/FPGA/for_xinlong/for_xinlong.cache/compile_simlib/activehdl}] -use_ip_compiled_libs -force -quiet
launch_runs impl_1 -to_step write_bitstream -jobs 16
wait_on_run impl_1
open_run impl_1
write_hw_platform -fixed -include_bit -force -file C:/Users/amita/FPGA/for_xinlong/system_wrapper.xsa

