setenv bootargs console=ttyS0,115200 root=/dev/mmcblk0p2 rootwait panic=10 initrd=0x50000000,32M
setenv stdout serial
setenv stderr serial
load mmc 0:1 0x43000000 sun8i-h2-plus-orangepi-zero.dtb
load mmc 0:1 0x42000000 zImage
load mmc 0:1 0x50000000 initrd.img
bootz 0x42000000 - 0x43000000