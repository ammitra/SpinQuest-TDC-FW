# ZynqMP OS build

This directory contains the Makefile for building the devicetree and kernel for the Krio ZynqMPSoC, as well as packaging them into the `BOOT.bin` and `image.ub` files. 

## device tree

The device tree is generated from the output products of Vivado, namely those providing the hardware description (address maps, device names, etc). Additional information is created to mark IP (BRAM controllers, GPIO) and HDL (TDC interrupt line) as generic-uio devices so that they can be interacted with easily using userspace applications on the SoC. 

## Linux Kernel

The kernel used on the Krio TDC boards is a modified petalinux kernel. The modifications can be found in `./zynq_os_mods`. 
