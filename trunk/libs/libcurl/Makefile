SRC_NAME=curl-8.12.1
SRC_URL=https://github.com/curl/curl/releases/download/curl-8_12_1/$(SRC_NAME).tar.xz
THISDIR = $(shell pwd)

all: download_test extract_test config_test
#all: config_test
	$(MAKE) -j$(HOST_NCPU) -C $(SRC_NAME)

download_test:
	( if [ ! -f $(SRC_NAME).tar.xz ]; then \
		wget -t5 -T20 --no-check-certificate -O $(SRC_NAME).tar.xz $(SRC_URL) || rm -f $(SRC_NAME).tar.xz; \
	fi )

extract_test:
	( if [ ! -d $(SRC_NAME) ]; then \
		tar --xz -xf $(SRC_NAME).tar.xz; \
		[ ! -d $(THISDIR)/patches ] || \
		find $(THISDIR)/patches -type f -name '*.patch' -print0 \
		  | sort -z \
		  | xargs -r -t -0 -n 1 patch -d $(SRC_NAME) -p1 -i; \
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
		--prefix= \
		--disable-static \
		--enable-openssl-auto-load-config \
		--enable-shared \
		$(if $(CONFIG_IPV6),--enable-ipv6,--disable-ipv6) \
		--disable-gopher \
		--disable-ldap \
		--disable-ldaps \
		--disable-rt \
		--disable-rtsp \
		--disable-telnet \
		--disable-tftp \
		--disable-smb \
		--disable-smtp \
		--disable-pop3 \
		--disable-imap \
		--disable-sspi \
		--disable-dict \
		--disable-ares \
		--disable-debug \
		--disable-curldebug \
		--disable-manual \
		--disable-verbose \
		--disable-tls-srp \
		--disable-libcurl-option \
		--disable-threaded-resolver \
		--disable-mqtt \
		--disable-alt-svc \
		--disable-hsts \
		--disable-ntlm \
		--disable-docs \
		--without-brotli \
		--without-hyper \
		--without-gnutls \
		--without-ca-path \
		--without-ca-fallback \
		--without-cyassl \
		--without-default-ssl-backend \
		--without-libidn2 \
		--without-libpsl \
		--without-librtmp \
		--without-libssh \
		--without-libssh2 \
		--without-krb4 \
		--with-nghttp2 \
		--without-nghttp3 \
		--without-ngtcp2 \
		--without-nss \
		--without-mbedtls \
		--without-mesalink \
		--without-polarssl \
		--without-schannel \
		--without-wolfssl \
		--without-winidn \
		--without-winssl \
		--without-zsh-functions-dir \
		--with-random=/dev/urandom \
		--with-zlib=$(STAGEDIR) \
		--with-ssl=$(STAGEDIR) \
		--with-ca-bundle=/etc/ssl/cert.pem \
		--host=$(HOST_TARGET) \
		--build=$(HOST_BUILD) ; \
	)

clean:
	if [ -f $(SRC_NAME)/Makefile ] ; then \
		$(MAKE) -C $(SRC_NAME) distclean ; \
	fi ; \
	rm -f config_done

install:
	$(MAKE) -C $(SRC_NAME) install DESTDIR=$(STAGEDIR)

romfs:
ifeq ($(CONFIG_FIRMWARE_INCLUDE_CURL),y)
	$(ROMFSINST) -d $(DESTDIR)/bin/curl /usr/bin/curl
endif
	cp -fP $(DESTDIR)/lib/libcurl.so* $(ROMFSDIR)/lib
