FROM ubuntu:focal

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -qy apt-utils
RUN apt-get -qy install locales
RUN locale-gen --no-purge en_US.UTF-8 ru_RU.UTF-8
ENV LC_ALL en_US.UTF-8


RUN apt-get install -qy \
	git \
	build-essential \
	gawk \
	pkg-config \
	gettext \
	automake \
	autoconf \
	autopoint \
	libtool \
	bison \
	flex \
	cmake \
	kmod \
	zlib1g-dev \
	libgmp3-dev \
	libmpfr-dev \
	libmpc-dev \
	texinfo \
	mc \
	libncurses5-dev \
	nano \
	vim \
	wget \
	autopoint \
	gperf \
	python-docutils \
	help2man \
	libtool-bin \
	libtool-doc

RUN git clone https://gitlab.com/dm38/padavan-ng.git --depth=1 /opt/padavan-ng

RUN cd /opt/padavan-ng/toolchain && ./clean_sources.sh && ./build_toolchain.sh
