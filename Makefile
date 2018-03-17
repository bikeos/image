VOLRPI3=volumes/rpi3
VOLVM=volumes/vm
VOLAPTCACHE=volumes/apt-cache

.PHONY: vm
vm: $(VOLVM)/vm.img

bikeos/bin/bosd-amd64:
	go build -o $@ github.com/bikeos/bosd/cmd/bosd

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

$(VOLRPI3)/rpi3.img:
	mkdir -p $(VOLRPI3)
	docker run --rm -i -t --privileged \
		-v /dev:/dev \
		-v /dev/mapper:/dev/mapper \
		-v /tmp:/tmp \
		-v `pwd`/$(VOLRPI3):/$(VOLRPI3) -v `pwd`/plat/rpi3:/spec	\
		-w /$(VOLRPI3) \
		bikeos:vmdb2 \
		/vmdb2/vmdb2 \
		/spec/raspi3.yaml \
		--verbose \
		--output rpi3.img \
		--log rpi3.log

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
		-p 3142:3142 
		bikeos:apt-cache

.PHONY: docker-apt-cache
docker-apt-cache:
	docker build -t bikeos:apt-cache cache/

.PHONY: docker-vmdb2
docker-vmdb2:
	docker build -t bikeos:vmdb2 plat/

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