# Custom image recipe for the K26 SoM on the Krio carrier card. 
# Based on kria-image-full-cmdline with additional packages tailored for the Krio TDC system.

require recipes-core/images/kria-image-full-cmdline.bb

SUMMARY = "Krio image"
DESCRIPTION = "A full-featured image for the KR260 platform based on Kria"

# Enable systemd as init manager
DISTRO_FEATURES += "systemd"
DISTRO_FEATURES:remove = "sysvinit"

IMAGE_FEATURES += " \
    package-management \
    ssh-server-openssh \
    tools-debug \
    tools-sdk \
"

# Other useful packages
IMAGE_INSTALL += " \
    python3-dev \
    python3-pkgconfig \
    vim \
    nano \
    curl \
    wget \
    sudo \
    rsync \
    make \
    packagegroup-core-buildessential \
    openssh-sftp-server \
    openssh-ssh \
    openssh-scp \
    openssh-sftp \
    openssh-sshd \
    openssh-misc \
    openssh-keygen \
"

# Network tools
IMAGE_INSTALL += " \
    net-tools \
    iputils-ping \
    iputils-tracepath \
    tcpdump \
    iptables \
"

# System utilities
IMAGE_INSTALL += " \
    htop \
    procps \
    util-linux \
    util-linux-blkid \
    util-linux-fdisk \
    util-linux-lsblk \
    util-linux-mount \
    util-linux-umount \
    util-linux-swapon \
    util-linux-swapoff \
    util-linux-fsck \
    e2fsprogs \
    e2fsprogs-e2fsck \
    e2fsprogs-mke2fs \
    e2fsprogs-tune2fs \
    e2fsprogs-resize2fs \
    devmem2 \
"

# XRT (Xilinx Runtime) for FPGA acceleration
IMAGE_INSTALL += " \
    xrt \
"

# UIO kernel modules for device access
IMAGE_INSTALL += " \
    kernel-module-uio-pdrv-genirq \
    kernel-module-uio-dmem-genirq \
"

# Set hostname to Krio-K26
set_hostname() {
    echo "Krio-K26" > ${IMAGE_ROOTFS}${sysconfdir}/hostname
}

# Create Krio user with password and sudo privileges
create_krio_user() {
    # Create user home directory
    install -d ${IMAGE_ROOTFS}/home/krio
    chmod 755 ${IMAGE_ROOTFS}/home/krio

    # Password hash for "krio" generated using: openssl passwd -1 -salt xilinx xilinx
    # Hash: $1$xilinx$a9KcUB279cot0TWU7KGCA0
    PASSWORD_HASH='$1$xilinx$a9KcUB279cot0TWU7KGCA0'

    # Add user to /etc/passwd (UID 1000, GID 1000)
    echo "krio:x:1000:1000:krio User:/home/krio:/bin/bash" >> ${IMAGE_ROOTFS}/etc/passwd

    # Add user to /etc/group (create krio group)
    echo "krio:x:1000:" >> ${IMAGE_ROOTFS}/etc/group

    # Add password to /etc/shadow
    echo "krio:${PASSWORD_HASH}:19000:0:99999:7:::" >> ${IMAGE_ROOTFS}/etc/shadow

    # Add user to sudo group
    if [ -f ${IMAGE_ROOTFS}/etc/group ]; then
        # Check if sudo group exists, if not create it
        if ! grep -q "^sudo:" ${IMAGE_ROOTFS}/etc/group; then
            echo "sudo:x:27:" >> ${IMAGE_ROOTFS}/etc/group
        fi
        # Add xilinx to sudo group
        sed -i '/^sudo:/s/$/,xilinx/' ${IMAGE_ROOTFS}/etc/group
    fi

    # Configure sudoers to require password authentication for xilinx
    install -d ${IMAGE_ROOTFS}/etc/sudoers.d
    echo "xilinx ALL=(ALL) ALL" > ${IMAGE_ROOTFS}/etc/sudoers.d/xilinx
    chmod 440 ${IMAGE_ROOTFS}/etc/sudoers.d/xilinx

    # Set ownership of home directory
    chown -R 1000:1000 ${IMAGE_ROOTFS}/home/xilinx 2>/dev/null || true
}


