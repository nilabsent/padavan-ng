#!/bin/sh

conf="/etc/storage/dnsmasq/dnsmasq.ipset"

[ -x /sbin/ipset ] || exit
[ -s "$conf" ] || exit

sed -n 's#^[[:space:]]*ipset=/.*/##p' "$conf" \
    | tr ',' '\n' | sort -u \
    | grep -w "$(ipset -n list)" \
    | xargs -r -n1 ipset flush
