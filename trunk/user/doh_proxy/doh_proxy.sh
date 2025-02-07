#!/bin/sh

func_start() {
    if [ -f "/var/run/doh_proxy.pid" ]; then
        logger -t doh_proxy "DoH proxy is running."
        return
    fi

    dns_prov=$(cat /etc/resolv.conf 2>/dev/null | grep nameserver | grep -v "127.0.0.1" | awk '{print $2}' | tr "\n" ",")
    dns_bs=$dns_prov"77.88.8.8,1.1.1.1,8.8.8.8,9.9.9.9,208.67.222.222,94.140.14.14"

    start_doh() {
        [ "$2" ] || return
        /usr/sbin/doh_proxy -r "$2" -p "$1" -b "$dns_bs" -a 127.0.0.1 -u nobody -g nogroup -d
        logger -t doh_proxy "Start resolving to $2 : $1"
    }

    start_doh 65055 "$(nvram get doh_server1)"
    start_doh 65056 "$(nvram get doh_server2)"
    start_doh 65057 "$(nvram get doh_server3)"
    start_doh 65058 "$(nvram get doh_server4)"

    touch /var/run/doh_proxy.pid
    sync && echo 3 > /proc/sys/vm/drop_caches
}

func_stop() {
    if [ -f "/var/run/doh_proxy.pid" ]; then
        killall doh_proxy
        logger -t doh_proxy "Shutdown."
        rm /var/run/doh_proxy.pid
    else
        logger -t doh_proxy "DoH proxy is stoping."
    fi
}

case "$1" in
    start)
        func_start
    ;;
    stop)
        func_stop
    ;;
    restart)
        func_stop
        func_start
    ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
    ;;
esac

exit 0
