#!/bin/sh

result=0
mtd_part_name="Storage"
mtd_part_dev="/dev/mtdblock5"
mtd_part_size=65536
dir_storage="/etc/storage"
slk="/tmp/.storage_locked"
tmp="/tmp/storage.tar"
tbz="${tmp}.bz2"
hsh="/tmp/hashes/storage_md5"

func_get_mtd()
{
	local mtd_part mtd_char mtd_idx mtd_hex
	mtd_part=`cat /proc/mtd | grep \"$mtd_part_name\"`
	mtd_char=`echo $mtd_part | cut -d':' -f1`
	mtd_hex=`echo $mtd_part | cut -d' ' -f2`
	mtd_idx=`echo $mtd_char | cut -c4-5`
	if [ -n "$mtd_idx" ] && [ $mtd_idx -ge 3 ] ; then
		mtd_part_dev="/dev/mtdblock${mtd_idx}"
		mtd_part_size=`echo $((0x$mtd_hex))`
	else
		logger -t "Storage" "Cannot find MTD partition: $mtd_part_name"
		exit 1
	fi
}

func_mdir()
{
	[ ! -d "$dir_storage" ] && mkdir -p -m 755 $dir_storage
}

func_stop_apps()
{
	killall -q rstats
	[ $? -eq 0 ] && sleep 1
}

func_start_apps()
{
	/sbin/rstats
}

func_load()
{
	local fsz

	bzcat $mtd_part_dev > $tmp 2>/dev/null
	fsz=`stat -c %s $tmp 2>/dev/null`
	if [ -n "$fsz" ] && [ $fsz -gt 0 ] ; then
		md5sum $tmp > $hsh
		tar xf $tmp -C $dir_storage 2>/dev/null
	else
		result=1
		rm -f $hsh
		logger -t "Storage load" "Invalid storage data in MTD partition: $mtd_part_dev"
	fi
	rm -f $tmp
	rm -f $slk
}

func_tarb()
{
	rm -f $tmp
	cd $dir_storage
	find * -print0 | xargs -0 touch -c -h -t 201001010000.00
	find * ! -type d -print0 | sort -z | xargs -0 tar -cf $tmp 2>/dev/null
	cd - >>/dev/null
	if [ ! -f "$tmp" ] ; then
		logger -t "Storage" "Cannot create tarball file: $tmp"
		exit 1
	fi
}

func_save()
{
	local fsz

	echo "Save storage files to MTD partition \"$mtd_part_dev\""
	rm -f $tbz
	md5sum -c -s $hsh 2>/dev/null
	if [ $? -eq 0 ] ; then
		echo "Storage hash is not changed, skip write to MTD partition. Exit."
		rm -f $tmp
		return 0
	fi
	md5sum $tmp > $hsh
	bzip2 -9 $tmp 2>/dev/null
	fsz=`stat -c %s $tbz 2>/dev/null`
	if [ -n "$fsz" ] && [ $fsz -ge 16 ] && [ $fsz -le $mtd_part_size ] ; then
		mtd_write write $tbz $mtd_part_name
		if [ $? -eq 0 ] ; then
			echo "Done."
		else
			result=1
			echo "Error! MTD write FAILED"
			logger -t "Storage save" "Error write to MTD partition: $mtd_part_dev"
		fi
	else
		result=1
		echo "Error! Invalid storage final data size: $fsz"
		logger -t "Storage save" "Invalid storage final data size: $fsz"
	fi
	rm -f $tmp
	rm -f $tbz
}

func_backup()
{
	rm -f $tbz
	bzip2 -9 $tmp 2>/dev/null
	if [ $? -ne 0 ] ; then
		result=1
		logger -t "Storage backup" "Cannot create BZ2 file!"
	fi
	rm -f $tmp
}

