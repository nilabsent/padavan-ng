#!/bin/sh

script_start="/etc/storage/start_script.sh"

# create start script
cp -f /usr/share/storage/start_script.sh "$script_start"
chmod 755 "$script_start"

if [ -z "$1" ] ; then
	$script_start
	mtd_storage.sh save
fi
