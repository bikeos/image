FROM debian:latest

COPY sources.list /etc/apt/sources.list
RUN apt-get update
RUN apt-get -y --no-install-recommends --no-install-suggests install diod
EXPOSE 564/tcp 5640/tcp
CMD diod --config-file /diod/diod.conf -f