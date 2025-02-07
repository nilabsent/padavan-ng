SRC_NAME=tor-tor-0.4.8.13
SRC_URL=https://gitlab.torproject.org/tpo/core/tor/-/archive/tor-0.4.8.13/$(SRC_NAME).tar.gz

CFLAGS +=$(COPT) -ffunction-sections -fdata-sections -fvisibility=hidden
LDFLAGS += -Wl,--gc-sections

all: download_test extract_test config_test
#all: config_test
	$(MAKE) -j$(HOST_NCPU) -C $(SRC_NAME)

download_test:
	( if [ ! -f $(SRC_NAME).tar.gz ]; then \
		wget -t5 --timeout=20 --no-check-certificate -O $(SRC_NAME).tar.gz $(SRC_URL); \
	fi )

extract_test:
	( if [ ! -d $(SRC_NAME) ]; then \
		tar xzf $(SRC_NAME).tar.gz; \
	fi )

config_test:
	( if [ -f ./config_done ]; then \
		echo "the same configuration"; \
	else \
		make configure && touch config_done; \
	fi )

configure:
	( cd $(SRC_NAME) ; \
	autoreconf -fi ; \
	./configure \
		--prefix=/usr \
		--host=$(HOST_TARGET) \
		--build=$(HOST_BUILD) \
		--sysconfdir=/etc/storage \
		--disable-unittests \
		--disable-android \
		--disable-tool-name-check \
		--disable-gcc-hardening \
		--disable-asciidoc \
		--disable-systemd \
		--disable-lzma \
		--disable-zstd; \
	)

clean:
	if [ -f $(SRC_NAME)/Makefile ] ; then \
		$(MAKE) -C $(SRC_NAME) distclean ; \
	fi ; \
	rm -f config_done GeoLite2-Country.mmdb*

romfs:
	$(ROMFSINST) $(SRC_NAME)/src/app/tor /usr/sbin/tor
	$(ROMFSINST) -p +x /usr/bin/tor.sh
	mkdir -p $(INSTALLDIR)/usr/share/tor
ifeq ($(CONFIG_FIRMWARE_INCLUDE_TOR_GEOIP),y)
	$(ROMFSINST) /usr/share/tor/geoip
endif
ifeq ($(CONFIG_FIRMWARE_INCLUDE_TOR_GEOIPV6),y)
ifeq ($(CONFIG_FIRMWARE_ENABLE_IPV6),y)
	$(ROMFSINST) /usr/share/tor/geoip6
endif
endif
