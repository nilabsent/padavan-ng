SRC_NAME=minidlna-1.3.3
SRC_URL=https://sourceforge.net/projects/minidlna/files/minidlna/1.3.3/$(SRC_NAME).tar.gz
THISDIR = $(shell pwd)

DLNA_CFLAGS  += -ffunction-sections -fdata-sections -fvisibility=hidden
DLNA_CFLAGS  += -Os -Wall -g -D_GNU_SOURCE -D_FILE_OFFSET_BITS=64
DLNA_CFLAGS  += -I$(STAGEDIR)/include

DLNA_LDFLAGS += -Wl,--gc-sections
DLNA_LDFLAGS += -L$(STAGEDIR)/lib

DLNA_LIBS += -ldl -lm -lpthread -lz -lexif -ljpeg -lsqlite3 -lid3tag -lFLAC -lvorbis -logg -lavformat -lavcodec -lavutil

all: download_test extract_test config_test
#all: config_test
	$(MAKE) -j$(HOST_NCPU) -C $(SRC_NAME)

download_test:
	( if [ ! -f $(SRC_NAME).tar.gz ]; then \
		wget -t5 -T20 --no-check-certificate -O $(SRC_NAME).tar.gz $(SRC_URL) || rm -f $(SRC_NAME).tar.gz; \
	fi )

extract_test:
	( if [ ! -d $(SRC_NAME) ]; then \
		tar zxf $(SRC_NAME).tar.gz; \
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
	./autogen.sh ; \
	ac_cv_lib_avformat_av_open_input_file=yes \
	CFLAGS="$(DLNA_CFLAGS)" LDFLAGS="$(DLNA_LDFLAGS)" LIBS="$(DLNA_LIBS)" \
	./configure \
		--prefix=/usr \
		--disable-nls \
		--enable-asus \
		--enable-tivo \
		--with-libiconv-prefix=$(STAGEDIR) \
		--with-log-path=/mnt/minidlna \
		--with-db-path=/mnt/minidlna \
		--with-os-name="Linux" \
		--with-os-version="Linux/Cross_compiled" \
		--with-os-url="http://www.kernel.org/" \
		--host=$(HOST_TARGET) \
		--build=$(HOST_BUILD) ; \
	)

clean:
	if [ -f $(SRC_NAME)/Makefile ] ; then \
		$(MAKE) -C $(SRC_NAME) distclean ; \
	fi ; \
	rm -f config_done

romfs:
	$(ROMFSINST) $(THISDIR)/$(SRC_NAME)/minidlnad /usr/bin/minidlnad
