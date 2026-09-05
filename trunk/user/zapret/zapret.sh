#!/bin/sh

### https://github.com/nilabsent/padavan-ng

NFQWS_BIN="/usr/bin/nfqws"
NFQWS_BIN_OPT="/opt/bin/nfqws"
NFQWS_BIN_GIT="/tmp/nfqws"
ETC_DIR="/etc/storage"

CONF_DIR="${ETC_DIR}/zapret"
CONF_DIR_EXAMPLE="/usr/share/zapret"
STRATEGY_FILE="$CONF_DIR/strategy"
PID_FILE="/var/run/zapret.pid"
POST_SCRIPT="$CONF_DIR/post_script.sh"

STARTUP_CONF="/tmp/zapret.conf"

DESYNC_MARK="0x40000000"
# mark allowed clients
FILTER_MARK="0x10000000"

DEFAULT_TCP_PORTS="80,443"
DEFAULT_UDP_PORTS="443"
# when port value is *
DEFAULT_ALL_PORTS="80-65535"

NFQUEUE_NUM=200
USER="nobody"

HOSTLIST_DOMAINS="https://github.com/1andrevich/Re-filter-lists/releases/latest/download/domains_all.lst"

HOSTLIST_MARKER="<HOSTLIST>"
HOSTLIST_NOAUTO_MARKER="<HOSTLIST_NOAUTO>"

HOSTLIST_NOAUTO="
  --hostlist=${CONF_DIR}/user.list
  --hostlist=${CONF_DIR}/auto.list
  --hostlist-exclude=${CONF_DIR}/exclude.list
  --hostlist=/tmp/filter.list
  --ipset=${CONF_DIR}/ipset.list
  --ipset-exclude=${CONF_DIR}/ipset-exclude.list
"
HOSTLIST="
  --hostlist=${CONF_DIR}/user.list
  --hostlist-exclude=${CONF_DIR}/exclude.list
  --hostlist-auto=${CONF_DIR}/auto.list
  --hostlist=/tmp/filter.list
  --ipset=${CONF_DIR}/ipset.list
  --ipset-exclude=${CONF_DIR}/ipset-exclude.list
"

unset IPSET
[ -x "/sbin/ipset" ] && IPSET=1

###

log()
{
    [ -n "$*" ] || return
    echo "$@" >&2
    local pid
    [ -f "$PID_FILE" ] && pid="[$(cat "$PID_FILE" 2>/dev/null)]"
    logger -t "zapret${NFQWS_VER}$pid" "$@"
}

error()
{
    log "$@"
    exit 1
}

isp_is_present()
{
    [ "$(echo "$ISP_IF" | tr -d ' ,\n')" ]
}

is_running()
{
    [ -f "$PID_FILE" ]
}

status_service()
{
    if is_running; then
        echo "service nfqws${NFQWS_VER} is running"
        exit 0
    else
        echo "service nfqws${NFQWS_VER} is stopped"
        exit 1
    fi
}

kernel_modules()
{
    # "modprobe -a" may not supported
    for i in nfnetlink_queue xt_connbytes xt_NFQUEUE nft-queue; do
        modprobe -q $i >/dev/null 2>&1
    done
}

startup_args()
{
    echo "--daemon"
    echo "--pidfile=$PID_FILE"
    echo "--user=$USER"
    echo "--qnum=$NFQUEUE_NUM"
    [ "$LOG_LEVEL" = "1" ] && echo "--debug=syslog"

    if [ "$NFQWS_VER" = "2" ]; then
        local i lua="$CONF_DIR_EXAMPLE/lua"

        [ -x "${NFQWS_BIN_GIT}$NFQWS_VER" ] && [ -d "/tmp/zapret2/lua" ] \
            && lua="/tmp/zapret2/lua"

        for i in $(find "$lua" -maxdepth 1 -name "*.lua" -o -name "*.lua.gz"); do
            echo "--lua-init=@$i"
        done
    fi

    local strategy="$(grep -v '^[[:space:]]*#' "$STRATEGY_FILE")"
    strategy="${strategy//$HOSTLIST_MARKER/$HOSTLIST}"
    strategy="${strategy//$HOSTLIST_NOAUTO_MARKER/$HOSTLIST_NOAUTO}"

    echo "$strategy"
}

filter_ipv4()
{
    grep -E -x '^[[:space:]]*((25[0-5]|2[0-4][0-9]|1[0-9]{2}|0?[0-9]{1,2})\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|0?[0-9]{1,2})(/(3[0-2]|[12]?[0-9]))?[[:space:]]*$' \
        | sed -E 's#/32|/0##g' | sort | uniq
}

