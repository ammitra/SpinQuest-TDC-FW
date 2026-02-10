# Apply master U-Boot config for the K26 platform
do_configure:append:k26-sm() {
	UBOOT_CONFIG_FILE=""
	for layer in ${BBLAYERS}; do
		if [ -f "${layer}/conf/layer.conf" ] && grep -q "krio" "${layer}/conf/layer.conf" 2>/dev/null; then
			if [ -f "${layer}/configs/u-boot.config" ]; then
				UBOOT_CONFIG_FILE="${layer}/configs/u-boot.config"
				break
			fi
		fi
	done

	if [ -z "${UBOOT_CONFIG_FILE}" ] || [ ! -f "${B}/.config" ]; then
		bbwarn "Unable to apply U-Boot config"
		return
	fi

	# Substitute network boot IP variables in the config file
	# Use default values if not set in local.conf
	BOARD_IP="${@d.getVar('BOARD_IP') or '172.20.1.2'}"
	BOARD_GATEWAY="${@d.getVar('BOARD_GATEWAY') or '172.20.1.1'}"
	NFS_SERVER="${@d.getVar('NFS_SERVER') or '172.20.1.1'}"

	# Create a temporary config file with substituted values
	sed -e "s|172\.20\.1\.1|${NFS_SERVER}|g" \
	    -e "s|172\.20\.1\.2|${BOARD_IP}|g" \
	    -e "s|setenv serverip 172\.20\.1\.1|setenv serverip ${NFS_SERVER}|g" \
	    -e "s|setenv ipaddr 172\.20\.1\.2|setenv ipaddr ${BOARD_IP}|g" \
	    "${UBOOT_CONFIG_FILE}" > "${B}/.config.tmp"
	mv "${B}/.config.tmp" "${B}/.config"
	bbnote "Applied U-Boot config from: ${UBOOT_CONFIG_FILE} (with IP substitution: BOARD_IP=${BOARD_IP}, NFS_SERVER=${NFS_SERVER})"
	cd "${B}" && oe_runmake olddefconfig
}