func_restore()
{
	local fsz tmp_storage

	[ ! -f "$tbz" ] && exit 1

	fsz=`stat -c %s $tbz 2>/dev/null`
	if [ -z "$fsz" ] || [ $fsz -lt 16 ] || [ $fsz -gt $mtd_part_size ] ; then
		result=1
		rm -f $tbz
		logger -t "Storage restore" "Invalid BZ2 file size: $fsz"
		return 1
	fi

	tmp_storage="/tmp/storage"
	rm -rf $tmp_storage
	mkdir -p -m 755 $tmp_storage
	tar xjf $tbz -C $tmp_storage 2>/dev/null
	if [ $? -ne 0 ] ; then
		result=1
		rm -f $tbz
		rm -rf $tmp_storage
		logger -t "Storage restore" "Unable to extract BZ2 file: $tbz"
		return 1
	fi
	if [ ! -f "$tmp_storage/start_script.sh" ] ; then
		result=1
		rm -f $tbz
		rm -rf $tmp_storage
		logger -t "Storage restore" "Invalid content of BZ2 file: $tbz"
		return 1
	fi

	func_stop_apps

	rm -f $slk
	rm -f $tbz
	rm -rf $dir_storage
	mkdir -p -m 755 $dir_storage
	cp -rf $tmp_storage /etc
	rm -rf $tmp_storage

	func_start_apps
}

func_erase()
{
	mtd_write erase $mtd_part_name
	if [ $? -eq 0 ] ; then
		rm -f $hsh
		rm -rf $dir_storage
		mkdir -p -m 755 $dir_storage
		touch "$slk"
	else
		result=1
	fi
}

func_reset()
{
	rm -f $slk
	rm -rf $dir_storage
	mkdir -p -m 755 $dir_storage
}

cp_default()
{
	# $1 - storage file path
	# #2 - chmod

	local dst="$1"

	if [ ! -f "$dst" ] ; then
		cp -f "/usr/share/${dst#/etc}" "$dst"
		chmod $2 "$dst"
	fi
}

