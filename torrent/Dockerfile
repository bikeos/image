FROM debian:buster

WORKDIR /tmp

RUN 	echo 'deb http://localhost:3142/debian buster main contrib non-free' >/etc/apt/sources.list && \
	apt-get update && \
	apt install --no-install-recommends --no-install-suggests -y \
	ctorrent bittorrent cvs g++ gcc git make zlib1g zlib1g-dev \
	&& cvs -d :pserver:cvs@cvs.fefe.de:/cvs -z9 co libowfat \
	&& cd libowfat && make && cd ../ \
	&& git clone git://erdgeist.org/opentracker \
	&& cd opentracker && FEATURES=-DWANT_ACCESSLIST_WHITE make -j4 \
	&& mv /tmp/opentracker/opentracker /bin/ \
	\
	&& apt remove -y cvs g++ gcc git make zlib1g-dev \
	&& rm -rf /var/cache/apk/* /tmp/*
EXPOSE 6969
COPY ./opentracker.conf /etc/opentracker/opentracker.conf
COPY ./run.sh /run.sh
CMD /run.sh