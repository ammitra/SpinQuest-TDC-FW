MAKE_PATH:=$(shell pwd)

OUTPUT_MARKUP= 2>&1 | tee -a $(MAKE_PATH)/logs/make_log-$$@${SUB_VARIENT_SELECTION}.txt ${CCZE_CMD}

#################################################################################
# Help 
#################################################################################
#list magic: https://stackoverflow.com/questions/4219255/how-do-you-get-the-list-of-targets-in-a-makefile
#all grep commands need || true because not finding a match is an error and breaks the make rule
list:
	@echo
	@echo Build config:
	@$(MAKE) -pRrq -f $(MAKEFILE_LIST) | \
		awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | \
		grep -v "all" | grep -v "bit" | grep -v "list" | \
		grep -v "open" | grep -v init | grep -v interactive | \
		grep -v make | grep -v "NOTIFY" | grep -v overlays | \
		grep -v SVF | grep -v test |  grep -v prebuild | grep -v clean || true | \
		grep -v prebuild || true | grep -v clean || true | \
		egrep -v -e '^[^[:alnum:]]' -e '^$@$$' || true | column -c 150
	@echo
	@echo Prebuilds:
	@$(MAKE) -pRrq -f $(MAKEFILE_LIST) | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | grep prebuild_ || true | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'  || true  | column -c 150
	@echo
	@echo Vivado:
	@$(MAKE) -pRrq -f $(MAKEFILE_LIST) | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | grep open_  || true | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'  || true | column -c 150
	@echo
	@echo Clean:
	@$(MAKE) -pRrq -f $(MAKEFILE_LIST) | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | grep clean_  || true | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'  || true | column -c 150
	@echo

full_list:
	@$(MAKE) -pRrq -f $(MAKEFILE_LIST) | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$' || true | column 

#################################################################################
# VIVADO stuff
#################################################################################
BUILD_PETALINUX_VERSION?=2022.1 # NOT NEEDED - USE CONTAINER TO BUILD
BUILD_PETALINUX_ROOT?="/opt/Xilinx/petalinux"
SOURCE_PETALINUX_ENV=${BUILD_PETALINUX_ROOT}/settings.sh


