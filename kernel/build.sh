#!/bin/bash

set -eou pipefail

cd /linux
ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- make -j9 Image

# I can't get make-kpkg to stop clobbering .config!
# cp .config /usr/share/kernel-package/config
# rm -rf /linux/debian/
#cp /etc/kernel-pkg.conf ~/.kernel-pkg.conf
# cp /kernel-config/* /usr/share/kernel-package/Config/
# CONFDIR=/kernel-config/ DEB_HOST_ARCH=arm64 nohup make-kpkg --rootcmd fakeroot --arch arm64 --cross-compile aarch64-linux-gnu- --revision=1.0 --initrd -j9 kernel_image
# cp /*.deb /linux/
