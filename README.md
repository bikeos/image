# image

A repository for mastering bikeos disk images with vmdb2 and docker.

## Building an image

The image is build through a sequence of `make` invocations.

### Docker containers

First, build the docker containers for vmdb2 and apt-cacher-ng:

```sh
make docker-apt-cache
make docker-vmdb2
```

### apt-cacher-ng

The build scripts are hardwired to a localhost debian repo because the build is going to constantly break. Start the cache in the foreground:

```sh
make apt-cache
```

Cache statistics are available through a web interface on `http://localhost:3142/acng-report.html`.

### Image

To create the image `volumes/vm/vm.img` (or `rpi3`, instead of `vm`, for a raspberrypi build):

```sh
make vm
```

Note: vmdb2 and debootstrap need docker `--privileged` permissions to configure `/dev/mapper` settings. If the host system depends on loopbacks or `/dev/mapper`, this stage could break things!

A cache of the rootfs is kept in `/tmp/vm.tar.gz` for fast rebuilds.

## Run the OS

### Inside a VM

Launch the VM image with qemu. It will auto-detect USB wifi devices for pass-through:

```sh
make qemu-vm
```

Log in with user `root`, password `bicycle`.

### On a RaspberryPI 3

Format the system microsd card (>2GB) and the data sd card:

```sh
dd if=volumes/vm/rpi3.img of=/dev/<system-sdcard> bs=4M
mkfs.nilfs2 /dev/<data-sdcard>1
```

Install the system card in the microsd card slot. Attach the data card through a USB card reader.
