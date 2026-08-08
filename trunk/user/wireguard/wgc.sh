#!/bin/sh

###

TIMEOUT_OFFLINE=300

MODULE="wireguard"
[ -d "/lib/modules/3.4.113/kernel/net/amneziawg" ] \
    && MODULE="amneziawg"

WG="wg"
IF_NAME="wg0"
IF_ADDR="$(nvram get vpnc_wg_if_addr | tr -s ' ,' '\n')"
IF_MTU="$(nvram get vpnc_wg_mtu)"
[ "$IF_MTU" ] || IF_MTU=1420
IF_PRIVATE="$(nvram get vpnc_wg_if_private)"
IF_PRESHARED="$(nvram get vpnc_wg_if_preshared)"
IF_DNS="$(nvram get vpnc_wg_if_dns | tr -s ',' ' ')"

unset DEFAULT
[ "$(nvram get vpnc_dgw)" = "1" ] && DEFAULT=1

LOCK_WATCHDOG="/var/lock/wgc_watchdog.lock"

PEER_PUBLIC="$(nvram get vpnc_wg_peer_public)"
PEER_PORT="$(nvram get vpnc_wg_peer_port)"
PEER_ENDPOINT="$(nvram get vpnc_wg_peer_endpoint)"
PEER_KEEPALIVE="$(nvram get vpnc_wg_peer_keepalive)"
[ -n "$PEER_KEEPALIVE" ] || PEER_KEEPALIVE=25
PEER_ALLOWEDIPS="$(nvram get vpnc_wg_peer_allowedips | tr -s ',' '\n')"
POST_SCRIPT="/etc/storage/vpnc_post_script.sh"

REMOTE_NETWORK_LIST="/etc/storage/vpnc_remote_network.list"
EXCLUDE_NETWORK_LIST="/etc/storage/vpnc_exclude_network.list"

NV_CLIENTS_LIST="$(nvram get vpnc_clients_allowed | tr -s ' ,' '\n')"
NV_IPSET_LIST="$(nvram get vpnc_ipset_allowed | tr -s ' ,' '\n')"

TABLE=51
FWMARK=51820
PREF_WG=5182
PREF_MAIN=5181

DNSMASQ_IPSET="unblock"

# nethash remote networks
VPN_REMOTE_IPSET="vpn.remote"
# nethash excluded remote networks
VPN_EXCLUDE_IPSET="vpn.exclude"
# nethash allowed LAN clients
VPN_CLIENTS_IPSET="vpn.clients"

###

unset IPSET
[ -x "/sbin/ipset" ] && IPSET=1

log()
{
    [ -n "$*" ] || return
    echo "$@"
    logger -t $MODULE "$@"
}

error()
{
    [ -n "$*" ] && log "error: $@" >&2
    stop_wg
    exit 1
}

die()
{
    [ -n "$*" ] && echo "$@" >&2
    exit 1
}

is_started()
{
    [ -d "/sys/class/net/${IF_NAME}" ]
}

set_state()
{
    nvram settmp vpnc_state_t=$1
}

get_state()
{
    nvram get vpnc_state_t
}

prepare_wg()
{
    modprobe -q $MODULE

    sysctl -q net.ipv4.conf.all.src_valid_mark=1
    sysctl -q net.ipv6.conf.all.disable_ipv6=0 2>/dev/null
    sysctl -q net.ipv6.conf.all.forwarding=1 2>/dev/null
}

wg_setdns()
{
    [ "$IF_DNS" ] || return

    nvram set vpnc_dns_t="$IF_DNS"
    update_resolvconf
}

check_endpoint()
{
    local r=5
    while [ $r -gt 0 ]; do
        timeout 3 2>&1 nslookup $PEER_ENDPOINT >/dev/null 2>&1 && return 0
        r=$((r - 1))
    done
    return 1
}

check_host_available()
{
    if ! check_endpoint; then
        [ -z "$(nvram get wg_log_reduce_t)" ] && log "error: host $PEER_ENDPOINT not found"
        nvram settmp wg_log_reduce_t=1
        nvram settmp wg_need_restart_t=1
        return 1
    fi
}

