FROM debian:latest

COPY sources.list /etc/apt/sources.list
RUN apt-get update
RUN apt-get -y --no-install-recommends --no-install-suggests install ltsp-server
RUN apt-get -y --auto-remove purge ltsp-server-standalone
RUN apt-get -y install dnsmasq
EXPOSE 67/udp 69 69/udp
CMD dnsmasq --conf-file=/pxe/pxe.conf --no-daemon