# https://www.wireguard.com
# https://github.com/amnezia-vpn

SRC_VER = 1.0.20260223
SRC_NAME = wireguard-tools-$(SRC_VER)
SRC_URL = https://github.com/WireGuard/wireguard-tools/archive/refs/tags/v$(SRC_VER).tar.gz

ifeq ($(CONFIG_FIRMWARE_INCLUDE_AMNEZIAWG),y)
SRC_VER = 3.1.20260812
SRC_NAME = amneziawg-tools-$(SRC_VER)
SRC_URL = https://github.com/amnezia-vpn/amneziawg-tools/archive/refs/tags/v$(SRC_VER).tar.gz
endif

CFLAGS += -ffunction-sections -fdata-sections -fvisibility=hidden
LDFLAGS += -Wl,--gc-sections

all: download_test extract_test config_test
	$(MAKE) -j$(HOST_NCPU) -C $(SRC_NAME)/src

download_test:
	( if [ ! -f $(SRC_NAME).tar.gz ]; then \
		wget -t5 -T20 --no-check-certificate -O $(SRC_NAME).tar.gz $(SRC_URL) || rm -f $(SRC_NAME).tar.gz; \
	fi )

extract_test:
	( if [ ! -d $(SRC_NAME) ]; then \
		tar -xf $(SRC_NAME).tar.gz; \
	fi )

config_test:
	( if [ -f ./config_done ]; then \
		echo "the same configuration"; \
	else \
		touch config_done; \
	fi )

clean:
	( for i in `ls -d */`; do \
		if [ -f $$i/src/Makefile ]; then \
			$(MAKE) -C $$i/src clean; \
		fi \
	done )
	rm -f config_done

romfs:
	$(ROMFSINST) $(SRC_NAME)/src/wg /usr/sbin/wg
	$(ROMFSINST) -p +x /usr/bin/wgs.sh
	$(ROMFSINST) -p +x /usr/bin/wgc.sh
ifeq ($(CONFIG_FIRMWARE_INCLUDE_AMNEZIAWG),y)
	$(ROMFSINST) -d /www/amneziawg.json
endif