setconf_wg()
{
    is_started || return 1

    check_host_available || exit 1

    local allowed_ipv6
    ip addr show $IF_NAME | grep -q "inet6" && allowed_ipv6=", ::/0"

    if [ "$MODULE" = "amneziawg" ]; then
        cps()
        {
            local i nv
            for i in \
                jc jmin jmax \
                i1 i2 i3 i4 i5 \
                h1 h2 h3 h4 \
                s1 s2 s3 s4 \
                ContentPaddingAddition HeaderProtectionKey \
                RekeyAfterTime RekeyTimeout RejectAfterTime \
                KeepaliveTimeout MaxHandshakeAttempts
            do
                nv=$(nvram get vpnc_awg_$i | tr -d '\n\r')
                [ -n "$nv" ] && echo "$i = $nv"
            done
        }
        awg="$(cps)"
    fi

    cat > "/tmp/${IF_NAME}.conf.$$" <<EOF
[Interface]
PrivateKey = $IF_PRIVATE
FwMark = $FWMARK
$awg

[Peer]
PublicKey = $PEER_PUBLIC
Endpoint = ${PEER_ENDPOINT}:${PEER_PORT}
PersistentKeepalive = $PEER_KEEPALIVE
AllowedIPs = 0.0.0.0/0$allowed_ipv6
EOF
    [ "$IF_PRESHARED" ] && echo "PresharedKey = $IF_PRESHARED" >> "/tmp/${IF_NAME}.conf.$$"

    log_try_connect
    local res=$($WG setconf $IF_NAME "/tmp/${IF_NAME}.conf.$$" 2>&1)
    rm -f "/tmp/${IF_NAME}.conf.$$"

    [ "$1" = "reconnect" ] && return

    if ! echo $res | grep -q "error"; then
        $WG show $IF_NAME | grep -A 5 "peer:" | grep -E "peer|endpoint" | while read i; do
            log "$i"
        done
        send_ping
    else
        echo "$res" | while read i; do
            log "$i"
        done
        return 1
    fi
}

prevent_access_loss()
{
    local i ep

    for i in \
        $(nvram get lan_ipaddr) \
        $(nvram get wan_ipaddr) \
        $(nvram get wan0_ipaddr)
    do
        [ "$i" = "0.0.0.0" ] && continue
        ip rule add from $i table main pref $PREF_MAIN
    done

    ep=$($WG show $IF_NAME endpoints | sed -r 's/^.+\t//; s/:[0-9]+$//; s/[][]*//g')
    [ -n "$ep" ] || return

    if [ "$ep" = "${ep#*:}" ]; then
        ip rule add to "$ep" table main pref $PREF_MAIN
    else
        ip -6 rule add to "$ep" table main pref $PREF_MAIN
    fi
}

add_default_route()
{
    ip rule add fwmark $FWMARK table $TABLE pref $PREF_WG
    ip route replace default dev $IF_NAME table $TABLE 2>/dev/null \
        || error "unable to add default route dev $IF_NAME table $TABLE"
}

add_route()
{
    # ¯\_(ツ)_/¯
    sync && sysctl -q vm.drop_caches=3
    usleep 100000

    add_default_route

    # for local cloudflare warp support on the router
    # padavan does not support nat64

    ip addr show $IF_NAME | grep -q "inet6" \
        && ip -6 route replace default dev $IF_NAME metric 1024 2>/dev/null

    prevent_access_loss
}

wg_if_init()
{
    local i p

    prepare_wg

    ip link add dev $IF_NAME type $MODULE 2>/dev/null || error "cannot create $IF_NAME"
    ip link set dev $IF_NAME mtu $IF_MTU

    for i in $IF_ADDR; do
        p=4; [ "$i" != "${i#*:}" ] && p=6
        ip -$p addr add "$i" dev $IF_NAME 2>/dev/null || log "warning: cannot set $IF_NAME address $i"
    done

    local if_ip=$(ip addr show dev $IF_NAME | awk '/inet/{print $2}')
    [ "$if_ip" ] || error "$IF_NAME interface address not set"

    if ip link set $IF_NAME up; then
        log "client started, interface: $IF_NAME, addresses: "$if_ip
    else
        error "$IF_NAME startup failed"
    fi
}

