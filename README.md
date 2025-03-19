# SpinQuest-TDC-FW

Firmware for the upgraded SpinQuest TDC boards for two platforms: the Kria K26 SoM and the PolarFire MPFS025T SoC. Revision control is handled by CERN's [Hog](https://hog.readthedocs.io/en/2021.2/index.html#) (HDL on git) software.

## Clone the repository

```
git clone --recursive https://github.com/ammitra/SpinQuest-TDC-FW.git
```

## Repository organization 

The repository is organized as follows:

```
SpinQuest-TDC-FW$ tree -dL 2
.
├── BD
├── Hog
├── IP
├── README.md
├── sources
├── sources
│   ├── sdc
│   ├── sim
│   ├── src
│   ├── top
│   ├── xdc
│   └── xml
└── Top
    ├── libero
    └── vivado
```

In order, these subdirectories contain:

* `BD/`: Vivado block design (`.bd`) files describing the components and connection between components in the block design. Different block designs should be stored in different subdirectories. 
* `Hog/`: The CERN [Hog](https://gitlab.cern.ch/hog/Hog) repository, added as a submodule. If you forgot to clone this repository with the `--recursive` flag, run the following command from the root of the repository: `git submodule update --init`
* `IP/`: Storage area for any Xilinx IP cores you produce and instantiate in the design as a component. **NOTE: user IP should be stored in its own directory `IP_Repository`.**
* `sources/`: Directory containing constraints, simulation, HDL source, and XML files. 
  * `sdc/`: Storage area for Synopsis Design Constraints and/or Physical Design Constraints files, used for assigning design and timing constraints for Libero designs.
  * `sim/`: Storage area for HDL simulation files and Xilinx waveform configuration files (`.wcfg`).
  * `src/`: Storage area for user-written HDL files that enter the design underneath the top-level. 
  * `top/`: Storage area for top-level HDL files in the design. 
  * `xdc/`: Storage area for Xilinx Design Constraints files, used for assigning design and timing constraints for Vivado designs.
  * `xml/`: Storage area for xml files used in Vivado IP and board designs.
* `Top/`: Directory containing sub-directories for each Vivado/Libero project in the repository. The project directories have a fixed structure and contain everything needed to recreate the Vivado/Libero project locally. The directory structure will be explained below. 

## Vivado projects

```
SpinQuest-TDC-FW$ tree -L 3 Top/vivado/
Top/vivado/
├── TDC_64ch_1BRAM
│   ├── hog.conf
│   ├── list
│   │   ├── ips.src
│   │   ├── sim_1.sim
│   │   ├── sources.con
│   │   └── xil_defaultlib.src
│   └── sim.conf
└── TDC_64ch_2BRAM
    ├── hog.conf
    ├── list
    │   ├── ips.src
    │   ├── sim_1.sim
    │   ├── sources.con
    │   └── xil_defaultlib.src
    └── sim.conf
```

There are currently two Vivado projects in this repository that can be built separately, targeting the Kria K26 SoM.

* The `TDC_64ch_1BRAM/` directory contains the files necessary to create the TDC design that writes only to *one* BRAM. This is useful for fast debugging of the firmware in hardware and in simulation. 
* The `TDC_64ch_2BRAM/` directory contains the files necessary to create the TDC design that writes to one of two separate BRAMs, switching upon arrival of the trigger signal. This is the design which will be developed into the final production firmware for SpinQuest's TDC boards.


## Libero projects 

**WIP...**

