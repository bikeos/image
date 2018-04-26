VOLRPI3=volumes/rpi3
VOLOPI0=volumes/opi0
VOLVM=volumes/vm
VOLAPTCACHE=volumes/apt-cache
VOLTFTP=volumes/tftp

.PHONY: vm
vm: $(VOLVM)/vm.img

bikeos/bin/bosd-amd64:
	go build -o $@ github.com/bikeos/bosd/cmd/bosd

bikeos/bin/bosd-arm64:
	GOARCH=arm64 go build -o $@ github.com/bikeos/bosd/cmd/bosd

bikeos/bin/bosd-arm:
	GOARCH=arm go build -o $@ github.com/bikeos/bosd/cmd/bosd

$(VOLVM)/vm.img: bikeos/bin/bosd-amd64 plat/vm/vm.yaml
	mkdir -p $(VOLVM)
	rm -f $(VOLVM)/vm.img.tmp
	touch $(VOLVM)/vm.img.tmp
	docker run --rm -i -t --privileged \
		--net host \
		-v /dev:/dev \
		-v /dev/mapper:/dev/mapper \
		-v /tmp:/tmp \
		-v `pwd`/$(VOLVM):/$(VOLVM) \
		-v `pwd`/plat/vm:/spec	\
		-v `pwd`/bikeos:/bikeos \
		-w /$(VOLVM) \
		bikeos:vmdb2 \
		bash -c " \
		/vmdb2/vmdb2 \
		/spec/vm.yaml \
		--verbose \
		--output vm.img.tmp \
		--log vm.log \
		--rootfs-tarball /tmp/vm.tar.gz"
	mv $(VOLVM)/vm.img.tmp $(VOLVM)/vm.img

.PHONY: rpi3
rpi3: $(VOLRPI3)/rpi3.img

$(VOLRPI3)/rpi3.img:bikeos/bin/bosd-arm64 plat/rpi3/rpi3.yaml
	mkdir -p $(VOLRPI3)
	rm -f $(VOLRPI3)/rpi3.img.tmp
	touch $(VOLRPI3)/rpi3.img.tmp
	docker run --rm -i -t --privileged \
		--net host \
		-v /dev:/dev \
		-v /dev/mapper:/dev/mapper \
		-v /tmp:/tmp \
		-v `pwd`/$(VOLRPI3):/$(VOLRPI3) \
		-v `pwd`/plat/rpi3:/spec	\
		-v `pwd`/bikeos:/bikeos \
		-w /$(VOLRPI3) \
		bikeos:vmdb2 \
		/vmdb2/vmdb2 \
		/spec/rpi3.yaml \
		--verbose \
		--output rpi3.img.tmp \
		--log rpi3.log \
		--rootfs-tarball /tmp/rpi3.tar.gz
	mv $(VOLRPI3)/rpi3.img.tmp $(VOLRPI3)/rpi3.img

.PHONY: opi0
opi0: $(VOLOPI0)/opi0.img
	mkdir -p exports/boot-opi0
	scripts/img_exportfs $^ p1 exports/boot-opi0
	dd of=$^ if=exports/boot-opi0/u-boot-sunxi-with-spl.bin bs=1024 seek=8 conv=notrunc
	sudo umount exports/boot-opi0


$(VOLOPI0)/opi0.img: bikeos/bin/bosd-arm plat/opi0/opi0.yaml plat/opi0/boot.cmd
	mkdir -p $(VOLOPI0)
	rm -f $(VOLOPI0)/opi0.img.tmp
	touch $(VOLOPI0)/opi0.img.tmp
	docker run --rm -i -t --privileged \
		--net host \
		-v /dev:/dev \
		-v /dev/mapper:/dev/mapper \
		-v /tmp:/tmp \
		-v `pwd`/$(VOLOPI0):/$(VOLOPI0) \
		-v `pwd`/plat/opi0:/spec	\
		-v `pwd`/bikeos:/bikeos \
		-w /$(VOLOPI0) \
		bikeos:vmdb2 \
		/vmdb2/vmdb2 \
		/spec/opi0.yaml \
		--verbose \
		--output opi0.img.tmp \
		--log opi0.log \
		--rootfs-tarball /tmp/opi0.tar.gz
	mv $(VOLOPI0)/opi0.img.tmp $(VOLOPI0)/opi0.img