################################################################################
# Configs
#################################################################################
# Get a list of the subdirs in configs.  These are our FPGA builds
CONFIGS_USp=$(filter-out configs/,$(patsubst configs/%/,%,$(dir $(wildcard configs/*/))))

define CONFIGS_USp_template = 
 $(1): ../Projects/vivado/$(1)/$(1).runs/impl_1/design_64ch_2BRAM_wrapper.bit 
	@echo "================================================================================" 	$(OUTPUT_MARKUP)
	@echo "clean out old things"																$(OUTPUT_MARKUP)
	$(setup_path)
	$(build_USp)
	$(build_output_files_USp)
	@echo "================================================================================" 	$(OUTPUT_MARKUP)
	@echo "Build ended:"																		$(OUTPUT_MARKUP)
	@date																						$(OUTPUT_MARKUP)
endef

################################################################################
# Kernel build variables
#################################################################################
BUILD_TIME=$(shell date +%s)

SUB_VARIENT_SELECTION?=.emmc

ZYNQ_BUILD=zynq_build
LINUX_BUILD_REL_PATH=images/linux
ZYNQ_BUILD_PROJECT_PATH=$(MAKE_PATH)/$(ZYNQ_BUILD)/$$@${SUB_VARIENT_SELECTION}/
ZYNQ_KERNEL_MODULES_PATH=$(ZYNQ_BUILD_PROJECT_PATH)/build/tmp/sysroots-components/zynqmp_generic_$(DEVICE_NAME)/
ZYNQ_BUILD_PROJECT=$(ZYNQ_BUILD_PROJECT_PATH)/config.project
BOOT_FILES=$(ZYNQ_BUILD_PROJECT)/$(LINUX_BUILD_REL_PATH)/BOOT.BIN

# $$@ escapes $@, which is used in the makefile functions to specify the specific build
CONFIGS_BASE=configs/
CONFIG_BASE=configs/TDC_64ch_2BRAM/

YOCTO_BASE=$(ZYNQ_BUILD_PROJECT_PATH)/project-spec/

YOCTO_CONFIG_BASE=$(YOCTO_BASE)/configs/

YOCTO_USER_BASE        =$(YOCTO_BASE)/meta-user/
YOCTO_USER_BSP_BASE    =$(YOCTO_USER_BASE)/recipes-bsp/
YOCTO_USER_KERNEL_BASE =$(YOCTO_USER_BASE)/recipes-kernel/
YOCTO_USER_MODULES_BASE=$(YOCTO_USER_BASE)/recipes-modules/

#CONFIG_BOOTLOADER=CONFIG_BOOTLOADER
CONFIG_ROOTFS=CONFIG_ROOTFS

ROOTFS_CONFIG_SRC_PATH=$(CONFIG_BASE)/configs/rootfs/
ROOTFS_CONFIG_DST_PATH=$(YOCTO_CONFIG_BASE)/

BOOT_CONFIG_SRC_PATH=$(CONFIG_BASE)/configs/boot_config/
BOOT_CONFIG_SRC_FILENAME=config${SUB_VARIENT_SELECTION}
BOOT_CONFIG_DST_PATH=$(YOCTO_CONFIG_BASE)/

UBOOT_MOD_SRC_PATH=$(CONFIG_BASE)/u-boot/
UBOOT_MOD_DST_PATH=$(YOCTO_USER_BSP_BASE)/u-boot/

ESW_MOD_SRC_PATH=$(CONFIG_BASE)/embeddedsw/
ESW_MOD_DST_PATH=$(YOCTO_USER_BSP_BASE)/embeddedsw/

KERNEL_MODS_SRC_PATH=$(CONFIG_BASE)/kernel/linux
KERNEL_MODS_DST_PATH=$(YOCTO_USER_KERNEL_BASE)/

DEVTREE_MODS_SRC_PATHS="$(CONFIG_BASE)/hw_user"
DEVTREE_MODS_SCRIPT=$(CONFIG_BASE)/device-tree/build_user_dtsi${SUB_VARIENT_SELECTION}
DEVTREE_MODS_DST_FILE=$(YOCTO_USER_BSP_BASE)/device-tree/files/system-user.dtsi

KMODULE_SRC_PATH=$(CONFIG_BASE)/kmodules/
KMODULE_DST_PATH=$(YOCTO_USER_MODULES_BASE)
KMODULE_SCRIPT=scripts/setup_kernel_mods.sh

FSBL_MOD_SRC_PATH=$(CONFIG_BASE)/fsbl/
FSBL_MOD_DST_PATH=$(YOCTO_USER_BSP_BASE)/fsbl/
FSBL_MOD_ADDR_SRC_PATH=../$(CONFIG_BASE)/autogen/
FSBL_MOD_ADDR_DST_PATH=$(FSBL_MOD_DST_PATH)/files/git/lib/sw_apps/


PACKAGE_LINUX_IMAGE=$(ZYNQ_BUILD_PROJECT_PATH)/images/linux/image.elf

KERNEL_MODULES_BASE=$(YOCTO_MOD_BASE)/recipes-modules

.PHONY: list  clean $(ROOTFS_CONFIG_DST_PATH) $(BOOT_CONFIG_DST_PATH) REBUILD_BOOTBIN tarball

clean:
	rm -rf ${ZYNQ_BUILD}
	rm -f  logs/make_log*.txt



#################################################################################
# Helper calls to simplify build rules
#################################################################################
# " || : " allows for a config to not fail if it doesn't have this kind of mod
define copy_configs =
	@echo $(CONFIGS_BASE)																		$(OUTPUT_MARKUP)
	@echo $(CONFIG_BASE)																		$(OUTPUT_MARKUP)
	@pwd																						$(OUTPUT_MARKUP)
# 	ROOTFS_MODS =============================================================
	@echo "================================================================================" 	$(OUTPUT_MARKUP)
	@echo "adding rootfs mods" 																	$(OUTPUT_MARKUP)
	@cp   	$(ROOTFS_CONFIG_SRC_PATH)/rootfs_config  \
			$(ROOTFS_CONFIG_DST_PATH)/rootfs_config || :										$(OUTPUT_MARKUP)
	@cp   	$(ROOTFS_CONFIG_SRC_PATH)/rootfs_config  \
			$(ROOTFS_CONFIG_DST_PATH)/rootfs_config.old || :									$(OUTPUT_MARKUP)

#	BOOT MODS ===============================================================
	@echo "================================================================================" 	$(OUTPUT_MARKUP)
	@echo "adding boot mods" 																	$(OUTPUT_MARKUP)
	@cp 	$(BOOT_CONFIG_SRC_PATH)/$(BOOT_CONFIG_SRC_FILENAME)  \
			$(BOOT_CONFIG_DST_PATH)/config 	 || : 												$(OUTPUT_MARKUP)
	@cp 	$(BOOT_CONFIG_SRC_PATH)/$(BOOT_CONFIG_SRC_FILENAME)  \
			$(BOOT_CONFIG_DST_PATH)/config.old || :												$(OUTPUT_MARKUP)

#   ESW mods ================================================================
	@echo "================================================================================" 	$(OUTPUT_MARKUP)
	@echo "adding embedded sw files" 															$(OUTPUT_MARKUP)
	@mkdir -p $(dir $(ESW_MOD_DST_PATH)) 														$(OUTPUT_MARKUP) 
	@cp -r 	$(ESW_MOD_SRC_PATH)/*    \
			$(ESW_MOD_DST_PATH) || :															$(OUTPUT_MARKUP)


#	Device Tree mods ========================================================
	@echo "================================================================================" 	$(OUTPUT_MARKUP)
	@echo "Building device tree mods"	 														$(OUTPUT_MARKUP)
	@echo $(DEVTREE_MODS_SCRIPT)																$(OUTPUT_MARKUP)
	@echo $(DEVTREE_MODS_SRC_PATHS)																$(OUTPUT_MARKUP)
	@echo $(DEVTREE_MODS_DST_FILE)																$(OUTPUT_MARKUP)
	DTSI_PATH= $(DEVTREE_MODS_SCRIPT) \
		 	$(DEVTREE_MODS_SRC_PATHS) > \
			$(DEVTREE_MODS_DST_FILE) || : 														$(OUTPUT_MARKUP)

	@echo "================================================================================"	$(OUTPUT_MARKUP)
	@echo "End of mods"																			$(OUTPUT_MARKUP)
endef

define setup_path =
	@echo "================================================================================" 	$(OUTPUT_MARKUP)
	@echo "Creating fresh OS project"
	rm -f make_log-$$@${SUB_VARIENT_SELECTION}.txt												$(OUTPUT_MARKUP)
	rm -rf $(ZYNQ_BUILD_PROJECT_PATH) 															$(OUTPUT_MARKUP)	
endef


define build_project =
	@echo "================================================================================" 	$(OUTPUT_MARKUP)
	@echo "Config the project with info from the HW"
	@cd $(ZYNQ_BUILD_PROJECT_PATH) &&\
		source $(SOURCE_PETALINUX_ENV) && \
		pwd && \
		petalinux-config --get-hw-description \
				../../../Projects/vivado/TDC_64ch_2BRAM/TDC_64ch_2BRAM.xsa --silentconfig       $(OUTPUT_MARKUP)
	@echo "================================================================================" 	$(OUTPUT_MARKUP)
	@echo "Apply all mods" 																		$(OUTPUT_MARKUP)
	$(copy_configs) 
	@echo "================================================================================" 	$(OUTPUT_MARKUP)
	@echo "Reset the project build"																$(OUTPUT_MARKUP)
	@cd $(ZYNQ_BUILD_PROJECT_PATH) &&\
		source $(SOURCE_PETALINUX_ENV) && \
		petalinux-build -x mrproper 															$(OUTPUT_MARKUP)
	@echo "================================================================================" 	$(OUTPUT_MARKUP)
	@echo "Build the project"																	$(OUTPUT_MARKUP)
	@cd $(ZYNQ_BUILD_PROJECT_PATH) &&\
		source $(SOURCE_PETALINUX_ENV) && \
		petalinux-build 																		$(OUTPUT_MARKUP)
	@echo "================================================================================" 	$(OUTPUT_MARKUP)
	@echo "Build the app"																		$(OUTPUT_MARKUP)
	@cd $(ZYNQ_BUILD_PROJECT_PATH) &&\
		source $(SOURCE_PETALINUX_ENV) && \
		petalinux-create -t apps --template fpgamanager_dtg -n tdc-app --enable \
		--srcuri "./project-spec/hw-description/system.xsa ../../configs/TDC_64ch_2BRAM/embeddedsw/shell.json" $(OUTPUT_MARKUP)
	@cd $(ZYNQ_BUILD_PROJECT_PATH) &&\
		cp ../../configs/TDC_64ch_2BRAM/embeddedsw/tdc-app.bbappend ./project-spec/meta-user/recipes-apps/tdc-app
	@echo "================================================================================" 	$(OUTPUT_MARKUP)
	@echo "Packaging images"																	$(OUTPUT_MARKUP)
	@cd $(ZYNQ_BUILD_PROJECT_PATH) &&\
		source $(SOURCE_PETALINUX_ENV) && \
		petalinux-build -x package 																$(OUTPUT_MARKUP)
endef


define build_output_files_USp =
	@echo "================================================================================" 	$(OUTPUT_MARKUP)
	@echo "package"																				$(OUTPUT_MARKUP)
	@cd $(ZYNQ_BUILD_PROJECT_PATH) &&\
		source $(SOURCE_PETALINUX_ENV) && \
		petalinux-package --boot --u-boot --force \
		petalinux-package --wic --images-dir images/linux/ --bootfiles "boot.scr, Image, system.dtb" --disk-name "sda"

endef

define build_USp =
	@echo "================================================================================" 	$(OUTPUT_MARKUP)
	@echo "Create petalinux project"															$(OUTPUT_MARKUP)
	@mkdir -p $(ZYNQ_BUILD)
	source $(SOURCE_PETALINUX_ENV) && \
		cd $(ZYNQ_BUILD) && \
		petalinux-create --type project --name $$@${SUB_VARIENT_SELECTION} \
			--template zynqMP --force 															$(OUTPUT_MARKUP)
	@echo "================================================================================" 	$(OUTPUT_MARKUP)
	@echo "build"																				$(OUTPUT_MARKUP)
	$(build_project)
endef


#################################################################################
# Real builds
#################################################################################
# Generate a build rule for each config in the configs dir ($CONFIGS) 
#$(foreach config,$(CONFIGS_USp),$(eval $(call CONFIGS_USp_template,$(config))))


build : ../Projects/vivado/TDC_64ch_2BRAM/TDC_64ch_2BRAM.runs/impl_1/design_64ch_2BRAM_wrapper.bit 
	@echo "================================================================================" 	$(OUTPUT_MARKUP)
	@echo "clean out old things"																$(OUTPUT_MARKUP)
	$(setup_path)
	$(build_USp)
	$(build_output_files_USp)
	@echo "================================================================================" 	$(OUTPUT_MARKUP)
	@echo "Build ended:"																		$(OUTPUT_MARKUP)
	@date																						$(OUTPUT_MARKUP)

get_built_dts : ${ZYNQ_BUILD_PROJECT_PATH}/images/linux/system.dtb
	dtc -I dtb -O dts -o dump_${BUILD_TIME}.dts ${ZYNQ_BUILD_PROJECT_PATH}/images/linux/system.dtb  $(OUTPUT_MARKUP)

reconfig_kernel:
	@cd $(ZYNQ_BUILD_PROJECT_PATH) &&\
		source $(SOURCE_PETALINUX_ENV) && \
		petalinux-config -c kernel																	$(OUTPUT_MARKUP)

reconfig:
	@cd $(ZYNQ_BUILD_PROJECT_PATH) &&\
		source $(SOURCE_PETALINUX_ENV) && \
		petalinux-config																			$(OUTPUT_MARKUP)

