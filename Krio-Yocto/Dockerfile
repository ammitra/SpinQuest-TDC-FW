# Modified from Kris Chaplin's yocto container  <kris.chaplin@amd.com>
# https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/2823422188/Building+Yocto+Images+using+a+Docker+Container

FROM ubuntu:latest

ARG DEBIAN_FRONTEND=noninteractive

RUN \
        dpkg --add-architecture i386 && \
        apt-get update && \
        apt-get install -yq sudo build-essential git nano vim\
          python3-yaml libncursesw6 libncursesw6:i386 \
          python3 man bash diffstat gawk chrpath wget cpio \
          texinfo lzop apt-utils bc screen locales \
          libc6-dev-i386 doxygen libssl-dev dos2unix xvfb x11-utils \
          g++-multilib libssl-dev:i386 zlib1g-dev:i386 \
          libtool libtool-bin procps python3-setuptools pigz socat \
          zstd iproute2 lz4 iputils-ping \
          curl libtinfo6 net-tools xterm rsync u-boot-tools unzip zip && \

        rm -rf /var/lib/apt-lists/* && \
        echo "dash dash/sh boolean false" | debconf-set-selections && \
        dpkg-reconfigure dash

RUN curl https://storage.googleapis.com/git-repo-downloads/repo > /bin/repo && chmod a+x /bin/repo
#RUN sed -i "1s/python/python3/" /bin/repo
RUN groupadd build -g 1005
RUN useradd -ms /bin/bash -p build build -u 1005 -g 1005 && \
        usermod -aG sudo build && \
        echo "build:build" | chpasswd

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

ENV LANG=en_US.utf8

USER build
WORKDIR /home/build
RUN git config --global user.email "build@example.com" && git config --global user.name "Build" && git config --global color.ui "auto"
# fix dependency issue for older xilinx tools on newer ubuntu
RUN sudo ln -s /lib/x86_64-linux-gnu/libtinfo.so.6 /lib/x86_64-linux-gnu/libtinfo.so.5
#RUN \
#    repo init -u https://github.com/Xilinx/yocto-manifests.git -b rel-v2025.2 && \
#    repo sync 

