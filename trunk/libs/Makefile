.EXPORT_ALL_VARIABLES:
.PHONY: all romfs clean

ifndef ROOTDIR
ROOTDIR=..
endif
ifndef ROMFSDIR
ROMFSDIR=$(ROOTDIR)/romfs
endif

UCLINUX_BUILD_LIB=1
-include $(LINUX_CONFIG)
include $(PROJECT_CONFIG)
include $(ARCH_CONFIG)

CFLAGS  += -ffunction-sections -fdata-sections
LDFLAGS += -Wl,--gc-sections

DESTDIR=$(ROOTDIR)/stage

dir_y =
dir_n =
dir_  =

LIBS_INCLUDE_LIBLZO=n
LIBS_INCLUDE_LIBNL=n
LIBS_INCLUDE_LIBCAP_NG=n
LIBS_INCLUDE_LIBSSL=n
LIBS_INCLUDE_LIBGETDNS=n
LIBS_INCLUDE_LIBYAML=n
LIBS_INCLUDE_LIBUSB_0=n
LIBS_INCLUDE_LIBUSB_1=n
LIBS_INCLUDE_LIBEVENT=n
LIBS_INCLUDE_MEDIA=n
LIBS_INCLUDE_LIBCURL=n
LIBS_INCLUDE_LIBSODIUM=n
LIBS_INCLUDE_LIBMBEDTLS=n
LIBS_INCLUDE_LIBCARES=n
LIBS_INCLUDE_LIBEV=n
STORAGE_ENABLED=n
QUIC_ENABLED=n

ifdef CONFIG_MMC_BLOCK
STORAGE_ENABLED=y
endif
ifdef CONFIG_BLK_DEV_SD
STORAGE_ENABLED=y
endif

ifeq ($(CONFIG_FIRMWARE_INCLUDE_ADB),y)
LIBS_INCLUDE_LIBSSL=y
endif

ifeq ($(CONFIG_FIRMWARE_ENABLE_HFS),y)
LIBS_INCLUDE_LIBSSL=y
endif

ifeq ($(CONFIG_FIRMWARE_INCLUDE_XUPNPD),y)
LIBS_INCLUDE_LIBSSL=y
endif

ifeq ($(CONFIG_FIRMWARE_INCLUDE_EAP_PEAP),y)
LIBS_INCLUDE_LIBSSL=y
endif

ifeq ($(CONFIG_FIRMWARE_INCLUDE_DDNS_SSL),y)
LIBS_INCLUDE_LIBSSL=y
endif

ifeq ($(CONFIG_FIRMWARE_INCLUDE_HTTPS),y)
LIBS_INCLUDE_LIBSSL=y
endif

ifeq ($(CONFIG_FIRMWARE_INCLUDE_OPENSSL_EXE),y)
LIBS_INCLUDE_LIBSSL=y
endif

ifeq ($(CONFIG_FIRMWARE_INCLUDE_SFTP),y)
LIBS_INCLUDE_LIBSSL=y
endif

ifeq ($(CONFIG_FIRMWARE_INCLUDE_OPENVPN),y)
LIBS_INCLUDE_LIBNL=y
LIBS_INCLUDE_LIBCAP_NG=y
LIBS_INCLUDE_LIBLZO=y
LIBS_INCLUDE_LIBSSL=y
endif

ifeq ($(CONFIG_FIRMWARE_INCLUDE_OPENSSH),y)
LIBS_INCLUDE_LIBSSL=y
endif

ifeq ($(CONFIG_FIRMWARE_INCLUDE_SSWAN),y)
LIBS_INCLUDE_LIBSSL=y
endif

ifeq ($(CONFIG_FIRMWARE_INCLUDE_STUBBY),y)
LIBS_INCLUDE_LIBSSL=y
LIBS_INCLUDE_LIBYAML=y
LIBS_INCLUDE_LIBGETDNS=y
endif

ifeq ($(CONFIG_FIRMWARE_INCLUDE_DOH),y)
LIBS_INCLUDE_LIBSSL=y
LIBS_INCLUDE_LIBCURL=y
LIBS_INCLUDE_LIBCARES=y
LIBS_INCLUDE_LIBEV=y
endif

