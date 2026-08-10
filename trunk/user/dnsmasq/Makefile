# https://thekelleys.org.uk

SRC_NAME = dnsmasq-2.93
SRC_URL  = https://thekelleys.org.uk/dnsmasq/$(SRC_NAME).tar.xz

COPTS = -DHAVE_BROKEN_RTC -DNO_INOTIFY -DNO_AUTH -DNO_LOOP -DNO_DUMPFILE -DNO_ID
COPTS += $(if $(CONFIG_IPV6),-DCONFIG_IPV6,-DNO_DHCP6)
COPTS += $(if $(CONFIG_USB_SUPPORT),,-DNO_TFTP)
COPTS += $(if $(CONFIG_FIRMWARE_INCLUDE_IPSET),,-DNO_IPSET)
COPTS += $(if $(CONFIG_FIRMWARE_ENABLE_DNSMASQ_REGEX),-DHAVE_REGEX -DHAVE_REGEX_IPSET,)

CFLAGS += -ffunction-sections -fdata-sections -fvisibility=hidden
LDFLAGS += -Wl,--gc-sections

all: download_test extract_test
	$(MAKE) -j$(HOST_NCPU) -C $(SRC_NAME) COPTS="$(COPTS)" CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)"

download_test:
	( if [ ! -f $(SRC_NAME).tar.xz ]; then \
		wget -t5 -T20 --no-check-certificate -O $(SRC_NAME).tar.xz $(SRC_URL) \
			|| rm -f $(SRC_NAME).tar.xz; \
	fi )

extract_test:
	( if [ ! -d $(SRC_NAME) ]; then \
		tar xJf $(SRC_NAME).tar.xz; \
		cat patches/*.patch | patch -d $(SRC_NAME) -r - -N -p1; \
	fi )

clean:
	$(MAKE) -C $(SRC_NAME) clean

romfs:
	$(ROMFSINST) $(SRC_NAME)/src/dnsmasq /usr/sbin/dnsmasq
