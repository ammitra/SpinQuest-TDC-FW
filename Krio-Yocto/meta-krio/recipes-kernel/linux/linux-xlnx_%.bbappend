# Apply saved kernel config from meta-krio/configs
do_configure:append:k26-sm() {
	KERNEL_CONFIG_FILE=""
	for layer in ${BBLAYERS}; do
		if [ -f "${layer}/conf/layer.conf" ] && grep -q "krio" "${layer}/conf/layer.conf" 2>/dev/null; then
			if [ -f "${layer}/configs/kernel.config" ]; then
				KERNEL_CONFIG_FILE="${layer}/configs/kernel.config"
				break
			fi
		fi
	done

	if [ -z "${KERNEL_CONFIG_FILE}" ]; then
		bbnote "No saved kernel config found, using default configuration"
		return
	fi

	# Find the kernel build directory where .config should be placed
	# The kernel build directory might be ${B} or a subdirectory like linux-*-standard-build
	KERNEL_BUILD_DIR="${B}"
	KERNEL_CONFIG_DST="${B}/.config"

	# Check if .config already exists in ${B}
	if [ ! -f "${KERNEL_CONFIG_DST}" ]; then
		# Try to find the standard build directory or any .config file
		FOUND_CONFIG=$(find "${B}" -name ".config" -type f 2>/dev/null | head -1)
		if [ -n "${FOUND_CONFIG}" ]; then
			KERNEL_CONFIG_DST="${FOUND_CONFIG}"
			KERNEL_BUILD_DIR=$(dirname "${FOUND_CONFIG}")
		else
			# Try to find linux-*-standard-build directory
			FOUND_BUILD_DIR=$(find "${B}" -name "linux-*-standard-build" -type d 2>/dev/null | head -1)
			if [ -n "${FOUND_BUILD_DIR}" ]; then
				KERNEL_BUILD_DIR="${FOUND_BUILD_DIR}"
				KERNEL_CONFIG_DST="${FOUND_BUILD_DIR}/.config"
			fi
		fi
	fi

	if [ ! -d "${KERNEL_BUILD_DIR}" ]; then
		bbwarn "Kernel build directory not found, skipping config copy..."
		return
	fi

	cp "${KERNEL_CONFIG_FILE}" "${KERNEL_CONFIG_DST}"
	bbnote "Applied kernel config from: ${KERNEL_CONFIG_FILE} to ${KERNEL_CONFIG_DST}"

	# Run olddefconfig to update the config with any new/changed options
	cd "${KERNEL_BUILD_DIR}" && oe_runmake olddefconfig || bbwarn "olddefconfig failed, continuing anyway"

}
