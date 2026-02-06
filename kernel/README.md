# ZynqMP OS build

This directory contains the Makefile for building the devicetree and kernel for the Krio ZynqMPSoC, as well as packaging them into the `BOOT.bin` and `image.ub` files. Based off the [LHC Apollo Service Module firmware repo](https://gitlab.com/apollo-lhc/FW/SM_ZYNQ_FW).

## device tree

The device tree is generated from the output products of Vivado, namely those providing the hardware description (address maps, device names, etc). Additional information is created to mark IP (BRAM controllers, GPIO) and HDL (TDC interrupt line) as generic-uio devices so that they can be interacted with easily using userspace applications on the SoC. The device tree is populated using the information contained in the XSA file produced by Vivado, but modifications can be made by the user by editing the file `<project_root>/project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi`. This can be automated using `.dtsi_chunk` and `.dtsi_post_chunk` files, found under `configs/TDC_64ch_2BRAM/hw_user/`. 

The `.dtsi_chunk` files describe device nodes whose properties you wish to modify. In the case of the SpinQuest TDC, these are the AXI BRAM controller and AXI GPIO IPs used for PS <-> PL communication. We can also use the `.dtsi_chunk` files to add a new device node, as is the case for the TDC interrupt line coming from the (custom RTL) TDC IP which does not have any assigned address. In this case, an address is assigned in the chunk file. 

The `dtsi_post_chunk` files perform the modification. In our case, they are used to assign the `uio` property to the AXI IPs and the TDC interrupt line devices in order to expose them as UIO devices, thus creating `/dev/uioX` nodes. From there, the userspace driver can map the device memory using `mmap()` and handle interrupts using `read()` calls directly on the device node. **NOTE:** in order for this to work, the kernel must be configured properly, as described in the next section.

## Linux Kernel

The kernel used on the Krio TDC boards is a modified petalinux kernel. The modifications can be found under `configs/TDC_64ch_2BRAM/kernel/linux/`. An example of how the kernel mod directory structure should look is given below:

```
configs/TDC_64ch_2BRAM/kernel/linux/
├── linux-xlnx
│   ├── bsp.cfg
│   └── user.cfg
└── linux-xlnx_%.bbappend
``` 

The `linux-xlnx/` directory should contain a `bsp.cfg` file (to be left blank) and a `user.cfg` file (to be edited). One can create more `.cfg` files in this subdirectory if one wishes to separate mods based on their functionality, in which case each of the files should be appended as space-separated values in the `SRC_URI` string at the end of the `linux-xlnx_%.bbappend` file. 

As a default, we modify the kernel to include the UIO drivers as well as the TI DP83869 gigabit PHY drivers. 

## Root filesystem

Users can add or remove packages from the image's rootfs by modifying the file `configs/TDC_64ch_2BRAM/configs/rootfs/rootfs_config`. 


