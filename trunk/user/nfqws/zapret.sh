#!/bin/sh

# https://github.com/nilabsent/zapretsh

# for openwrt versions 21 and above (iptables):
# opkg install curl iptables-mod-nfqueue iptables-mod-conntrack-extra
#
# for openwrt versions 22 and later (nftables):
# opkg install curl kmod-nft-queue kmod-nfnetlink-queue

NFQWS_BIN="/usr/bin/nfqws"
NFQWS_BIN_OPT="/opt/bin/nfqws"
NFQWS_BIN_GIT="/tmp/nfqws"
ETC_DIR="/etc"

# padavan
[ -d "/etc_ro" ] && ETC_DIR="/etc/storage"

CONFDIR="${ETC_DIR}/zapret"
CONFDIR_EXAMPLE="/usr/share/zapret"
CONFFILE="$CONFDIR/config"
PIDFILE="/var/run/zapret.pid"

HOSTLIST_DOMAINS="https://github.com/1andrevich/Re-filter-lists/releases/latest/download/domains_all.lst"

HOSTLIST_MARKER="<HOSTLIST>"
HOSTLIST_NOAUTO_MARKER="<HOSTLIST_NOAUTO>"

HOSTLIST_NOAUTO="
  --hostlist=${ETC_DIR}/zapret/user.list
  --hostlist=${ETC_DIR}/zapret/auto.list
  --hostlist-exclude=${ETC_DIR}/zapret/exclude.list
  --hostlist=/tmp/filter.list
"
HOSTLIST="
  --hostlist=${ETC_DIR}/zapret/user.list
  --hostlist-exclude=${ETC_DIR}/zapret/exclude.list
  --hostlist-auto=${ETC_DIR}/zapret/auto.list
  --hostlist=/tmp/filter.list
"

### default config

ISP_INTERFACE=
IPV6_ENABLED=0
TCP_PORTS=80,443
UDP_PORTS=443,50000:50099
NFQUEUE_NUM=200
LOG_LEVEL=0
USER="nobody"

###

log() {
  [ -n "$@" ] || return
  echo "$@"
  local pid
  [ -f "$PIDFILE" ] && pid="[$(cat "$PIDFILE" 2>/dev/null)]"
  logger -t "zapret$pid" "$@"
}

error() {
  log "$@"
  exit 1
}

if id -u >/dev/null 2>&1; then
  [ $(id -u) != "0" ] && echo "root user is required to start" && exit 1
fi

# padavan: possibility of running nfqws from usb-flash drive
[ -d "/etc_ro" ] && for i in "a1" "a2" "a3" "a4" "b1" "b2" "b3" "b4" ; do
    disk_path="/media/AiDisk_${i}"
    if [ -d "${disk_path}" ] && grep -q ${disk_path} /proc/mounts ; then
        if [ -f "${disk_path}$NFQWS_BIN_OPT" ]; then
            NFQWS_BIN="${disk_path}$NFQWS_BIN_OPT"
            chmod +x "$NFQWS_BIN"
            break
        fi
    fi
done

[ -s "$NFQWS_BIN_GIT" ] && NFQWS_BIN="$NFQWS_BIN_GIT"

