include $(ROOTDIR)/user/shared/board.mk

all:

clean:

romfs:
	./makedevlinks $(ROMFSDIR)
	$(ROMFSINST) /sbin/dev_init.sh
	$(ROMFSINST) /sbin/reset_ss.sh
	$(ROMFSINST) /sbin/mtd_storage.sh
ifeq ($(STORAGE_ENABLED),y)
	$(ROMFSINST) /sbin/automount.sh
endif
ifdef CONFIG_BLK_DEV_SD
	$(ROMFSINST) /sbin/hddtune.sh
	$(ROMFSINST) /sbin/spindown.sh
endif
	# FIXME:
ifneq (,$(filter -DBOARD_ARCHER_MR200,$(CFLAGS)))
	echo "\nadb wait-for-device\nadb shell chmod +x /WEBSERVER/www/cgi-bin/*\nadb shell httpd -h /WEBSERVER/www/" >> $(INSTALLDIR)/sbin/dev_init.sh ;\
	echo "echo \"2357 000d\" > /sys/bus/usb-serial/drivers/option1/new_id\nsleep 2\nadb kill-server\n" >> $(INSTALLDIR)/sbin/dev_init.sh
endif
	$(ROMFSINST) /etc_ro/protocols
	$(ROMFSINST) /etc_ro/services
	$(ROMFSINST) /etc_ro/profile
	$(ROMFSINST) /etc_ro/shells
	$(ROMFSINST) /etc_ro/mdev.conf
	mkdir -p $(INSTALLDIR)/usr/share/terminfo
	tar -xzf ./terminfo.tar.gz -C $(INSTALLDIR)/usr/share
	$(ROMFSINST) -d storage /usr/share/storage
ifneq ($(CONFIG_FIRMWARE_INCLUDE_SSWAN),y)
	rm -rf $(INSTALLDIR)/usr/share/storage/strongswan
endif
ifneq ($(CONFIG_FIRMWARE_INCLUDE_OPENVPN),y)
	rm -rf $(INSTALLDIR)/usr/share/storage/openvpn
endif
ifneq ($(CONFIG_FIRMWARE_INCLUDE_IPSET),y)
	rm -rf $(INSTALLDIR)/usr/share/storage/ipset
	rm -f $(INSTALLDIR)/usr/share/storage/dnsmasq/dnsmasq.ipset
endif
ifneq ($(CONFIG_FIRMWARE_INCLUDE_WPAD),y)
	rm -f $(INSTALLDIR)/usr/share/storage/wpad.dat
endif
ifeq (,$(filter y,$(CONFIG_FIRMWARE_INCLUDE_WIREGUARD) $(CONFIG_FIRMWARE_INCLUDE_AMNEZIAWG)))
	rm -f $(INSTALLDIR)/usr/share/storage/vpnc_exclude_network.list
	rm -f $(INSTALLDIR)/usr/share/storage/vpnc_remote_network.list
	rm -f $(INSTALLDIR)/usr/share/storage/vpnc_post_script.sh
endif
ifneq ($(CONFIG_FIRMWARE_INCLUDE_TOR),y)
	rm -rf $(INSTALLDIR)/usr/share/storage/tor
endif