ipset_create_exclude()
{
    [ -n "$IPSET" ] || return

    ipset -q create nozapret$1 nethash family inet$1
    ipset -q flush nozapret$1

    local i
    if [ -n "$1" ]; then
        for i in ::1 fc00::/7 fe80::/10
        do
            ipset -q add nozapret$1 $i
        done
    else
        filter_ipv4 < "${CONF_DIR}/ipset-exclude.list" \
            | sed -E 's#^(.*)$#add nozapret \1#' \
            | ipset restore

        for i in \
            127.0.0.0/8 169.254.0.0/16 100.64.0.0/10 \
            198.18.0.0/15 192.88.99.0/24 192.0.0.0/24 \
            192.0.2.0/24 198.51.100.0/24 203.0.113.0/24 \
            192.168.0.0/16 10.0.0.0/8 172.16.0.0/12 \
            224.0.0.0/4 240.0.0.0/4
        do
            ipset -q add nozapret $i
        done
    fi
}

ipset_exclude()
{
    [ -n "$IPSET" ] || return

    echo "-m set ! --match-set nozapret$2 $1"
}

get_ipset_name_hash()
{
    # converting ipset name into hash

    [ -n "$1" ] || return

    case "$1" in
        0x*)
            return 1
        ;;

        *[!0-9]*)
            echo "0x$(echo -n "$1" | md5sum | cut -c1-7)"
        ;;

        *)
            return 1
        ;;
    esac
}

get_ipset_name_fwmark()
{
    # get ipset names from --filter-mark
    # reverse sorting by word length for safe replacement with a hash

    awk '
        !/^[[:space:]]*#/{
            for(i=1; i<=NF; i++)
                if($i ~ /^--filter-mark=/) {
                    v=substr($i, 15)
                    if(v !~ /^0x/ && v ~ /[a-zA-Z]/)
                        print length(v), v
            }
        }
    ' $STRATEGY_FILE | sort -u | sort -nr | cut -d' ' -f2-
}

get_strategy_ports()
{
    local proto="$1"
    local default_ports

    if [ "$proto" = "tcp" ]; then
        default_ports="$DEFAULT_TCP_PORTS"
    elif [ "$proto" = "udp" ]; then
        default_ports="$DEFAULT_UDP_PORTS"
    else
        return 1
    fi

    awk -v proto="$proto" \
        -v def_ports="$default_ports" \
        -v all_ports="$DEFAULT_ALL_PORTS" '

        /^[[:space:]]*#/ { next }
        {
            line = $0
            while (match(line, "--filter-" proto "=[0-9*~,-]+")) {
                str = substr(line, RSTART, RLENGTH)
                sub(/^[^=]*=/, "", str)

                n = split(str, ports_arr, ",")
                for (i = 1; i <= n; i++) {
                    p = ports_arr[i]

                    if (p ~ /~/) continue

                    gsub(/\*/, all_ports, p)
                    gsub(/-/, ":", p)

                    print p
                }

                line = substr(line, RSTART + RLENGTH)
            }
        }
        END {
            n = split(def_ports, def_arr, ",")
            for (i = 1; i <= n; i++) print def_arr[i]
        }
    ' "$STRATEGY_FILE" | sort -u
}

get_port_list()
{
    # set limit for multiport iptables

    local port_limit=7

    echo "$1" | xargs -n $port_limit | tr ' ' ','
}

cb()
{
    echo "-m connbytes --connbytes-dir $1 --connbytes-mode packets --connbytes 1:$2"
}

