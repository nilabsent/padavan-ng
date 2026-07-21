#!/bin/sh

depmod_bin="/sbin/depmod"

# check env
if [ -z "${ROOTDIR}" ]; then
	echo "ROOTDIR is not set!"
	exit 1
fi

if [ -z "${KERNELRELEASE}" ]; then
	echo "KERNELRELEASE is not set!"
	exit 1
fi

if [ -z "${INSTALL_MOD_PATH}" ]; then
	echo "INSTALL_MOD_PATH is not set!"
	exit 1
fi

if [ ! -x "$depmod_bin" ]; then
	echo "$depmod_bin is not found! Please install package module-init-tools (kmod)"
	exit 1
fi

if [ "$CONFIG_FIRMWARE_INCLUDE_IPSET" = "y" ] ; then
	ipset_dir="${ROOTDIR}/user/ipset/ipset-7.24/kernel/net/netfilter"
	mkdir -p "${INSTALL_MOD_PATH}/lib/modules/${KERNELRELEASE}/kernel/net/netfilter/ipset"
	cp -f "$ipset_dir/xt_set.ko" "${INSTALL_MOD_PATH}/lib/modules/${KERNELRELEASE}/kernel/net/netfilter"
	if [ "$CONFIG_CC_OPTIMIZE_FOR_SIZE" = "y" ] ; then
		for i in \
			ip_set \
			ip_set_hash_ip \
			ip_set_hash_net \
			ip_set_bitmap_ip \
			ip_set_list_set
		do
			cp -f "$ipset_dir/ipset/$i.ko" "${INSTALL_MOD_PATH}/lib/modules/${KERNELRELEASE}/kernel/net/netfilter/ipset"
		done
	else
		cp -f "$ipset_dir/ipset/"*.ko "${INSTALL_MOD_PATH}/lib/modules/${KERNELRELEASE}/kernel/net/netfilter/ipset"
	fi
fi

# call depmod
#sudo $depmod_bin -ae -F System.map -b "${INSTALL_MOD_PATH}" -r ${KERNELRELEASE}
${FAKEROOT} $depmod_bin -ae -F System.map -b "${INSTALL_MOD_PATH}" ${KERNELRELEASE}

# clear unneeded depmod files
rm -f "${INSTALL_MOD_PATH}/lib/modules/${KERNELRELEASE}/modules.alias"
rm -f "${INSTALL_MOD_PATH}/lib/modules/${KERNELRELEASE}/modules.alias.bin"
rm -f "${INSTALL_MOD_PATH}/lib/modules/${KERNELRELEASE}/modules.dep.bin"
rm -f "${INSTALL_MOD_PATH}/lib/modules/${KERNELRELEASE}/modules.devname"
rm -f "${INSTALL_MOD_PATH}/lib/modules/${KERNELRELEASE}/modules.softdep"
rm -f "${INSTALL_MOD_PATH}/lib/modules/${KERNELRELEASE}/modules.symbols"
rm -f "${INSTALL_MOD_PATH}/lib/modules/${KERNELRELEASE}/modules.symbols.bin"
rm -f "${INSTALL_MOD_PATH}/lib/modules/${KERNELRELEASE}/modules.builtin"
rm -f "${INSTALL_MOD_PATH}/lib/modules/${KERNELRELEASE}/modules.builtin.bin"
rm -f "${INSTALL_MOD_PATH}/lib/modules/${KERNELRELEASE}/modules.order"
rm -f "${INSTALL_MOD_PATH}/lib/modules/${KERNELRELEASE}/build"
rm -f "${INSTALL_MOD_PATH}/lib/modules/${KERNELRELEASE}/source"

rm -rf "${INSTALL_MOD_PATH}/opt/lib"
if [ -z ${CONFIG_FIRMWARE_INCLUDE_BACKPORTED} ]&&[ -d ${INSTALL_MOD_PATH}/lib/modules/${KERNELRELEASE}/updates ]; then
	mkdir -p "${INSTALL_MOD_PATH}/opt/lib/modules/${KERNELRELEASE}/"
	mv -vf "${INSTALL_MOD_PATH}/lib/modules/${KERNELRELEASE}/updates" -t "${INSTALL_MOD_PATH}/opt/lib/modules/${KERNELRELEASE}"
	ln -st ${INSTALL_MOD_PATH}/lib/modules/${KERNELRELEASE} /opt/lib/modules/${KERNELRELEASE}/updates
fi