log_try_connect()
{
    set_state 2
    [ -n "$(nvram get wg_log_reduce_t)" ] && return
    log "trying connect to $PEER_ENDPOINT"
}

log_unable_connect()
{
    set_state 0
    [ -n "$(nvram get wg_log_reduce_t)" ] && return
    log "unable connect to $PEER_ENDPOINT"

    # prevent multiple messages
    nvram settmp wg_log_reduce_t=1
}

log_success_connect()
{
    [ "$(get_state)" = "1" ] && return
    log "successfully connected"
    set_state 1
    nvram unset wg_log_reduce_t
}

connect_wg()
{
    # $1 reconnect

    if check_connected; then
        [ -n "$(nvram get wg_log_reduce_t)" ] && log_success_connect
    else
        setconf_wg $1
        if check_connection_status; then
            log_success_connect
            return 0
        else
            log_unable_connect
            return 1
        fi
    fi
}

get_latest_handshakes()
{
    $WG show $IF_NAME latest-handshakes | cut -f2
}

send_ping()
{
    timeout 1 ping -I $IF_NAME 255.255.255.255 >/dev/null 2>&1
}

check_connected()
{
    is_started || die

    local lh now

    lh=$(get_latest_handshakes)
    now=$(date +%s)

    if [ -z "$lh" ] || [ "$lh" -eq 0 ]; then
        return 1
    fi

    [ "$((now - lh))" -gt 15 ] && send_ping
    [ "$((now - lh))" -gt "$TIMEOUT_OFFLINE" ] && return 1

    nvram settmp wg_latest_handshakes_t=$lh

    return 0
}

check_connection_status()
{
    local connected loop=0

    while is_started; do
        [ "$loop" -ge 15 ] && break
        check_connected && connected=1 && break
        loop=$((loop + 1))
        sleep 1
    done

    local now=$(date +%s)
    local lh_success=$(nvram get wg_latest_handshakes_t)

    if [ -n "$lh_success" ] && [ "$(( now -  $lh_success ))" -gt "$TIMEOUT_OFFLINE" ]; then
        log "unable to connect for more than 5 minutes, emergency restart"
        nvram settmp wg_need_restart_t=1
        exit
    fi

    [ -n "$connected" ]
}

start_wg()
{
    is_started && die "already started"

    (
        flock -n 200 || exit 1

        set_state 0
        check_host_available || exit 1

        nvram settmp wg_latest_handshakes_t=$(date +%s)
        nvram unset wg_need_restart_t
        nvram unset wg_log_reduce_t

        ipset_create
        wg_if_init
        connect_wg
        add_route
        wg_setdns
        start_fw

        call_post_script start

    ) 200>$LOCK_WATCHDOG
}

watchdog()
{
    (
        flock -n 200 || exit 1

        if [ -n "$(nvram get wg_need_restart_t)" ]; then
            stop_wg
            start_wg
            exit
        fi

        is_started || return

        connect_wg reconnect
        call_post_script watchdog

    ) 200>$LOCK_WATCHDOG
}

reload_wg()
{
    is_started || return 1

    ipset_create
    stop_fw
    start_fw && log "access control rules successfully updated"
}

update_wg()
{
    is_started || return 1

    start_fw
}

stop_wg()
{
    set_state 0
    stop_fw

    ip route flush table $TABLE 2>/dev/null
    ip -6 route del default dev $IF_NAME 2>/dev/null

    while ip rule del pref $PREF_WG 2>/dev/null; do true; done
    while ip rule del pref $PREF_MAIN 2>/dev/null; do true; done
    while ip -6 rule del pref $PREF_MAIN 2>/dev/null; do true; done

    ip link set $IF_NAME down 2>/dev/null
    ip link del dev $IF_NAME 2>/dev/null \
        && log "client stopped"

    rm -f "$LOCK_WATCHDOG"

    call_post_script stop
    nvram unset wg_need_restart_t
}

