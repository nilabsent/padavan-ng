SRC_NAME = wget-1.20.3
SRC_URL = http://mirror.tochlab.net/pub/gnu/wget/wget-1.20.3.tar.gz
THISDIR = $(shell pwd)

all: download_test extract_test config_test
	$(MAKE) -j$(HOST_NCPU) -C $(SRC_NAME)

download_test:
	( if [ ! -f $(SRC_NAME).tar.gz ]; then \
		wget -t5 --timeout=20 --no-check-certificate -O $(SRC_NAME).tar.gz $(SRC_URL); \
	fi )

extract_test:
	( if [ ! -d $(SRC_NAME) ]; then \
		tar zxf $(SRC_NAME).tar.gz; \
	fi )

config_test:
	( if [ -f ./config_done ]; then \
		echo "the same configuration"; \
	else \
		make configure && touch config_done; \
	fi )

configure:
	( cd $(SRC_NAME) ; \
	LD="$(CC)" \
	./configure \
		--prefix=/usr \
		--sysconfdir=/usr/etc_ro \
		--with-ssl=openssl \
		--disable-nls \
		--host=$(HOST_TARGET) \
		--build=$(HOST_BUILD) ; \
	)

clean:
	if [ -f $(SRC_NAME)/Makefile ] ; then \
		$(MAKE) -C $(SRC_NAME) distclean ; \
	fi ; \
	rm -f config_done

romfs:
	$(ROMFSINST) -p +x $(THISDIR)/$(SRC_NAME)/src/wget /usr/bin/wget
	mkdir -p $(INSTALLDIR)/etc_ro/ssl/certs
	$(ROMFSINST) -p $(THISDIR)/wgetrc /etc_ro/wgetrc
