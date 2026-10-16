#!/bin/sh

TOR_BIN="/usr/sbin/tor"
PID_FILE="/var/run/tor.pid"
PID_WAIT_SYNC_FILE="/var/run/tor_wait_sync.pid"

DATA_DIR="/tmp/tor"
unset OPT
[ -d "/opt/tmp" ] && OPT="/opt"

GEOIP_DIR="/usr/share/tor"
CONFIG_DIR="/etc/storage/tor"
CONFIG_FILE="$CONFIG_DIR/torrc"
TOR_REMOTE_LIST="$CONFIG_DIR/remote_network.list"
TOR_NETWORK_IPV4="172.24.0.0/13"
TOR_PORTS="80,443"
CONTROL_PORT=9051
DNS_PORT=9053
TRANS_PORT=9040

# 0 - disabled, 1 - redirect allowed remote, 2 - redirect all
NV_TOR_PROXY_MODE="$(nvram get tor_proxy_mode)"

TOR_IPSET_CLIENTS="tor.clients"
TOR_IPSET_REMOTE="tor.remote"
TOR_IPSET_EXCLUDE="tor.exclude"

# get comma separated lists for nvram
NV_IPSET_LIST="$(nvram get tor_ipset_allowed | tr -s ' ,' '\n')"
NV_TOR_CLIENTS="$(nvram get tor_clients_allowed | tr -s ' ,' '\n')"

NV_TOR_EXCLUDE="
0.0.0.0/8
127.0.0.0/8
169.254.0.0/16
224.0.0.0/4
240.0.0.0/4
100.64.0.0/10
10.0.0.0/8
192.168.0.0/16
172.16.0.0/13
198.18.0.0/15
192.88.99.0/24
192.0.0.0/24
192.0.2.0/24
198.51.100.0/24
203.0.113.0/24
"

unset IPSET
[ -x /sbin/ipset ] && IPSET=1

log()
{
    [ -n "$*" ] || return
    echo "$@" >&2

    local pid
    [ -f "$PID_FILE" ] && pid="[$(cat "$PID_FILE" 2>/dev/null)]"
    logger -t "Tor$pid" "$@"
}

error()
{
    log "error: $@"
    exit 1
}

die()
{
    [ -n "$*" ] && echo "$@" >&2
    exit 1
}

is_started()
{
    [ -z "$(pidof $(basename "$TOR_BIN"))" ] && return 1
    [ -f "$PID_FILE" ]
}

tor_control()
{
    nc -z 127.0.0.1 $CONTROL_PORT >/dev/null 2>&1 || die
    [ -n "$1" ] || return
    printf 'AUTHENTICATE ""\r\n%s\r\nQUIT\r\n' "$1" \
        | nc -w 5 127.0.0.1 $CONTROL_PORT 2>/dev/null
}

tor_get_status()
{
    tor_control 'GETINFO status/bootstrap-phase' \
        | sed -n 's|250-status/||p'
}

tor_ready() {
    local status="$(tor_get_status)"
    [ -n "$status" ] || return 1

    echo "$status" \
        | sed 's| \([A-Z]\)|\n\1|g' \
        | grep -E 'PROGRESS=|WARNING=|HOSTADDR=|SUMMARY=' \
        | xargs -r -d'\n'
    echo $status | grep -q 'PROGRESS=100'
}

tor_waiting_bootstrap()
{
    local loop=0
    local pid="$(cat $PID_FILE 2>/dev/null)"

    echo "waiting bootstrapping..."
    while ! tor_ready && [ $loop -lt 60 ]; do
        is_started || die
        [ ! "$pid" = "$(cat $PID_FILE 2>/dev/null)" ] && die
        loop=$((loop+1))
        sleep 5
    done
    echo "done"

    rm -f "$PID_WAIT_SYNC_FILE"
    sync && sysctl -q vm.drop_caches=3
    start_redirect
}

start_tor()
{
    is_started && die "already started"

    [ -s "$CONFIG_FILE" ] || error "not found configuration file $CONFIG_FILE"

    if [ -d "/opt/share/tor" ]
    then
        mount | grep -q $GEOIP_DIR || mount --bind /opt/share/tor $GEOIP_DIR
    fi

    log "started, data directory: ${OPT}${DATA_DIR}"
    rm -rf ${OPT}${DATA_DIR}
    rm -rf $DATA_DIR

    $TOR_BIN --RunAsDaemon 1 \
        --DataDirectory ${OPT}${DATA_DIR} \
        --ControlPort $CONTROL_PORT \
        --CookieAuthentication 0 \
        --DNSPort 0.0.0.0:$DNS_PORT \
        --VirtualAddrNetworkIPv4 $TOR_NETWORK_IPV4 \
        --TransPort 0.0.0.0:$TRANS_PORT \
        --PidFile $PID_FILE

    if [ "$?" -eq 0 ]; then
        [ "$NV_TOR_PROXY_MODE" = "0" -o -z "$NV_TOR_PROXY_MODE" ] && return
        sleep 1
        tor_waiting_bootstrap &
        echo $! > "$PID_WAIT_SYNC_FILE"
    fi
}

