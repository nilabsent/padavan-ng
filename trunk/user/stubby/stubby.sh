#!/bin/sh

STUBBY_BIN="/usr/sbin/stubby"
STUBBY_CONFIG="/etc/storage/stubby/stubby.yml"
PIDFILE="/var/run/stubby.pid"
MARK="####### LIST OF SERVERS ######"

make_default_config()
{
    mkdir -p $(dirname "$STUBBY_CONFIG")
    cat << EOF > $STUBBY_CONFIG
####### STUBBY YAML CONFIG FILE ######
resolution_type: GETDNS_RESOLUTION_STUB
dns_transport_list:
  - GETDNS_TRANSPORT_TLS
tls_authentication: GETDNS_AUTHENTICATION_REQUIRED
tls_query_padding_blocksize: 128
edns_client_subnet_private : 1
round_robin_upstreams: 1
idle_timeout: 10000
listen_addresses:
  - 127.0.0.1@65054
  - 0::1@65054
####### DNSSEC SETTINGS ######
#dnssec_return_status: GETDNS_EXTENSION_TRUE
#dnssec_return_only_secure: GETDNS_EXTENSION_TRUE
#trust_anchors_backoff_time: 2500
#appdata_dir: "/var/lib/stubby"
#######  UPSTREAMS  ######
upstream_recursive_servers:
$MARK
EOF
}

log() {
  [ -n "$@" ] || return
  echo "$@"
  local pid
  [ -f "$PIDFILE" ] && pid="[$(cat "$PIDFILE" 2>/dev/null)]"
  logger -t "stubby$pid" "$@"
}

check_config()
{
    if [ ! -f "$STUBBY_CONFIG" ]; then
        make_default_config || return 1
    fi

    if ! grep -q "^upstream_recursive_servers:$" "$STUBBY_CONFIG"; then
        make_default_config
    fi

    if ! grep -q "^$MARK$" "$STUBBY_CONFIG"; then
        make_default_config
    fi
}

start_service()
{
    if [ -f "$PIDFILE" ]; then
        echo "already running"
        return
    fi

    check_config || exit 1

    sed -i "1,/$MARK/!d" $STUBBY_CONFIG >/dev/null 2>&1

    make_config_servers()
    {
        [ "$1" ] || return
        [ "$2" ] || return
        echo "  - address_data: $2" >> $STUBBY_CONFIG
        echo "    tls_auth_name: $1" >> $STUBBY_CONFIG
    }

    for i in 1 2 3; do
        make_config_servers "$(nvram get stubby_server$i)" "$(nvram get stubby_server_ip$i)"
    done

    $STUBBY_BIN -g
    if pgrep -x "$STUBBY_BIN" 2>&1 >/dev/null; then
        log "started, version $($STUBBY_BIN -V | awk '{print $2}')"
    fi
}

stop_service()
{
    killall -q $(basename "$STUBBY_BIN") && log "stopped"

    local loop=0
    while pgrep -x "$STUBBY_BIN" 2>&1 >/dev/null && [ $loop -lt 50 ]; do
        loop=$((loop+1))
        read -t 0.2
    done

    rm -f "$PIDFILE"
}

case "$1" in
    start)
        start_service
    ;;
    stop)
        stop_service
    ;;
    restart)
        stop_service
        start_service
    ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
    ;;
esac

exit 0
