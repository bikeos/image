FROM debian:buster

RUN apt update
RUN apt-get install -y	kpartx parted qemu-utils qemu-user-static \
			python3-cliapp python3-jinja2 python3-yaml \
			git
RUN apt-get install -y	squashfs-tools dosfstools nilfs-tools
RUN apt-get install -y	debootstrap
RUN git clone http://github.com/bikeos/vmdb2.git
RUN cd /vmdb2 && git fetch && git checkout bikeos # cache bust 1
CMD ["/vmdb2/vmdb2"]
# TODO use cache from apt-cacher instance