[ -f "$CONFDIR" ] && rm -f "$CONFDIR"
[ -d "$CONFDIR" ] || mkdir -p "$CONFDIR" || exit 1
# copy all non-existent config files to storage except fake dir
[ -d "$CONFDIR_EXAMPLE" ] && false | cp -i "${CONFDIR_EXAMPLE}"/* "$CONFDIR" >/dev/null 2>&1
[ -f "$CONFFILE" ] && . "$CONFFILE"
for i in user.list exclude.list auto.list strategy config; do
  [ -f ${ETC_DIR}/zapret/$i ] || touch ${ETC_DIR}/zapret/$i || exit 1
done

###

unset OPENWRT
[ -f "/etc/openwrt_release" ] && OPENWRT=1
unset NFT
nft -v >/dev/null 2>&1 && NFT=1

_ISP_IF=$(
  echo "$ISP_INTERFACE,$(ip -4 r s default | cut -d ' ' -f5)" |\
    tr " " "\n" | tr "," "\n" | sort -u
);

_ISP_IF6=$(
  echo "$ISP_INTERFACE,$(ip -6 r s default | cut -d ' ' -f5)" |\
    tr " " "\n" | tr "," "\n" | sort -u
);

_MANGLE_RULES() ( echo "
-A PREROUTING  -i $IFACE -p tcp -m multiport --sports $TCP_PORTS -m connbytes --connbytes-dir=reply    --connbytes-mode=packets --connbytes 1:3 -m mark ! --mark 0x40000000/0x40000000 -j NFQUEUE --queue-num $NFQUEUE_NUM --queue-bypass
-A POSTROUTING -o $IFACE -p tcp -m multiport --dports $TCP_PORTS -m connbytes --connbytes-dir=original --connbytes-mode=packets --connbytes 1:9 -m mark ! --mark 0x40000000/0x40000000 -j NFQUEUE --queue-num $NFQUEUE_NUM --queue-bypass
-A POSTROUTING -o $IFACE -p udp -m multiport --dports $UDP_PORTS -m connbytes --connbytes-dir=original --connbytes-mode=packets --connbytes 1:9 -m mark ! --mark 0x40000000/0x40000000 -j NFQUEUE --queue-num $NFQUEUE_NUM --queue-bypass
")

is_running() {
  [ -z "$(pgrep `basename "$NFQWS_BIN"` 2>/dev/null)" ] && return 1
  [ ! -f "$PIDFILE" ] && return 1
  return 0
}

status_service() {
  if is_running; then
    echo "service nfqws is running"
    exit 0
  else
    echo "service nfqws is stopped"
    exit 1
  fi
}

kernel_modules() {
  # "modprobe -a" may not supported
  for i in nfnetlink_queue xt_connbytes xt_NFQUEUE nft-queue; do
    modprobe -q $i >/dev/null 2>&1
  done
}

replace_str()
{
  local a=$(echo "$1" | sed 's/\//\\\//g')
  local b=$(echo "$2" | tr '\n' ' ' | sed 's/\//\\\//g')
  shift; shift
  echo "$@" | tr '\n' ' ' | sed "s/$a/$b/g; s/[ \t]\{1,\}/ /g"
}

startup_args() {
  [ -f /tmp/filter.list ] || touch /tmp/filter.list
  local args="--user=$USER --qnum=$NFQUEUE_NUM"

  [ "$LOG_LEVEL" = "1" ] && args="--debug=syslog $args"

  NFQWS_ARGS="$(grep -v '^#' ${ETC_DIR}/zapret/strategy)"
  NFQWS_ARGS=$(replace_str "$HOSTLIST_MARKER" "$HOSTLIST" "$NFQWS_ARGS")
  NFQWS_ARGS=$(replace_str "$HOSTLIST_NOAUTO_MARKER" "$HOSTLIST_NOAUTO" "$NFQWS_ARGS")
  echo "$args $NFQWS_ARGS"
}

offload_unset_rules() {
  eval "$(ip$1tables-save -t filter 2>/dev/null | grep "FORWARD.*forwarding_rule_zapret" | sed 's/^-A/ip$1tables -D/g')"
  ip$1tables -F forwarding_rule_zapret 2>/dev/null
  ip$1tables -X forwarding_rule_zapret 2>/dev/null
}

offload_stop() {
  [ -n "$NFT" ] && return
  [ -n "$OPENWRT" ] || return
  offload_unset_rules
  offload_unset_rules 6
}

offload_set_rules() {
  local HW_OFFLOAD
  [ "$(uci -q get firewall.@defaults[0].flow_offloading_hw)" = "1" ] && \
    HW_OFFLOAD="--hw"

  local FW_FORWARD=$(
    for IFACE in $(eval echo "\$_ISP_IF$1"); do
      # insert after custom forwarding rule chain
      echo "-I FORWARD 2 -o $IFACE -j forwarding_rule_zapret"
    done)

  [ -n "$FW_FORWARD" ] && ip$1tables-restore -n 2>/dev/null <<EOF
*filter
:forwarding_rule_zapret - [0:0]
-A forwarding_rule_zapret -p udp -m multiport --dports $UDP_PORTS -m connbytes --connbytes 1:9 --connbytes-mode packets --connbytes-dir original -m comment --comment zapret_traffic_offloading_exemption -j RETURN
-A forwarding_rule_zapret -p tcp -m multiport --dports $TCP_PORTS -m connbytes --connbytes 1:9 --connbytes-mode packets --connbytes-dir original -m comment --comment zapret_traffic_offloading_exemption -j RETURN
-A forwarding_rule_zapret -m comment --comment zapret_traffic_offloading_enable -m conntrack --ctstate RELATED,ESTABLISHED -j FLOWOFFLOAD $HW_OFFLOAD
$(echo "$FW_FORWARD")
COMMIT
EOF
}

offload_start() {
  [ -n "$NFT" ] && return
  # offloading is supported only in OpenWrt
  [ -n "$OPENWRT" ] || return

  offload_stop
  [ -n "$_ISP_IF$_ISP_IF6" ] || return
  [ "$(uci -q get firewall.@defaults[0].flow_offloading)" = "1" ] || return

  # delete system offloading
  [ -n "$_ISP_IF" ] && eval "$(iptables-save -t filter 2>/dev/null | grep "FLOWOFFLOAD" | sed 's/^-A/iptables -D/g')"
  [ "$IPV6_ENABLED" = "1" ] && \
    [ -n "$_ISP_IF6" ] && eval "$(ip6tables-save -t filter 2>/dev/null | grep "FLOWOFFLOAD" | sed 's/^-A/ip6tables -D/g')"

  offload_set_rules
  [ "$IPV6_ENABLED" = "1" ] && offload_set_rules 6

  log "offloading rules updated"
}

nftables_stop() {
  [ -n "$NFT" ] || return
  nft delete table inet zapret 2>/dev/null
}

iptables_stop() {
  [ -n "$NFT" ] && return
  eval "$(iptables-save -t mangle 2>/dev/null | grep "queue-num $NFQUEUE_NUM " | sed 's/^-A/iptables -t mangle -D/g')"
  eval "$(ip6tables-save -t mangle 2>/dev/null | grep "queue-num $NFQUEUE_NUM " | sed 's/^-A/ip6tables -t mangle -D/g')"
}

firewall_stop() {
  nftables_stop
  iptables_stop
  offload_stop
}

nftables_start() {
  [ -n "$NFT" ] || return

  UDP_PORTS=$(echo $UDP_PORTS | tr ":" "-")
  TCP_PORTS=$(echo $TCP_PORTS | tr ":" "-")

  nft create table inet zapret
  nft add chain inet zapret post "{type filter hook postrouting priority mangle;}"
  nft add chain inet zapret pre "{type filter hook prerouting priority filter;}"

  for IFACE in $(echo "$_ISP_IF$_ISP_IF6" | sort -u); do
    nft add rule inet zapret post oifname $IFACE meta mark and 0x40000000 == 0 tcp dport "{$TCP_PORTS}" ct original packets 1-9 queue num $NFQUEUE_NUM bypass
    nft add rule inet zapret post oifname $IFACE meta mark and 0x40000000 == 0 udp dport "{$UDP_PORTS}" ct original packets 1-9 queue num $NFQUEUE_NUM bypass
    nft add rule inet zapret pre iifname $IFACE tcp sport "{$TCP_PORTS}" ct reply packets 1-3 queue num $NFQUEUE_NUM bypass
  done
}

iptables_set_rules() {
  local FW_MANGLE
  for IFACE in $(eval echo "\$_ISP_IF$1"); do
    FW_MANGLE="$FW_MANGLE$(_MANGLE_RULES)"
  done

  [ -n "$FW_MANGLE" ] && ip$1tables-restore -n 2>/dev/null <<EOF
*mangle
$(echo "$FW_MANGLE")
COMMIT
EOF
}

iptables_start() {
  [ -n "$NFT" ] && return

  UDP_PORTS=$(echo $UDP_PORTS | tr "-" ":")
  TCP_PORTS=$(echo $TCP_PORTS | tr "-" ":")

  iptables_set_rules
  [ "$IPV6_ENABLED" = "1" ] && iptables_set_rules 6
}

firewall_start() {
  firewall_stop

  nftables_start
  iptables_start

  IF_LOG="$_ISP_IF"
  [ "$IPV6_ENABLED" = "1" ] && IF_LOG="$_ISP_IF$_ISP_IF6"

  if [ -n "$IF_LOG" ]; then
    IF_LOG=$(echo "$IF_LOG" | sort -u | tr "\n" " ")
    log "firewall rules were applied on interface(s):$IF_LOG"
  else
    log "firewall rules were not set"
  fi

  offload_start
}

system_config() {
  sysctl -w net.netfilter.nf_conntrack_checksum=0 >/dev/null 2>&1
  sysctl -w net.netfilter.nf_conntrack_tcp_be_liberal=1 >/dev/null 2>&1
  [ -n "$OPENWRT" ] || return
  [ -f /etc/firewall.zapret ] || \
    echo "/etc/init.d/zapret enabled && /etc/init.d/zapret reload" > /etc/firewall.zapret
  uci -q get firewall.zapret >/dev/null || (
    uci -q set firewall.zapret=include
    uci -q set firewall.zapret.path='/etc/firewall.zapret'
    uci -q set firewall.zapret.reload='1'
    uci commit
  )
}

start_service() {
  [ -s "$NFQWS_BIN" -a -x "$NFQWS_BIN" ] || error "$NFQWS_BIN: not found or invalid"
  if is_running; then
    echo "service nfqws is already running"
    return
  fi

  kernel_modules

  res=$($NFQWS_BIN --daemon --pidfile=$PIDFILE $(startup_args) 2>&1) ||\
    error "failed to start nfqws service: $res"

  firewall_start
  system_config

  echo "$res" | grep -iv "loading" | while read i; do
    log "$i"
  done
}

stop_service() {
  firewall_stop
  killall -q -s 15 $(basename "$NFQWS_BIN") && log "service nfqws stopped"
  rm -f "$PIDFILE"
}

reload_service() {
  is_running || return
  firewall_start
  kill -HUP $(cat "$PIDFILE")
}

download_nfqws() {
  cd /tmp

  ARCH=$(uname -m | grep -oE 'mips|mipsel|aarch64|arm|rlx|i386|i686|x86_64')
  case "$ARCH" in
    rlx)
      ARCH="lexra"
    ;;
    mips)
      ARCH="mips32r1-msb"
      grep -qE 'system type.*(MediaTek|Ralink)' /proc/cpuinfo && ARCH="mips32r1-lsb"
    ;;
    mipsel)
      ARCH="mips32r1-lsb"
    ;;
    i386|i686)
      ARCH="x86"
    ;;
  esac
  [ -n "$ARCH" ] || error "cpu arch unknown"

  if [ -f /usr/bin/curl ]; then
    URL=$(curl -s --connect-timeout 5 'https://api.github.com/repos/bol-van/zapret/releases/latest' |\
      grep 'browser_download_url.*openwrt-embedded' | cut -d '"' -f4)
    [ -n "$URL" ] || error "unable to get link to nfqws"
    curl -sSL --connect-timeout 5 $URL -o zapret.tar.gz || error "unable to download $URL"
  else
    URL=$(wget -q -T 5 'https://api.github.com/repos/bol-van/zapret/releases/latest' -O- |\
      grep 'browser_download_url.*openwrt-embedded' | cut -d '"' -f4)
    [ -n "$URL" ] || error "unable to get link to nfqws"
    wget -q -T 5 $URL -O zapret.tar.gz || error "unable to download $URL"
  fi
  [ -s zapret.tar.gz ] || exit
  [ $(cat zapret.tar.gz | head -c3) = "Not" ] && exit
  log "downloaded successfully: $URL"

  local NFQWS=$(tar tzfv zapret.tar.gz | grep binaries/$ARCH/nfqws | awk '{print $6}')
  [ -n "$NFQWS" ] || error "nfqws not found in archive zapret.tar.gz for arch $ARCH"
  tar xzf zapret.tar.gz "$NFQWS" -O > $NFQWS_BIN_GIT
  [ -s $NFQWS_BIN_GIT ] && chmod +x $NFQWS_BIN_GIT
  rm -f zapret.tar.gz
}

download_list() {
  local LIST="/tmp/filter.list"
  if [ -f /usr/bin/curl ]; then
    curl -sSL --connect-timeout 5 "$HOSTLIST_DOMAINS" -o $LIST || error "unable to download $HOSTLIST_DOMAINS"
  else
    wget -q -T 5 "$HOSTLIST_DOMAINS" -O $LIST || error "unable to download $HOSTLIST_DOMAINS"
  fi
  [ -s "$LIST" ] && log "downloaded successfully: $HOSTLIST_DOMAINS"
}

download() {
  download_nfqws
  download_list
}

case "$1" in
  start)
    start_service
    ;;
  stop)
    stop_service
    ;;
  status)
    status_service
    ;;
  restart)
    stop_service
    start_service
    ;;
  firewall-start)
    firewall_start
    ;;
  firewall-stop)
    firewall_stop
    ;;
  offload-start)
    offload_start
    ;;
  offload-stop)
    offload_stop
    ;;
  reload)
    reload_service
    ;;
  download)
    download
    ;;
  download-nfqws)
    download_nfqws
    ;;
  download-list)
    download_list
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|download|download-nfqws|download-list|status}"
esac
