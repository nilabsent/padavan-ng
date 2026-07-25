# https://github.com/bol-van/zapret

SRC_VER = 72.13
SRC_NAME = zapret-$(SRC_VER)
SRC_URL = https://github.com/bol-van/zapret/archive/refs/tags/v$(SRC_VER).tar.gz

CFLAGS += -DZAPRET_GH_VER=v$(SRC_VER) -DZAPRET_GH_HASH=release
CFLAGS += $(if $(CONFIG_IPV6),-DUSE_IPV6,)
CFLAGS += -ffunction-sections -fdata-sections -fvisibility=hidden
LDFLAGS += -Wl,--gc-sections

all: download_test extract_test
	$(MAKE) -j$(HOST_NCPU) -C $(SRC_NAME)

download_test:
	( if [ ! -f $(SRC_NAME).tar.gz ]; then \
		wget -t5 -T20 --no-check-certificate -O $(SRC_NAME).tar.gz $(SRC_URL) || rm -f $(SRC_NAME).tar.gz; \
	fi )

extract_test:
	( if [ ! -d $(SRC_NAME) ]; then \
		tar zxf $(SRC_NAME).tar.gz; \
		cat patches/*.patch | patch -d $(SRC_NAME) -r - -N -p1; \
	fi )

clean:
	( if [ -f $(SRC_NAME)/Makefile ] ; then \
		$(MAKE) -C $(SRC_NAME) clean ; \
	fi )

romfs:
	$(ROMFSINST) -p +x $(SRC_NAME)/binaries/my/nfqws /usr/bin/nfqws
