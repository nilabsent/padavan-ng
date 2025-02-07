SRC_NAME=openvpn-2.6.13
SRC_URL=https://github.com/OpenVPN/openvpn/archive/refs/tags/v2.6.13.tar.gz

CFLAGS += -ffunction-sections -fdata-sections -fvisibility=hidden
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
		tar -xf $(SRC_NAME).tar.gz; \
		patch -d $(SRC_NAME) -p1 -i ../openvpn-orig.patch; \
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
	IFCONFIG=/sbin/ifconfig \
	ROUTE=/sbin/route \
	NETSTAT=/bin/netstat \
	LIBNL_GENL_CFLAGS=-I$(STAGEDIR)/include/libnl3 \
	LIBNL_GENL_LIBS="-L$(STAGEDIR)/lib -lnl-genl-3" \
	LIBCAPNG_CFLAGS=-I$(STAGEDIR)/include \
	LIBCAPNG_LIBS="-L$(STAGEDIR)/lib -lcap-ng" \
	OPENSSL_CFLAGS=-I$(STAGEDIR)/include/openssl \
	OPENSSL_LIBS="-L$(STAGEDIR)/lib -lssl -lcrypto" \
	./configure \
		--prefix=/usr \
		--disable-debug \
		--disable-plugins \
		--disable-pkcs11 \
		--disable-ofb-cfb \
		--disable-selinux \
		--disable-systemd \
		--disable-iproute2 \
		--disable-unit-tests \
		--disable-management \
		--disable-lz4 \
		--disable-dco \
		--enable-small \
		--enable-fragment \
		--enable-lzo \
		--with-crypto-library=openssl \
		--with-sysroot=$(STAGEDIR) \
		--host=$(HOST_TARGET) \
		--build=$(HOST_BUILD) ; \
	)

clean:
	if [ -f $(SRC_NAME)/Makefile ] ; then \
		$(MAKE) -C $(SRC_NAME) distclean ; \
	fi ; \
	rm -f config_done

romfs:
	$(ROMFSINST) $(SRC_NAME)/src/openvpn/openvpn /usr/sbin/openvpn
	$(ROMFSINST) -p +x /usr/bin/openvpn-cert.sh
