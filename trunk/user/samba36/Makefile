# patches: https://git.archive.openwrt.org/?p=15.05/openwrt.git;a=tree;f=package/network/services/samba36/patches

SRC_NAME := samba-3.6.25
SRC_DIR := $(SRC_NAME)/source3
SRC_URL := https://download.samba.org/pub/samba/stable/$(SRC_NAME).tar.gz
THISDIR := $(shell pwd)

SMBCFLAGS = -Wall -D__location__=\\\"\\\" -ffunction-sections -fdata-sections $(CFLAGS)
SMBLDFLAGS = -Wl,--gc-sections $(LDFLAGS)
SMBCPPFLAGS = $(CPPFLAGS) -DNDEBUG -DSHMEM_SIZE=524288 -Dfcntl=fcntl64 -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE=1 -D_LARGEFILE64_SOURCE=1 -D_LARGE_FILES=1
MAKE_FLAGS = $(MAKEFLAGS) DYNEXP= PICFLAG= MODULES=

ifeq ($(CONFIG_FIRMWARE_INCLUDE_SMBD_SYSLOG),y)
SMBCFLAGS += -DMAX_DEBUG_LEVEL="0"
else
SMBCFLAGS += -DMAX_DEBUG_LEVEL="-1"
endif

all: download_test extract_test config_test
	MAKEFLAGS="$(MAKE_FLAGS)" $(MAKE) -C $(SRC_DIR) basics
	MAKEFLAGS="$(MAKE_FLAGS)" $(MAKE) -j$(HOST_NCPU) -C $(SRC_DIR)

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
	( cd $(SRC_DIR) && \
	ac_cv_lib_attr_getxattr=no \
	ac_cv_search_getxattr=no \
	ac_cv_file__proc_sys_kernel_core_pattern=no \
	libreplace_cv_HAVE_C99_VSNPRINTF=yes \
	libreplace_cv_HAVE_GETADDRINFO=yes \
	libreplace_cv_HAVE_IFACE_IFCONF=yes \
	LINUX_LFS_SUPPORT=yes \
	samba_cv_CC_NEGATIVE_ENUM_VALUES=yes \
	samba_cv_HAVE_GETTIMEOFDAY_TZ=yes \
	samba_cv_HAVE_IFACE_IFCONF=yes \
	samba_cv_HAVE_KERNEL_OPLOCKS_LINUX=yes \
	samba_cv_HAVE_SECURE_MKSTEMP=yes \
	samba_cv_HAVE_WRFILE_KEYTAB=no \
	samba_cv_USE_SETREUID=yes \
	samba_cv_USE_SETRESUID=yes \
	samba_cv_have_setreuid=yes \
	samba_cv_have_setresuid=yes \
	ac_cv_header_zlib_h=no \
	samba_cv_zlib_1_2_3=no \
	ac_cv_path_PYTHON="" \
	ac_cv_path_PYTHON_CONFIG="" \
	PKG_CONFIG_PATH="$(STAGEDIR)/lib/pkgconfig" \
	CPPFLAGS="$(SMBCPPFLAGS)" \
	CFLAGS="$(SMBCFLAGS)" LDFLAGS="$(SMBLDFLAGS)" \
	./configure \
		--host=$(HOST_TARGET) \
		--build=$(HOST_BUILD) \
		--exec-prefix=/ \
		--prefix=/ \
		--enable-external-libtdb=no \
		--disable-external-libtalloc \
		--disable-dmalloc \
		--disable-iprint \
		--disable-fam \
		--disable-krb5developer \
		--disable-developer \
		--disable-debug \
		--disable-avahi \
		--disable-cups \
		--disable-pie \
		--disable-relro \
		--disable-static \
		--disable-swat \
		--disable-shared-libs \
		--with-codepagedir=/usr/share/samba \
		--with-configdir=/etc \
		--with-included-iniparser \
		--with-included-popt=no \
		--with-rootsbindir=/sbin \
		--with-lockdir=/var/locks \
		--with-syslog \
		--with-nmbdsocketdir=/var/nmbd \
		--with-piddir=/var/run \
		--with-privatedir=/etc/samba \
		--with-sendfile-support \
		--without-acl-support \
		--without-cluster-support \
		--without-ads \
		--without-krb5 \
		--without-ldap \
		--without-pam \
		--without-utmp \
		--without-quotas \
		--without-sys-quotas \
		--without-winbind \
		--without-libtdb \
		--without-libtalloc \
		--without-libnetapi \
		--without-libsmbclient \
		--without-libsmbsharemodes \
		--without-libtevent \
		--without-libaddns \
		--with-shared-modules=pdb_tdbsam,pdb_wbc_sam,idmap_nss,nss_info_template,auth_winbind,auth_wbc,auth_domain; \
	mkdir -p bin )

clean:
	if [ -f $(SRC_DIR)/Makefile ] ; then \
		$(MAKE) -C $(SRC_DIR) distclean ; \
	fi ;
	rm -rf $(SRC_DIR)/bin
	rm -f config_done

distclean: clean
	@find $(SRC_DIR) -name config.h | xargs rm -f
	@find $(SRC_DIR) -name Makefile | xargs rm -f
	@find $(SRC_DIR) -name config.status | xargs rm -f
	@find $(SRC_DIR) -name config.cache | xargs rm -f

romfs:
ifeq ($(CONFIG_FIRMWARE_INCLUDE_SMBD36),y)
	$(ROMFSINST) $(THISDIR)/$(SRC_DIR)/bin/samba_multicall /sbin/samba_multicall
	$(ROMFSINST) -s samba_multicall /sbin/smbd
	$(ROMFSINST) -s samba_multicall /sbin/nmbd
	$(ROMFSINST) -s /sbin/samba_multicall /bin/smbpasswd
	mkdir -p $(ROMFSDIR)/usr/share/samba
	cp -fP $(THISDIR)/$(SRC_NAME)/codepages/*.dat $(ROMFSDIR)/usr/share/samba
else
ifeq ($(CONFIG_FIRMWARE_INCLUDE_WINS),y)
	$(ROMFSINST) $(THISDIR)/$(SRC_DIR)/bin/nmbd /sbin/nmbd
endif
endif