ifeq ($(CONFIG_FIRMWARE_INCLUDE_CURL),y)
LIBS_INCLUDE_LIBSSL=y
LIBS_INCLUDE_LIBCURL=y
endif

ifeq ($(STORAGE_ENABLED),y)
ifeq ($(CONFIG_FIRMWARE_INCLUDE_TRANSMISSION),y)
LIBS_INCLUDE_LIBSSL=y
LIBS_INCLUDE_LIBEVENT=y
LIBS_INCLUDE_LIBCURL=y
endif
ifeq ($(CONFIG_FIRMWARE_INCLUDE_ARIA),y)
LIBS_INCLUDE_LIBSSL=y
endif
ifeq ($(CONFIG_FIRMWARE_INCLUDE_MINIDLNA),y)
LIBS_INCLUDE_MEDIA=y
endif
ifeq ($(CONFIG_FIRMWARE_INCLUDE_FIREFLY),y)
LIBS_BUILD_SHARED=y
LIBS_INCLUDE_MEDIA=y
endif
endif

ifdef CONFIG_USB_SUPPORT
LIBS_INCLUDE_LIBUSB_1=y
ifeq ($(CONFIG_FIRMWARE_INCLUDE_U2EC),y)
LIBS_INCLUDE_LIBUSB_0=y
endif
endif

ifdef CONFIG_MTD_UBI
LIBS_INCLUDE_LIBLZO=y
endif

ifeq ($(CONFIG_FIRMWARE_INCLUDE_TOR),y)
LIBS_INCLUDE_LIBSSL=y
LIBS_INCLUDE_LIBEVENT=y
endif

ifeq ($(CONFIG_FIRMWARE_INCLUDE_REDSOCKS2),y)
LIBS_INCLUDE_LIBEVENT=y
endif

ifneq (,$(filter y,$(CONFIG_FIRMWARE_INCLUDE_PRIVOXY) \
                   $(CONFIG_FIRMWARE_ENABLE_DNSMASQ_REGEX)))
LIBS_INCLUDE_LIBPCRE=y
endif

ifeq ($(CONFIG_FIRMWARE_INCLUDE_QUIC),y)
QUIC_ENABLED=y
endif

ifneq (,$(filter y,$(CONFIG_FIRMWARE_INCLUDE_DNSCRYPT)))
LIBS_INCLUDE_LIBSODIUM=y
endif

ifneq (,$(filter y,$(CONFIG_FIRMWARE_INCLUDE_SSREDIR) \
                   $(CONFIG_FIRMWARE_INCLUDE_SSLOCAL)))
LIBS_INCLUDE_LIBMBEDTLS=y
LIBS_INCLUDE_LIBSODIUM=y
LIBS_INCLUDE_LIBPCRE=y
LIBS_INCLUDE_LIBCARES=y
LIBS_INCLUDE_LIBEV=y
endif

ifneq (,$(filter y,$(QUIC_ENABLED) $(CONFIG_FIRMWARE_INCLUDE_OPENSSL_35)))
SSL_VER = 3.5
else ifeq ($(CONFIG_FIRMWARE_INCLUDE_OPENSSL_11),y)
SSL_VER = 1.1
else ifeq ($(CONFIG_FIRMWARE_INCLUDE_OPENSSL_10),y)
SSL_VER = 1.0
else
SSL_VER = 3.0
endif

dir_y						+= libz
dir_$(LIBS_INCLUDE_LIBLZO)			+= liblzo
dir_$(LIBS_INCLUDE_LIBNL)			+= libnl
dir_$(LIBS_INCLUDE_LIBCAP_NG)			+= libcap-ng
dir_$(LIBS_INCLUDE_LIBSSL)			+= libssl
dir_$(LIBS_INCLUDE_LIBUSB_0)			+= libusb
dir_$(LIBS_INCLUDE_LIBUSB_1)			+= libusb-1.0
dir_y						+= libnfnetlink

