# Makefile for the Yocto project for the SpinQuest TDC
# Targets the commercial Kria K26 SOM (with eMMC) on the Krio carrier card

YOCTO_VERSION ?= scarthgap
MACHINE	      ?= k26-sm
BUILD_DIR     ?= $(CURDIR)/build
SOURCES_DIR   ?= $(CURDIR)/sources
TMPDIR        ?= $(BUILD_DIR)/tmp

# Network boot configuration
# These must be defined in build/conf/local.conf
# Skip validation for setup targets that create the config file
CURRENT_TARGET := $(firstword $(MAKECMDGOALS))
SKIP_IP_VALIDATION := $(filter setup-env setup-sources help,$(CURRENT_TARGET))

# BitBake parallelism configuration
# Use 80% of available CPU cores for optimal parallelism
NUM_CORES := $(shell nproc)
BB_NUMBER_THREADS ?= $(shell cores=$$(nproc); echo $$(( cores * 80 / 100 )) | awk '{if (int($$1) < 1) print 1; else print int($$1)}')

# Xilinx Yocto Manifest configuration
# For Xilinx tools 2025.2, use repo tool with manifests (recommended approach)
# See: https://xilinx.github.io/kria-apps-docs/yocto/build/html/docs/yocto_kria_support.html
XILINX_RELEASE_TAG ?= rel-v2025.2
YOCTO_MANIFEST_URL = https://github.com/Xilinx/yocto-manifests.git

# Distribution selection for 2025.2:
# - default-edf.xml: EDF Distribution (for .wic images and general builds)
# Using EDF distribution
YOCTO_MANIFEST_FILE ?= default-edf.xml

# Configuration file paths
CONFIG_DIR    = $(CURDIR)/meta-krio/configs
KERNEL_CONFIG = $(CONFIG_DIR)/kernel.config

# Custom Yocto layer 
LAYER=./sources/meta-krio

.PHONY: help setup build-layer build-fw build-all rm-layer clean 

help:
	@echo ""
	@echo "Yocto Build System for Xilinx K26 SoM on Krio carrier card"
	@echo ""
	@echo "Available targets:"
	@echo "  setup    		  - Download and setup Yocto source repositories"
	@echo "  build-layer      - Build the custom meta-krio Yocto layer"
	@echo "  build-fw         - Run bitbake (after generating the custom layer)"
	@echo "  build-all        - Build everything"
	@echo "  rm-layer         - Remove the custom meta-krio Yocto layer"
	@echo "  clean            - Remove project and clean up Yocto build dirs"
	@echo ""
	@echo "Configuration:"
	@echo "  MACHINE           = $(MACHINE)"
	@echo "  YOCTO_VERSION     = $(YOCTO_VERSION)"
	@echo "  BUILD_DIR         = $(BUILD_DIR)"
	@echo "  BB_NUMBER_THREADS = $(BB_NUMBER_THREADS) (80% of $(NUM_CORES) cores)"
	@echo ""

setup:
	@echo "Setting up Yocto source repositories using repo tool..."
	@echo "Xilinx release: $(XILINX_RELEASE_TAG)"
	@echo "Manifest file: $(YOCTO_MANIFEST_FILE)"
	@echo ""
	@echo "Checking for repo tool..."
	@command repo init -u $(YOCTO_MANIFEST_URL) -b $(XILINX_RELEASE_TAG) && \
	repo sync && \
	. ./setupsdk
	@echo "Yocto $(XILINX_RELEASE_TAG) is ready."
	@echo ""

clean:
	@echo "Removing Yocto directories...."
	@rm -rf sources/ build/ .repo/ setupsdk
	@echo "Finished cleaning build environment."
	@echo ""

build-layer:
	@echo "Building the project..."
	@cp ../Projects/vivado/TDC_64ch_2BRAM/TDC_64ch_2BRAM.xsa meta-krio/recipes-apps/tdc-app/files/system.xsa && \
	bitbake-layers create-layer $(LAYER) && \
	mkdir -p $(LAYER)/{conf/machine,recipes-kernel/linux-xlnx,recipes-bsp/{u-boot/u-boot-xlnx,device-tree/files}} && \
	bitbake-layers add-layer $(LAYER)
	@command rm -rf sources/meta-krio/ && cp -r meta-krio/ sources/ 
	@echo "Done building the project..."

build-fw:
	@command echo "Building the firmware..." && \
	MACHINE=k26-sm bitbake petalinux-image-minimal

build-all: build-layer build-fw

rm-layer:
	@command bitbake-layers remove-layer meta-krio