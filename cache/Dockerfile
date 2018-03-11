FROM debian:latest

RUN apt update
RUN apt-get install -y apt-cacher-ng avahi-daemon

RUN sed 's/# ForeGround: 0/ForeGround: 1/' -i /etc/apt-cacher-ng/acng.conf && \
    sed 's/# PassThroughPattern:.*this would allow.*/PassThroughPattern: .* #/' -i /etc/apt-cacher-ng/acng.conf

EXPOSE 3142/tcp
# /var/cache/apt-cacher-ng
# tail -f /var/log/apt-cacher-ng/*
CMD ["/usr/sbin/apt-cacher-ng", "-c", "/etc/apt-cacher-ng/"]