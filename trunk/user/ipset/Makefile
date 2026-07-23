# https://ipset.netfilter.org

SRC_NAME=ipset-7.24
SRC_URL=https://ipset.netfilter.org/$(SRC_NAME).tar.bz2

CFLAGS += -ffunction-sections -fdata-sections -fvisibility=hidden

all: download_test extract_test config_test
	$(MAKE) -j$(HOST_NCPU) -C $(SRC_NAME)
	$(MAKE) modules -j$(HOST_NCPU) -C $(SRC_NAME)

download_test:
	( if [ ! -f $(SRC_NAME).tar.bz2 ]; then \
		wget -t5 -T20 --no-check-certificate -O $(SRC_NAME).tar.bz2 $(SRC_URL) || rm -f $(SRC_NAME).tar.bz2; \
	fi )

extract_test:
	( if [ ! -d $(SRC_NAME) ]; then \
		tar xjf $(SRC_NAME).tar.bz2; \
		cat patches/*.patch | patch -d $(SRC_NAME) -r - -N -p1; \
	fi )

config_test:
	( if [ -f ./config_done ]; then \
		echo "the same configuration"; \
	else \
		make configure && touch config_done; \
	fi )

configure:
	( cd $(SRC_NAME) ; \
	./autogen.sh ; \
	PKG_CONFIG_PATH=$(STAGEDIR)/lib/pkgconfig \
	./configure \
		--prefix= \
		--enable-static \
		--disable-shared \
		libmnl_CFLAGS="-I$(STAGEDIR)/include" \
		libmnl_LIBS="-L$(STAGEDIR)/lib -lmnl" \
		--with-kmod=yes \
		--with-kbuild=$(ROOTDIR)/$(LINUXDIR) \
		--host=$(HOST_TARGET) \
		--build=$(HOST_BUILD) ; \
	)

clean:
	if [ -f $(SRC_NAME)/Makefile ] ; then \
		$(MAKE) -C $(SRC_NAME) modules_clean ; \
		$(MAKE) -C $(SRC_NAME) distclean ; \
	fi ; \
	rm -f config_done

romfs:
	$(ROMFSINST) $(SRC_NAME)/src/ipset /sbin/ipset
	$(ROMFSINST) -p +x /usr/bin/ipset-import.sh
	$(ROMFSINST) -p +x /usr/bin/ipset-download.sh
	$(ROMFSINST) -p +x /usr/bin/ipset-flush-dnsmasq.sh