.PHONY: clean-dev
clean-dev:
	sudo dmsetup remove /dev/mapper/loop*
	sudo losetup -D

.PHONY: apt-cache
apt-cache:
	mkdir -p $(VOLAPTCACHE)/{log,cache}
	docker run --rm -i -t \
		-v `pwd`/$(VOLAPTCACHE)/cache:/var/cache/apt-cacher-ng/ \
		-v `pwd`/$(VOLAPTCACHE)/log:/var/log/apt-cacher-ng/ \
		-u `id -u`:`id -u` \
		-p 3142:3142 \
		bikeos:apt-cache

.PHONY: docker-apt-cache
docker-apt-cache:
	docker build -t bikeos:apt-cache cache/

$(VOLTFTP)/tftpboot: $(VOLRPI3)/rpi3.img
	mkdir -p $@
	scripts/img_cp $(VOLRPI3)/rpi3.img  p1 "*" $@

.PHONY: pxe
pxe: $(VOLTFTP)/tftpboot
	docker run --privileged --rm -i -t --net host \
		-v `pwd`/$(VOLTFTP)/tftpboot:/var/lib/tftpboot \
		-v `pwd`/pxe:/pxe  \
		-u `id -u`:`id -u` \
		bikeos:pxe

.PHONY:
docker-pxe:
	docker build --rm --network=host -t bikeos:pxe pxe/

.PHONY:
export-root-opi0:
	mkdir -p exports/root-opi0
	scripts/img_exportfs $(VOLOPI0)/opi0.img p2 exports/root-opi0

.PHONY:
export-boot-opi0:
	mkdir -p exports/boot-opi0
	scripts/img_exportfs $(VOLOPI0)/opi0.img p1 exports/boot-opi0

.PHONY:
export-rpi3:
	mkdir -p exports/root-rpi3
	scripts/img_exportfs $(VOLRPI3)/rpi3.img p2 exports/root-rpi3

.PHONY:
diod-rootfs:
	docker run --privileged --rm -i -t --net host \
		-v `pwd`/exports:/exports \
		-v `pwd`/diod:/diod \
		-p 5640:5640 \
		bikeos:diod

.PHONY:
rsync-opi0:
	sudo rsync -r -c -l -v exports/root-opi0/ tgt

.PHONY:
docker-diod:
	docker build --rm --network=host -t bikeos:diod diod/

.PHONY: docker-vmdb2
docker-vmdb2:
	docker build -t bikeos:vmdb2 plat/

.PHONY: build-kernel
build-kernel:
	docker run --rm -t -i \
		-v `pwd`/linux:/linux  \
		-v `pwd`/kernel:/kernel \
		-u `id -u`:`id -u` \
		bikeos:kernel /kernel/build.sh

.PHONY: docker-kernel
docker-kernel:
	docker build --network=host -t bikeos:kernel kernel/


.PHONY: binfmts
binfmts:
	sudo mount -t binfmt_misc none /proc/sys/fs/binfmt_misc || true
	docker run --rm -i -t bikeos:vmdb2 update-binfmts --display
	docker run --rm -i -t --privileged bikeos:vmdb2 update-binfmts --enable qemu-aarch64


# TODO: ncurses/console mode
# auto-detects some usb-peripherals, overrides clock for gps testing
# -net user,vlan=0 -net nic
QEMUCMD=qemu-system-x86_64 -enable-kvm -rtc base=1990-01-01,clock=vm -net none
.PHONY: qemu-vm
qemu-vm: vm
	$(QEMUCMD)	-hda $(VOLVM)/vm.img -smp 2 -m 512 \
			-usb -device usb-ehci,id=ehci \
			$(shell lsusb | egrep "(Ralink|Realtek|IMC)" | \
					cut -f1 -d: | \
					awk '{ print "-device usb-host,hostbus="$$2",hostaddr="$$4",bus=ehci.0" } ' | \
					sed 's/=0*/=/g') \
			$(shell lsusb | egrep "(U-Blox)" | \
					cut -f1 -d: | \
					awk '{ print "-device usb-host,hostbus="$$2",hostaddr="$$4",bus=usb-bus.0" } ' | \
					sed 's/=0*/=/g')