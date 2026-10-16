#!/bin/sh
##
## fast download many cdn cidr:
##
## akamai, amazon, blizzard, cloudflare, clouvider, contabo
## datacamp, digitalocean, fastly, frantech, github, google
## hetzner, meta, oracle, ovh, reflected, sberbank, vultr
## telegram
##

angry_wget() {
  local r=1
  while [ $r -lt 10 ]; do
    wget -T10 --no-check-certificate "$1" -O "$2" && return 0 || sleep $r
    r=$((r + 2))
  done
  return 1
}

cdn="https://github.com/nilabsent/ipset/archive/refs/heads/main.tar.gz"
angry_wget "$cdn" "-" | tar xz -C /tmp
for i in $(ls /tmp/ipset-main/ipv4/*.txt); do
    name="$(basename $i .txt)"
    ipset.sh import $name $i
done
rm -rf /tmp/ipset-main