dir_$(CONFIG_FIRMWARE_INCLUDE_ZAPRET2)		+= libluajit
dir_$(CONFIG_FIRMWARE_INCLUDE_QRENCODE)		+= libqrencode
dir_y						+= libmnl
dir_y						+= libnetfilter_queue

# tcpdump shared libs
dir_$(CONFIG_FIRMWARE_INCLUDE_TCPDUMP)		+= libpcap

# minidlna and firefly shared libs
dir_$(LIBS_INCLUDE_MEDIA)			+= libid3tag
dir_$(LIBS_INCLUDE_MEDIA)			+= libav
dir_$(CONFIG_FIRMWARE_INCLUDE_MINIDLNA)		+= libexif
dir_$(CONFIG_FIRMWARE_INCLUDE_MINIDLNA)		+= libjpeg
dir_$(CONFIG_FIRMWARE_INCLUDE_MINIDLNA)		+= libogg
dir_$(CONFIG_FIRMWARE_INCLUDE_MINIDLNA)		+= libvorbis
dir_$(LIBS_INCLUDE_MEDIA)			+= libflac
dir_$(LIBS_INCLUDE_MEDIA)			+= libsqlite

# stubby extra libs
dir_$(LIBS_INCLUDE_LIBYAML)			+= libyaml
dir_$(LIBS_INCLUDE_LIBGETDNS)			+= libgetdns

dir_$(LIBS_INCLUDE_LIBEV)			+= libev
dir_$(LIBS_INCLUDE_LIBCARES)			+= libcares

# libcurl for Transmission and DoH proxy
dir_$(QUIC_ENABLED)				+= libngtcp2
dir_$(QUIC_ENABLED)				+= libnghttp3
dir_$(LIBS_INCLUDE_LIBCURL)			+= libnghttp2
dir_$(LIBS_INCLUDE_LIBCURL)			+= libcurl

# aria2 shared libs
dir_$(CONFIG_FIRMWARE_INCLUDE_ARIA)		+= libxml2

dir_$(LIBS_INCLUDE_LIBPCRE)			+= libpcre
dir_$(LIBS_INCLUDE_LIBMBEDTLS)			+= libmbedtls
dir_$(LIBS_INCLUDE_LIBSODIUM)			+= libsodium

# nfs rpc lib
ifneq (,$(filter y,$(CONFIG_FIRMWARE_INCLUDE_NFSD) $(CONFIG_FIRMWARE_INCLUDE_NFSC)))
dir_y						+= libtirpc
endif

dir_$(LIBS_INCLUDE_LIBEVENT)			+= libevent

all:
ifneq ($(LIBS_INCLUDE_LIBSSL),y)
	sed -i "s/\# CONFIG_FEATURE_WGET_HTTPS is not set/CONFIG_FEATURE_WGET_HTTPS=y/" $(DESTDIR)/busybox.config
	sed -i "s/CONFIG_FEATURE_WGET_OPENSSL=y/\# CONFIG_FEATURE_WGET_OPENSSL is not set/" $(DESTDIR)/busybox.config
endif
	for i in $(dir_y) ; do \
		[ -d $$i ] && \
		$(MAKE) -j1 -C $$i || \
		exit $$? ; \
		if [ ! -f $(DESTDIR)/.installed_$$i ] ; then \
			$(MAKE) -C $$i install && \
			touch $(DESTDIR)/.installed_$$i ; \
		fi ; \
	done

%_only:
	$(MAKE) -C $(@:_only=)

%_romfs:
	$(MAKE) -C $(@:_romfs=) romfs

%_clean:
	$(MAKE) -C $(@:_clean=) clean

romfs:
	for i in $(dir_y) ; do \
		[ -d $$i ] && \
		$(MAKE) -C $$i romfs ; \
	done

clean:
	for i in `ls -d *` ; do \
		if [ -d $$i ] ; then \
			$(MAKE) -C $$i clean ; \
			rm -f $(DESTDIR)/.installed_$$i ; \
		fi ; \
	done

