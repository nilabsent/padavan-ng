# https://github.com/bol-van/zapret2

SRC_VER = 1.0.4
SRC_NAME = zapret2-$(SRC_VER)
SRC_URL = https://github.com/bol-van/zapret2/archive/refs/tags/v$(SRC_VER).tar.gz

CFLAGS += -DZAPRET_GH_VER=v$(SRC_VER) -DZAPRET_GH_HASH=release
CFLAGS += -I$(STAGEDIR)/include/luajit-2.1
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
	$(ROMFSINST) -p +x $(SRC_NAME)/binaries/my/nfqws2 /usr/bin/nfqws2
	$(ROMFSINST) -d $(SRC_NAME)/lua/zapret-antidpi.lua /usr/share/zapret/lua/zapret-antidpi.lua
	$(ROMFSINST) -d $(SRC_NAME)/lua/zapret-auto.lua /usr/share/zapret/lua/zapret-auto.lua
	$(ROMFSINST) -d $(SRC_NAME)/lua/zapret-lib.lua /usr/share/zapret/lua/zapret-lib.lua
	$(ROMFSINST) -d $(SRC_NAME)/lua/zapret-obfs.lua /usr/share/zapret/lua/zapret-obfs.lua
