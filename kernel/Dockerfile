FROM debian:buster

ADD sources.list /etc/apt/sources.list
RUN dpkg --add-architecture armhf
RUN dpkg --add-architecture arm64
RUN apt-get update
RUN apt-get install --no-install-recommends --no-install-suggests -y crossbuild-essential-armhf crossbuild-essential-arm64
RUN apt-get install -y git make kernel-package
RUN apt-get install -y --no-install-recommends --no-install-suggests bison flex libelf-dev libssl-dev fakeroot
ADD build.sh /build.sh
CMD ["/build.sh"]