set_chain_rules()
{
    # $1 = "6" - sign that it is ipv6

    local i port filter hash
    local jnfq="-j NFQUEUE --queue-num $NFQUEUE_NUM --queue-bypass"

    # allowed clients enable only for ipv4
    if [ -n "$CLIENTS_ALLOWED" ] && [ -z "$1" ]; then
        filter="-m mark --mark $FILTER_MARK/$FILTER_MARK"

        echo "-A zapret_out -j MARK --or-mark $FILTER_MARK"
        for i in $CLIENTS_ALLOWED; do
            echo "-A zapret_mark -s $i -j MARK --or-mark $FILTER_MARK"
        done
    fi

    # create iptables rules for ipset mark, mark = ipset name hash
    [ -z "$1" ] && for i in $IPSET_FWMARK; do
        if hash=$(get_ipset_name_hash "$i"); then
            ipset -q create $i nethash family inet \
            && log "'$i' created successfully"

            echo "-A zapret_mark -m set --match-set $i dst -j MARK --or-mark $hash"
        fi
    done

    for i in $ISP_IF; do
        echo "-A zapret_pre -i $i $(ipset_exclude src $1) $jnfq"

        for port in $(get_port_list "$TCP_PORTS"); do
            echo "-A zapret_post -o $i -p tcp -m multiport --dports $port $filter $(ipset_exclude dst $1) $jnfq"
        done

        for port in $(get_port_list "$UDP_PORTS"); do
            echo "-A zapret_post -o $i -p udp -m multiport --dports $port $filter $(ipset_exclude dst $1) $jnfq"
        done
    done
}

set_fw_rules()
{
    local check_mark="-m mark ! --mark $DESYNC_MARK/$DESYNC_MARK"

    echo "
-$1 PREROUTING -j zapret_mark
-$1 OUTPUT -j zapret_out
-$1 INPUT -p tcp $(cb reply 10) -m multiport --sports 80,443 -j zapret_pre
-$1 INPUT -p udp $(cb reply 3) --sport 443 -j zapret_pre
-$1 FORWARD -p tcp $(cb reply 10) -m multiport --sports 80,443 -j zapret_pre
-$1 FORWARD -p udp $(cb reply 3) --sport 443 -j zapret_pre
-$1 POSTROUTING -p tcp $check_mark $(cb original 20) -j zapret_post
-$1 POSTROUTING -p udp $check_mark $(cb original 5) -j zapret_post
"
}

iptables_stop()
{
    local i

    for i in "" $([ -d /proc/sys/net/ipv6 ] && echo 6); do
        ip${i}tables-restore -n 2>/dev/null <<EOF
*mangle
$(set_fw_rules D)
-F zapret_pre
-F zapret_post
-F zapret_out
-F zapret_mark
-X zapret_pre
-X zapret_post
-X zapret_out
-X zapret_mark
COMMIT
EOF
    done
}

firewall_stop()
{
    iptables_stop
}

iptables_start()
{
    local i

    for i in "" $([ -d /proc/sys/net/ipv6 ] && echo 6); do
        ipset_create_exclude $i
        ip${i}tables-restore -n <<EOF
*mangle
:zapret_pre - [0:0]
:zapret_post - [0:0]
:zapret_out - [0:0]
:zapret_mark - [0:0]
$(set_fw_rules I)
$(set_chain_rules $i)
COMMIT
EOF
    done
}

firewall_start()
{
    firewall_stop

    if isp_is_present; then
        if iptables_start; then
            log "firewall rules updated on interface(s): "$ISP_IF
        else
            log "firewall rules update failed"
        fi
    else
        log "interfaces not defined, firewall rules not set"
    fi
}

system_config()
{
    sysctl -w net.netfilter.nf_conntrack_checksum=0 >/dev/null 2>&1
    sysctl -w net.netfilter.nf_conntrack_tcp_be_liberal=1 >/dev/null 2>&1
}

create_random_pattern_files()
{
    rm -f /tmp/rnd*.bin

    local len=$(for i in $ISP_IF; do cat /sys/class/net/$i/mtu; done | sort | head -n1)
    [ ! "$len" ] && len=1280

    local pattern=$(grep -v "^[[:space:]]*#" "$STRATEGY_FILE" | tr -d '"' \
        | grep -Eo "[-](pattern|syndata|unknown|unknown-udp)=/tmp/rnd[0-9]?[.]bin" \
        | cut -d '=' -f2 | sort -u)

    if [ "$pattern" ]; then
        echo "creating random file(s): "$pattern
        for i in $pattern; do
            head -c $((len-28)) /dev/urandom > "$i"
        done
    fi
}

set_strategy_file()
{
    [ "$1" ] || return
    [ -s "$1" ] && STRATEGY_FILE="$1"
    [ -s "${CONF_DIR}/$1" ] && STRATEGY_FILE="${CONF_DIR}/$1"
}