call_post_script()
{
    [ -s "$POST_SCRIPT" ] && [ -x "$POST_SCRIPT" ] || return

    MODULE="$MODULE" \
    WG="$WG" \
    IF_NAME="$IF_NAME" \
    IF_ADDR="$IF_ADDR" \
    IF_MTU="$IF_MTU" \
    IF_DNS="$IF_DNS" \
    PEER_PORT="$PEER_PORT" \
    PEER_ENDPOINT="$PEER_ENDPOINT" \
    PEER_ALLOWEDIPS="$PEER_ALLOWEDIPS" \
    NV_CLIENTS_LIST="$NV_CLIENTS_LIST" \
    NV_IPSET_LIST="$NV_IPSET_LIST" \
    TABLE="$TABLE" \
    FWMARK="$FWMARK" \
    PREF_WG="$PREF_WG" \
    PREF_MAIN="$PREF_MAIN" \
    "$POST_SCRIPT" "$1"
}

filter_ipv4()
{
    grep -E -x '^[[:space:]]*((25[0-5]|2[0-4][0-9]|1[0-9]{2}|0?[0-9]{1,2})\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|0?[0-9]{1,2})(/(3[0-2]|[12]?[0-9]))?[[:space:]]*$' \
        | sed -E 's#/32|/0##g' | sort | uniq
}

ipset_load()
{
    # $1: "list" - file list; "" - var with line break

    local mode="$1"
    local name="$2"
    local list="$3"

    [ -n "$name" ] || return
    ipset -q -N $name nethash \
        && log "ipset '$name' created successfully"
    ipset flush $name

    if [ "$mode" = "list" ]; then
        [ -s "$list" ] || return
        filter_ipv4 < $list \
            | sed -E 's#^(.*)$#add '"$name"' \1#' \
            | ipset restore
    else
        [ -n "$list" ] || return
        printf '%s\n' "$list" | filter_ipv4 \
            | sed -E 's#^(.*)$#add '"$name"' \1#' \
            | ipset restore
    fi

    [ $? -eq 0 ] || log "ipset '$name' failed to update"
}

ipset_create()
{
    # create ipset ipv4 entrys

    [ -n "$IPSET" ] || return

    ipset -q -N $DNSMASQ_IPSET nethash timeout 21600 \
        && log "ipset '$DNSMASQ_IPSET' with timeout 21600 created successfully"

    ipset_load "list" "$VPN_REMOTE_IPSET" "$REMOTE_NETWORK_LIST"
    ipset_load "list" "$VPN_EXCLUDE_IPSET" "$EXCLUDE_NETWORK_LIST"
    ipset_load "nv" "$VPN_CLIENTS_IPSET" "$NV_CLIENTS_LIST"

    local name
    for name in $NV_IPSET_LIST; do
        ipset -q -N $name nethash \
            && log "ipset '$name' created successfully"
    done

    for name in $(bogon_networks); do
        ipset -q add $VPN_EXCLUDE_IPSET $name
    done

    echo "$PEER_ALLOWEDIPS" | grep -qv "/0" \
    && log "adding additional AllowedIPs to ipset '$VPN_REMOTE_IPSET'"

    for name in $PEER_ALLOWEDIPS; do
        ipset -q add $VPN_REMOTE_IPSET "$name"
    done
}

bogon_networks()
{
    echo "0.0.0.0/8 127.0.0.0/8 169.254.0.0/16
        100.64.0.0/10 198.18.0.0/15 192.88.99.0/24
        192.0.0.0/24 192.0.2.0/24 198.51.100.0/24
        203.0.113.0/24 224.0.0.0/4 240.0.0.0/4
        $(nvram get vpns_vnet)/24
        $(nvram get lan_ipaddr)/24"
}

