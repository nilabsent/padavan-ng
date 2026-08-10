# https://busybox.net

SRC_NAME = busybox-1.38.0
SRC_URL = https://busybox.net/downloads/$(SRC_NAME).tar.bz2

CFLAGS += -ffunction-sections -fdata-sections -fvisibility=hidden
LDFLAGS += -Wl,--gc-sections

all: download_test extract_test
	cp -fL $(STAGEDIR)/busybox.config $(SRC_NAME)/.config
	$(MAKE) -j$(HOST_NCPU) -C $(SRC_NAME)

download_test:
	( if [ ! -f $(SRC_NAME).tar.bz2 ]; then \
		wget -t5 -T40 --no-check-certificate -O $(SRC_NAME).tar.bz2 $(SRC_URL) \
			|| rm -f $(SRC_NAME).tar.bz2; \
	fi )

extract_test:
	( if [ ! -d $(SRC_NAME) ]; then \
		tar xjf $(SRC_NAME).tar.bz2; \
		cat patches/*.patch | patch -d $(SRC_NAME) -r - -N -p1; \
	fi )

clean:
	$(MAKE) -C $(SRC_NAME) distclean

romfs:
	$(MAKE) -C $(SRC_NAME) CONFIG_PREFIX=$(ROMFSDIR) install
