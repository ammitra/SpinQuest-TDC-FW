# Xilinx K26 SoM on Krio carrier card - Yocto project

Firmware build system using Yocto (version `scarthgap`). 

## Instructions 

A docker image with the Yocto toolchain can be created from the included Dockerfile:

```
docker build -t yoctocontainer .
```

It can then be run (from the main repository directory) with:

```
cd /path/to/SpinQuest-TCD-FW/
docker run --cap-add NET_ADMIN --hostname buildserver -it -v /tftpboot:/tftpboot -v `pwd`:/home/build/work yoctocontainer
```

Once inside the container, `cd` to `work/Kria-Yocto` and then use the Makefile to build the firmware. The repository is mounted to the container so all build products will persist after leaving the container. 

**NOTE:** Modify the Dockerfile to match your host UID and GID so that files created in the container can be easily modified after container destruction. 