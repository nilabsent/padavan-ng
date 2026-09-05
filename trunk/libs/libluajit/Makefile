# https://github.com/LuaJIT

SRC_NAME = luajit-2.1-24c20c9
SRC_URL = https://github.com/LuaJIT/LuaJIT/archive/refs/heads/v2.1.tar.gz
CFLAGS += -I$(STAGEDIR)/include -L$(STAGEDIR)/lib -DLUAJIT_DISABLE_FFI -DLUAJIT_DISABLE_GC64

all: download_test extract_test
	$(MAKE) -j$(HOST_NCPU) -C $(SRC_NAME) \
		HOST_CC="$(HOSTCC) -m32 $(CFLAGS)" \
		CROSS="$(CROSS_COMPILE)" \
		DPREFIX=/ \
		PREFIX=/ \
		TARGET_SYS=Linux \
		BUILDMODE=static

download_test:
	( if [ ! -f $(SRC_NAME).tar.gz ]; then \
		wget -t5 -T20 --no-check-certificate -O $(SRC_NAME).tar.gz $(SRC_URL) \
			|| rm -f $(SRC_NAME).tar.gz; \
	fi )

extract_test:
	( if [ ! -d $(SRC_NAME) ]; then \
		mkdir -p $(SRC_NAME) \
			&& tar -zx --strip-components=1 -f $(SRC_NAME).tar.gz -C $(SRC_NAME); \
	fi )

clean:
	if [ -f $(SRC_NAME)/Makefile ] ; then \
		$(MAKE) -C $(SRC_NAME) clean; \
	fi ; \

install:
	$(MAKE) -C $(SRC_NAME) install \
		TARGET_SYS=Linux \
		DPREFIX=$(STAGEDIR) \
		PREFIX=$(STAGEDIR) \
		DESTDIR=$(STAGEDIR);

romfs:
