#!/bin/sh

DOH_BIN="/usr/sbin/https_dns_proxy"
PIDFILE="/var/run/https_dns_proxy.pid"
FIRST_PORT="65055"

log()
{
  [ -n "$@" ] || return
  echo "$@"
  logger -t "https_dns_proxy" "$@"
}

start_service()
{
    if [ -f "$PIDFILE" ]; then
        echo "already running"
        return
    fi

    unset started
    start_doh() {
        [ "$2" ] || return
        local bootstrap_dns=""
        [ "$3" ] && bootstrap_dns="-b $3"

        $DOH_BIN -p $1 -r $2 $bootstrap_dns -a 127.0.0.1 -u nobody -g nogroup -4 -d
        if pgrep -x "$DOH_BIN" 2>&1 >/dev/null; then
            [ ! "$started" ] && log "started, version $($DOH_BIN -V)" && started=1
            log "start resolving to $2 : $1"
            touch "$PIDFILE"
        fi
    }

    for i in 1 2 3; do
        start_doh $(($FIRST_PORT+$i-1)) "$(nvram get doh_server$i)" "$(nvram get doh_server_ip$i)"
    done
}

stop_service()
{
    killall -q $(basename "$DOH_BIN") && log "stopped"

    local loop=0
    while pgrep -x "$DOH_BIN" 2>&1 >/dev/null && [ $loop -lt 50 ]; do
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