ipt_set_rules()
{
    local i

    if [ -n "$IPSET" ]; then
        if [ -n "$NV_CLIENTS_LIST" ]; then
            echo "-A vpnc_wireguard -m set ! --match-set $VPN_CLIENTS_IPSET src -j RETURN"
        fi

        echo "-A vpnc_wireguard -m set --match-set $VPN_EXCLUDE_IPSET dst -j RETURN"

        if [ -n "$DEFAULT" ]; then
            echo "-A vpnc_wireguard -j vpnc_wireguard_mark"
        else
            for i in "$VPN_REMOTE_IPSET" $NV_IPSET_LIST; do
                [ -n "$i" ] && echo "-A vpnc_wireguard -m set --match-set $i dst -j vpnc_wireguard_mark"
            done
        fi
    else
        for i in $(bogon_networks) $(filter_ipv4 < "$EXCLUDE_NETWORK_LIST"); do
            echo "-A vpnc_wireguard -d $i -j RETURN"
        done

        if [ -n "$NV_CLIENTS_LIST" ]; then
            for i in $NV_CLIENTS_LIST; do
                echo "-A vpnc_wireguard -s $i -j vpnc_wireguard_remote"
            done
        else
            echo "-A vpnc_wireguard -j vpnc_wireguard_remote"
        fi

        if [ -n "$DEFAULT" ]; then
            echo "-A vpnc_wireguard_remote -j vpnc_wireguard_mark"
        else
            for i in $(filter_ipv4 < "$REMOTE_NETWORK_LIST"); do
                echo "-A vpnc_wireguard_remote -d $i -j vpnc_wireguard_mark"
            done
        fi
    fi
}

check_fw()
{
    iptables -t mangle -nL vpnc_wireguard >/dev/null 2>&1
}

stop_fw()
{
    check_fw || return

    ipt_remove_rule(){ while iptables -t $1 -C $2 2>/dev/null; do iptables -t $1 -D $2; done }
    ipt_remove_chain(){ iptables -t $1 -F $2 2>/dev/null && iptables -t $1 -X $2 2>/dev/null; }

    ipt_remove_rule "mangle" "PREROUTING -s $(nvram get lan_ipaddr)/24 -j vpnc_wireguard"
    ipt_remove_rule "mangle" "PREROUTING -s $(nvram get vpns_vnet)/24 -j vpnc_wireguard"

    ipt_remove_chain "mangle" "vpnc_wireguard"
    ipt_remove_chain "mangle" "vpnc_wireguard_remote"
    ipt_remove_chain "mangle" "vpnc_wireguard_mark"
}

start_fw()
{
    is_started || return 1
    check_fw && return

    iptables-restore -n <<EOF
*mangle
:vpnc_wireguard - [0:0]
:vpnc_wireguard_remote - [0:0]
:vpnc_wireguard_mark - [0:0]
-A PREROUTING -s $(nvram get lan_ipaddr)/24 -j vpnc_wireguard
-A PREROUTING -s $(nvram get vpns_vnet)/24 -j vpnc_wireguard
-A vpnc_wireguard -p udp --dport 53 -j RETURN
-A vpnc_wireguard -p tcp --dport 53 -j RETURN
-A vpnc_wireguard -p udp --dport 123 -j RETURN
$(ipt_set_rules)
-A vpnc_wireguard_mark -j CONNMARK --restore-mark
-A vpnc_wireguard_mark -m mark --mark $FWMARK -j RETURN
-A vpnc_wireguard_mark -m conntrack --ctstate NEW -j MARK --set-mark $FWMARK
-A vpnc_wireguard_mark -m mark --mark $FWMARK -j CONNMARK --save-mark
COMMIT
EOF
    [ $? -eq 0 ] || log "firewall rules update failed"
}

case $1 in
    start)
        start_wg
    ;;

    stop)
        stop_wg
    ;;

    restart)
        stop_wg
        start_wg
    ;;

    update)
        update_wg
        call_post_script update
    ;;

    reload)
        reload_wg
        call_post_script reload
    ;;

    watchdog)
        watchdog
    ;;
esac