start_service()
{
    local i hash

    [ -s "$NFQWS_BIN" -a -x "$NFQWS_BIN" ] || error "$NFQWS_BIN: not found or invalid"
    if is_running; then
        echo "already running"
        return
    fi

    kernel_modules
    local pattern=$(create_random_pattern_files)

    [ -d "$STARTUP_CONF" ] && rm -rf "$STARTUP_CONF"
    echo "$(startup_args)" > "$STARTUP_CONF"

    # replace ipset names with hash in STARTUP_CONF
    for i in $IPSET_FWMARK; do
        if hash=$(get_ipset_name_hash "$i"); then
            sed -i "s|--filter-mark=$i|--filter-mark=$hash/$hash|g" "$STARTUP_CONF"
        fi
    done

    res=$($NFQWS_BIN @"$STARTUP_CONF" 2>&1)
    if [ ! "$?" = "0" ]; then
        log "failed to start $(basename $NFQWS_BIN): $(echo "$res" | head -n3 | grep -Ev '^$|github version')"
        exit 1
    fi

    log "started $(basename $NFQWS_BIN), $(echo "$res" | grep 'github version')"
    [ -n "$CLIENTS_ALLOWED" ] && log "allowed clients: "$CLIENTS_ALLOWED
    [ -n "$IPSET_FWMARK" ] && log "use ipsets: "$IPSET_FWMARK
    log "use strategy from $STRATEGY_FILE"
    log "$pattern"
    echo "$res" \
    | grep -Ei "loaded|profile" \
    | while read -r i; do
        log "$i"
    done

    system_config
    firewall_start
}

stop_service()
{
    firewall_stop

    killall -q nfqws && log "stopped"
    killall -q nfqws2 && log "stopped"

    rm -f "$PID_FILE"
}

reload_service()
{
    is_running || return

    firewall_start
    kill -HUP $(cat "$PID_FILE")
}

angry_wget() {
    local r=1

    while [ $r -lt 11 ]; do
        wget -T10 --no-check-certificate "$1" -O "$2" && return 0 || sleep $r
        r=$((r + 1))
    done

    return 1
}

download_nfqws()
{
    # $1 - nfqws2
    # $2 - nfqws version number starting from 69.3

    local archive="/tmp/zapret$1.tar.gz"

    ARCH=$(uname -m | grep -oE 'mips|mipsel|aarch64|arm|rlx|i386|i686|x86_64')
    case "$ARCH" in
        aarch64*)
            ARCH="(aarch64|arm64)"
        ;;
        armv*)
            ARCH="arm"
        ;;
        rlx)
            ARCH="lexra"
        ;;
        mips)
            ARCH="(mips32r1-msb|mips)"
            grep -qE 'system type.*(MediaTek|Ralink)' /proc/cpuinfo && ARCH="(mips32r1-lsb|mipsel)"
        ;;
        i386|i686)
            ARCH="x86"
        ;;
    esac
    [ -n "$ARCH" ] || error "cpu arch unknown"

    if [ "$2" ]; then
        URL="https://github.com/bol-van/zapret$1/releases/download/v$2/zapret$1-v$2-openwrt-embedded.tar.gz"
        if [ -x /usr/bin/curl ]; then
            curl -SL --retry 10 --retry-all-errors --progress-bar "$URL" -o $archive \
                || error "unable to download $URL"
        else
            angry_wget "$URL" $archive \
                || error "unable to download $URL"
        fi
    else
        if [ -x /usr/bin/curl ]; then
            URL=$(curl -sSL --retry 10 --retry-all-errors "https://api.github.com/repos/bol-van/zapret$1/releases/latest" \
                  | grep 'browser_download_url.*openwrt-embedded' | cut -d '"' -f4)
            [ -n "$URL" ] || error "unable to get archive link"

            curl -SL --retry 10 --retry-all-errors --progress-bar "$URL" -o $archive \
                || error "unable to download: $URL"
        else
            URL=$(wget -q -T20 --no-check-certificate "https://api.github.com/repos/bol-van/zapret$1/releases/latest" -O- \
                  | tr ',' '\n' | grep 'browser_download_url.*openwrt-embedded' | cut -d '"' -f4)
            [ -n "$URL" ] || error "unable to get archive link"

            angry_wget "$URL" $archive \
                || error "unable to download: $URL"
        fi
    fi

    [ -s $archive ] || exit
    [ $(cat $archive | head -c3) = "Not" ] && error "not found: $URL"
    log "downloaded successfully: $URL"

    local nfqws_bin=$(tar tzfv $archive | grep -E "binaries/(linux-)?$ARCH/nfqws$1" | awk '{print $6}')
    [ -n "$nfqws_bin" ] || error "nfqws$1 not found for architecture $ARCH"

    local lua=$(tar tzfv $archive | grep "lua/zapret" | awk '{print $6}')
    if [ -n "$lua" ]; then
        rm -rf /tmp/zapret2/lua
        mkdir -p /tmp/zapret2
        tar xzf $archive \
            $(tar tzfv $archive | grep "lua/zapret" | awk '{print $6}') \
            --strip-components 1 --overwrite -C /tmp/zapret2
    fi

    tar xzf $archive "$nfqws_bin" --strip-components 3 -C /tmp
    if [ -s $NFQWS_BIN_GIT$1 ]; then
        chmod +x $NFQWS_BIN_GIT$1
    else
        log "error: nfqws$1 extract failed"
    fi

    rm -f $archive
    echo "done"
}

download_list()
{
    local list="/tmp/filter.list"

    if [ -x /usr/bin/curl ]; then
        curl -SL --connect-timeout 20 --progress-bar "$HOSTLIST_DOMAINS" -o $list || error "unable to download $HOSTLIST_DOMAINS"
    else
        angry_wget "$HOSTLIST_DOMAINS" $list || error "unable to download $HOSTLIST_DOMAINS"
    fi

    [ -s "$list" ] && log "downloaded successfully: $HOSTLIST_DOMAINS"
}

if id -u >/dev/null 2>&1; then
    [ $(id -u) != "0" ] && echo "root user is required to start" && exit 1
fi

[ -f "$CONF_DIR" ] && rm -f "$CONF_DIR"
[ -d "$CONF_DIR" ] || mkdir -p "$CONF_DIR" || exit 1

# copy all non-existent config files to storage except fake dir
[ -d "$CONF_DIR_EXAMPLE" ] && false | cp -i "${CONF_DIR_EXAMPLE}"/* "$CONF_DIR" >/dev/null 2>&1

for i in user exclude auto ipset ipset-exclude; do
    [ -f ${CONF_DIR}/$i.list ] || touch ${CONF_DIR}/$i.list || exit 1
done
touch /tmp/filter.list

ISP_IF="$(nvram get zapret_iface | tr -s ' ,' '\n' | sort -u)"
if [ -z "$ISP_IF" ]; then
    ISP_IF4="$(nvram get wan0_ifname)"
    ISP_IF6="$(nvram get wan0_ifname6)"

    ISP_IF=$(printf "%s\n" $ISP_IF4 $ISP_IF6 | sort -u)
fi

LOG_LEVEL="$(nvram get zapret_log)"
CLIENTS_ALLOWED="$(nvram get zapret_clients_allowed | tr -s ',' '\n')"

STRATEGY_FILE="${STRATEGY_FILE}$(nvram get zapret_strategy)"
set_strategy_file "$2"

TCP_PORTS=$(get_strategy_ports tcp)
UDP_PORTS=$(get_strategy_ports udp)

IPSET_FWMARK="$(get_ipset_name_fwmark)"

# nfqws2 support
unset NFQWS_VER
grep -q "^[^#]*[-][-]lua-desync" "$STRATEGY_FILE" && NFQWS_VER=2
[ "$1" = "start2" ] || [ "$1" = "restart2" ] && NFQWS_VER=2

[ -x "${NFQWS_BIN}${NFQWS_VER}" ] && NFQWS_BIN="${NFQWS_BIN}${NFQWS_VER}"
[ -x "$NFQWS_BIN_OPT${NFQWS_VER}" ] && NFQWS_BIN="$NFQWS_BIN_OPT${NFQWS_VER}"
[ -x "$NFQWS_BIN_GIT${NFQWS_VER}" ] && NFQWS_BIN="$NFQWS_BIN_GIT${NFQWS_VER}"

case "$1" in
    start|start2)
        start_service
    ;;

    stop)
        stop_service
    ;;

    status)
        status_service
    ;;

    restart|restart2)
        stop_service
        start_service
    ;;

    firewall-start)
        firewall_start
    ;;

    firewall-stop)
        firewall_stop
    ;;

    reload)
        reload_service
    ;;

    download|download-nfqws)
        download_nfqws "" "$2"
    ;;

    download2|download-nfqws2)
        download_nfqws "2" "$2"
    ;;

    download-list)
        download_list
    ;;

    *)  echo "Usage: $0 {start{2} [strategy_file]|stop|restart{2} [strategy_file]|download{2} [version_nfqws]|download-list|status}"
esac

[ -s "$POST_SCRIPT" -a -x "$POST_SCRIPT" ] && . "$POST_SCRIPT"

exit 0