func_fill()
{
	dir_httpssl="$dir_storage/https"
	dir_dnsmasq="$dir_storage/dnsmasq"
	dir_ovpnsvr="$dir_storage/openvpn/server"
	dir_ovpncli="$dir_storage/openvpn/client"
	dir_sswan="$dir_storage/strongswan"
	dir_sswan_crt="$dir_sswan/ipsec.d"
	dir_inadyn="$dir_storage/inadyn"
	dir_crond="$dir_storage/cron/crontabs"
	dir_wlan="$dir_storage/wlan"
	dir_ipset="$dir_storage/ipset"
	dir_tor="$dir_storage/tor"

	# create crond dir
	[ ! -d "$dir_crond" ] && mkdir -p -m 730 "$dir_crond"

	# create https dir
	[ ! -d "$dir_httpssl" ] && mkdir -p -m 700 "$dir_httpssl"

	# create start script
	if [ ! -f "$dir_storage/start_script.sh" ] ; then
		reset_ss.sh -a
	fi

	# create started script
	cp_default "$dir_storage/started_script.sh" 755

	# create shutdown script
	cp_default "$dir_storage/shutdown_script.sh" 755

	# create post-iptables script
	cp_default "$dir_storage/post_iptables_script.sh" 755

	# create post-wan script
	cp_default "$dir_storage/post_wan_script.sh" 755

	# create inet-state script
	cp_default "$dir_storage/inet_state_script.sh" 755

	# create vpn server action script
	cp_default "$dir_storage/vpns_client_script.sh" 755

	# create vpn client action script
	cp_default "$dir_storage/vpnc_server_script.sh" 755

	# wireguard storage files
	if [ -s /lib/modules/3.4.113/kernel/net/wireguard/wireguard.ko ] \
	   || [ -s /lib/modules/3.4.113/kernel//net/amneziawg/amneziawg.ko ] ; then
		# create wireguard client post script
		cp_default "$dir_storage/vpnc_post_script.sh" 755

		# create wireguard remote ip list
		cp_default "$dir_storage/vpnc_remote_network.list" 644

		# create wireguard exclusion list of remote ip
		cp_default "$dir_storage/vpnc_exclude_network.list" 644
	fi

	# create Ez-Buttons script
	cp_default "$dir_storage/ez_buttons_script.sh" 755

	# create wpad.dat script
	if [ -L "/www/wpad.dat" ] ; then
		cp_default "$dir_storage/wpad.dat" 644
	fi

	# create user dnsmasq.conf
	[ ! -d "$dir_dnsmasq" ] && mkdir -p -m 755 "$dir_dnsmasq"
	cp_default "$dir_dnsmasq/dnsmasq.conf" 644

	# create user dns servers
	cp_default "$dir_dnsmasq/dnsmasq.servers" 644

	# create user hosts
	cp_default "$dir_dnsmasq/hosts" 644

	# create user ipsets
	if [ -x /sbin/ipset ] ; then
		cp_default "$dir_dnsmasq/dnsmasq.ipset" 644

		[ ! -d "$dir_ipset" ] && mkdir -p -m 755 "$dir_ipset"
		cp_default "$dir_ipset/ipset.json" 644
		cp_default "$dir_ipset/ipset_post_script.sh" 755
	fi

	# create user inadyn.conf"
	[ ! -d "$dir_inadyn" ] && mkdir -p -m 755 "$dir_inadyn"
	cp_default "$dir_inadyn/inadyn.conf" 644

	# create user AP confs
	[ ! -d "$dir_wlan" ] && mkdir -p -m 755 "$dir_wlan"
	cp_default "$dir_wlan/AP.dat" 644
	cp_default "$dir_wlan/AP_5G.dat" 644

	# create openvpn files
	if [ -x /usr/sbin/openvpn ] ; then
		[ ! -d "$dir_ovpncli" ] && mkdir -p -m 700 "$dir_ovpncli"
		[ ! -d "$dir_ovpnsvr" ] && mkdir -p -m 700 "$dir_ovpnsvr"

		dir_ovpn="$dir_storage/openvpn"
		for i in ca.crt dh1024.pem server.crt server.key server.conf ta.key ; do
			[ -f "$dir_ovpn/$i" ] && mv -n "$dir_ovpn/$i" "$dir_ovpnsvr"
		done

		cp_default "$dir_ovpnsvr/server.conf" 644
		cp_default "$dir_ovpncli/client.conf" 644
	fi

	# create strongswan files
	if [ -x /usr/sbin/ipsec ] ; then
		[ ! -d "$dir_sswan" ] && mkdir -p -m 700 "$dir_sswan"
		[ ! -d "$dir_sswan_crt" ] && mkdir -p -m 700 "$dir_sswan_crt"
		[ ! -d "$dir_sswan_crt/cacerts" ] && mkdir -p -m 700 "$dir_sswan_crt/cacerts"
		[ ! -d "$dir_sswan_crt/certs" ] && mkdir -p -m 700 "$dir_sswan_crt/certs"
		[ ! -d "$dir_sswan_crt/private" ] && mkdir -p -m 700 "$dir_sswan_crt/private"

		cp_default "$dir_sswan/strongswan.conf" 644
		cp_default "$dir_sswan/ipsec.conf" 644
		cp_default "$dir_sswan/ipsec.secrets" 644
	fi

	# create tor config
	if [ -x /usr/sbin/tor ]; then
		[ ! -d "$dir_tor" ] && mkdir -p -m 755 "$dir_tor"
		cp_default "$dir_tor/torrc" 644
		cp_default "$dir_tor/remote_network.list" 644
	fi

	# create zapret files
	if [ -x "/usr/bin/zapret.sh" ]; then
		/usr/bin/zapret.sh >/dev/null
	fi
}

case "$1" in
load)
	func_get_mtd
	func_mdir
	func_load
	;;
save)
	[ -f "$slk" ] && exit 1
	func_get_mtd
	func_mdir
	func_tarb
	func_save
	;;
backup)
	func_mdir
	func_tarb
	func_backup
	;;
restore)
	func_get_mtd
	func_restore
	;;
erase)
	func_get_mtd
	func_erase
	;;
reset)
	func_stop_apps
	func_reset
	func_fill
	func_start_apps
	;;
fill)
	func_mdir
	func_fill
	;;
*)
	echo "Usage: $0 {load|save|backup|restore|erase|reset|fill}"
	exit 1
	;;
esac

exit $result
