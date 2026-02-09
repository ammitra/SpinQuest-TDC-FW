#
# This file is the tdc-app recipe.
#

SUMMARY = "Simple tdc-app to use fpgamanager class"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit fpgamanager_dtg update-alternatives
 
COMPATIBLE_MACHINE:zynq = ".*"
COMPATIBLE_MACHINE:zynqmp = ".*"
COMPATIBLE_MACHINE:versal = ".*"

SRC_URI = "file://system.xsa \
           file://shell.json \
           "
do_install:append() {
	install -d ${D}${sysconfdir}/dfx-mgrd
	echo "${PN}" > ${D}${sysconfdir}/dfx-mgrd/${PN}
}
 
FILES:${PN} += "${sysconfdir}"
 
ALTERNATIVE:${PN} = "default_firmware"
ALTERNATIVE_TARGET[default_firmware] = "${sysconfdir}/dfx-mgrd/${PN}"
ALTERNATIVE_LINK_NAME[default_firmware] = "${sysconfdir}/dfx-mgrd/default_firmware"