stop_tor()
{
    stop_redirect
    killall -q -SIGKILL $(basename "$TOR_BIN") && log "stopped"

    if mountpoint -q $GEOIP_DIR ; then
        umount -l $GEOIP_DIR
    fi

    rm -rf ${OPT}${DATA_DIR}
    rm -rf $DATA_DIR
    rm -f $PID_FILE
    [ -f "$PID_WAIT_SYNC_FILE" ] \
        && kill "$(cat "$PID_WAIT_SYNC_FILE")" 2>/dev/null \
        && rm -f "$PID_WAIT_SYNC_FILE"
}

reload_tor()
{
    is_started || return

    kill -SIGHUP $(cat "$PID_FILE")
}

### transparent proxy

filter_ipv4()
{
    grep -E -x '^[[:space:]]*((25[0-5]|2[0-4][0-9]|1[0-9]{2}|0?[0-9]{1,2})\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|0?[0-9]{1,2})(/(3[0-2]|[12]?[0-9]))?[[:space:]]*$' \
        | sed -E 's#/32|/0##g' | sort | uniq
}

fill_ipset()
{
    # $1: "list" - file list; "" - var with line break

    local mode="$1"
    local name="$2"
    local list="$3"

    [ -n "$name" ] || return
    ipset -q create $name nethash
    ipset -q flush $name

    if [ "$mode" = "list" ]; then
        [ -s "$list" ] || return
        filter_ipv4 < $list \
            | sed -E 's#^(.*)$#add '"$name"' \1#' \
            | ipset -! restore
    else
        [ -n "$list" ] || return
        printf '%s\n' "$list" | filter_ipv4 \
            | sed -E 's#^(.*)$#add '"$name"' \1#' \
            | ipset -! restore
    fi

    [ $? -eq 0 ] || log "ipset '$name' failed to update"
}

create_ipset()
{
    fill_ipset "nv" "$TOR_IPSET_CLIENTS" "$NV_TOR_CLIENTS"
    fill_ipset "nv" "$TOR_IPSET_EXCLUDE" "$NV_TOR_EXCLUDE"
    fill_ipset "list" "$TOR_IPSET_REMOTE" "$TOR_REMOTE_LIST"
    ipset -q add "$TOR_IPSET_REMOTE" "$TOR_NETWORK_IPV4"

    local name
    for name in $NV_IPSET_LIST; do
        ipset -q create $name nethash
    done
}

stop_redirect()
{
    [ -n "$IPSET" ] || return

    iptables-restore -n <<EOF
*nat
$(iptables-save -t nat | sed -n '/PREROUTING .* -j tor_proxy\b/s/^-A/-D/p')
-F tor_proxy
-X tor_proxy
COMMIT
EOF
}

make_rules()
{
    local i

    [ -n "$NV_TOR_CLIENTS" ] \
        && echo "-A tor_proxy -m set ! --match-set $TOR_IPSET_CLIENTS src -j RETURN"

    if [ "$NV_TOR_PROXY_MODE" = "1" ]; then
        for i in $TOR_IPSET_REMOTE $NV_IPSET_LIST; do
            echo "-A tor_proxy -p tcp -m set --match-set $i dst -j REDIRECT --to-ports $TRANS_PORT"
        done
    else
        echo "-A tor_proxy -p tcp -j REDIRECT --to-ports $TRANS_PORT"
    fi
}

start_redirect()
{
    stop_redirect

    is_started || return 1
    [ "$NV_TOR_PROXY_MODE" = "0" -o -z "$NV_TOR_PROXY_MODE" ] && return
    [ -f "$PID_WAIT_SYNC_FILE" ] && return
    [ -n "$IPSET" ] || return

    create_ipset

    iptables-restore -n <<EOF
*nat
:tor_proxy - [0:0]
-A PREROUTING -p tcp -m multiport --dports $TOR_PORTS -m set ! --match-set $TOR_IPSET_EXCLUDE dst -j tor_proxy
$(make_rules)
COMMIT
EOF
    [ $? -eq 0 ] || error "firewall rules update failed"
}

case "$1" in
    start)
        start_tor
    ;;

    stop)
        stop_tor
    ;;

    restart)
        stop_tor
        start_tor
    ;;

    reload)
        reload_tor
    ;;

    update)
        start_redirect
    ;;

    status)
        tor_get_status
    ;;

    control)
        tor_control "$2"
    ;;

    *)
        echo "Usage: $0 {start|stop|restart|reload|update|status|control <command>}"
        exit 1
    ;;
esac

exit 0
