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

Underneath each project directory (`Top/vivado/project_name/`) are a number of files used by Hog:

* `hog.conf`: **[MANDATORY]** The Hog configuration file used to set the Vivado project, synthesis, and implementation settings. More information [here](https://hog.readthedocs.io/en/2021.2/02-User-Manual/01-Hog-local/01-conf.html). This file can be automatically configured from an existing Vivado project by the [Hog buttons](https://hog.readthedocs.io/en/2021.2/02-User-Manual/01-Hog-local/02a-Hog-Buttons.html). 
* `sim.conf`: **[OPTIONAL]** The Hog configuration file for simulation settings.
* `list/`: **[MANDATORY]** This directory contains the list files, that are plain text files, used to instruct Hog on how to build the project. Each list file shall contain the list of the files to be added to the project. More information [here](https://hog.readthedocs.io/en/2021.2/02-User-Manual/01-Hog-local/02-List-files.html). Again, these files may be generated automatically from an exisiting Vivado project by Hog, see `hog.conf` above.
  * `ips.src`: Lists any IPs (user or proprietary) used in the project, as well as the block design (`.bd`) file(s). 
  * `sim_1.sim`: Lists the files used in simulation set 1. These files include the HDL testbench and any other associated files (e.g. `.wcfg`).
  * `sources.con`: Lists the constraints files used in the design. 
  * `xil_defaultlib.src`: Lists the files associated with the HDL library `xil_defaultlib` in the project. One can make other libraries with other files by adding a new `<library name>.src` file.

### Running the workflow

After cloning this repository, you can run the entire workflow automatically from the command line, using the project settings specified in `Top/vivado/project_name/hog.conf`.

To run only project creation:
```
./Hog/Do CREATE [C] vivado/project_name
```

To run the entire workflow:
```
./Hog/Do WORKFLOW [W] vivado/project_name
```

To create the project and run the complete workflow
```
./Hog/Do CREATEORKFLOW [CW] vivado/project_name
```

To simulate the project, creating it if not existing:
```
./Hog/Do SIMULATE [S] vivado/project_name
```

To run synthesis only, and create the project if it doesn't exist:
```
./Hog/Do SYNTHESIS vivado/project_name
```

To run implementation only (assuming the project exists and is synthesized):
```
./Hog/Do IMPLEMENT vivado/project_name
```

Run `./Hog/Do` at any time to see a list of all directives. 

### Development 




## Libero projects 

**WIP...**

