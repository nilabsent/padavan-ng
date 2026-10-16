#!/bin/sh
#
# ipset update service
#
# Usage:
#   ipset.sh start
#   ipset.sh stop
#   ipset.sh restart
#   ipset.sh import <ipset_name> <url|local_file>
#   ipset.sh import <json_file>
#

BIN="/sbin/ipset"
PID="/var/run/ipset.pid"
CONF="/etc/storage/ipset/ipset.json"
SCRIPT="/etc/storage/ipset/ipset_post_script.sh"

log()
{
    [ -n "$*" ] || return
    echo "$@" >&2
    logger -t "${BIN##*/}" "$@"
}

error()
{
    log "$@"
    exit 1
}

angry_wget() {
    local out r=0

    while [ $r -lt 10 ] && [ -z "$BREAK" ]; do
        out=$(wget -T5 --no-check-certificate "$1" -O "$2" 2>&1)
        [ $? -eq 0 ] && return 0

        case "$out" in
            *"bad address"*|*"404 Not Found"*|*"403 Forbidden"*)
                return 1
            ;;
        esac

        r=$((r + 2))
        sleep $r
    done

    return 1
}

filter_ipv4()
{
    grep -E -x '^[[:space:]]*((25[0-5]|2[0-4][0-9]|1[0-9]{2}|0?[0-9]{1,2})\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|0?[0-9]{1,2})(/(3[0-2]|[12]?[0-9]))?[[:space:]]*$' \
        | sed -E 's#/32|/0##g' | sort | uniq
}

restore()
{
    local name="$1"
    local list="$2"

    [ -n "$name" ] || return 1
    [ -f "$list" ] || { log "file not found: $list"; return 1; }

    $BIN -! create $name nethash
    $BIN flush $name

    filter_ipv4 < "$list" \
        | sed -E 's#^(.*)$#add '"$name"' \1#' \
        | $BIN -! restore

    if [ $? -eq 0 ]; then
        local num=", $($BIN list $name | grep -i 'Number of entries' | tr '[:upper:]' '[:lower:]')"
        log "'$name' updated$num"
    else
        log "'$name' failed to update"
    fi
}

download()
{
    local tmp_file=/tmp/ipset-import.tmp
    local name="$1"
    local url="$2"

    [ -n "$name" ] || return 1
    [ -n "$url" ] || return 1

    if angry_wget "$url" "$tmp_file"; then
        restore "$name" "$tmp_file"
    else
        log "error downloading $url"
    fi

    rm -f "$tmp_file"
}

parse_json()
{
    awk '
        BEGIN { RS="}" }
        {
            name = ""; url = "";

            if (match($0, /"name"[[:space:]]*:[[:space:]]*"[^"]*"/)) {
                str = substr($0, RSTART, RLENGTH);
                sub(/^"name"[[:space:]]*:[[:space:]]*"/, "", str);
                sub(/"$/, "", str);
                name = str;
            }

            if (match($0, /"url"[[:space:]]*:[[:space:]]*"[^"]*"/)) {
                str = substr($0, RSTART, RLENGTH);
                sub(/^"url"[[:space:]]*:[[:space:]]*"/, "", str);
                sub(/"$/, "", str);
                url = str;
            }

            if (name != "" && url != "") {
                print name, url;
            }
    }' "$1"
}

import_json()
{
    local name url

    parse_json "$1" | while read -r name url; do
        case "$url" in
            *://*)
                download "$name" "$url"
            ;;

            *)
                restore "$name" "$url"
            ;;
        esac
    done
}

do_import()
{
    local arg1="$1"
    local arg2="$2"

    case "$arg1" in
        *.json)
            [ -f "$arg1" ] || error "json file $arg1 not found"
            import_json "$arg1"
        ;;

        *)
            [ -n "$arg2" ] || do_usage
            case "$arg2" in
                *://*)
                    download "$arg1" "$arg2"
                ;;

                *)
                    restore "$arg1" "$arg2"
                ;;
            esac
        ;;
    esac
}

do_usage()
{
    echo "Usage: $0 {start|stop|restart|import <name> <url|file>|import <json_file>}"
    exit 1
}

start_service()
{
    [ -s "$PID" ] && error "already started"

    unset BREAK
    echo $$ > "$PID"

    log "started, $($BIN -V | cut -d' ' -f2) using $CONF"

    # wait internet
    while [ -z "$BREAK" ]; do
        for i in 0 1 2 3 4 5; do
            ping -c1 -w2 -W2 $(nvram get di_addr$i) >/dev/null 2>&1
            [ $? -eq 0 ] && break
            [ -n "$BREAK" ] && exit 1

            sleep 5
            false
        done
        [ $? -eq 0 ] && break
    done

    sync && sysctl -q vm.drop_caches=3

    if [ -f "$CONF" ]; then
        [ -f "$PID" ] && import_json "$CONF"
    else
        log "warning: $CONF not found"
    fi

    [ -f "$PID" ] && [ -s "$SCRIPT" ] && [ -x "$SCRIPT" ] \
            && log "running script $SCRIPT" \
            && "$SCRIPT"

    [ -f "$PID" ] && rm -f "$PID" && log "stopped"
}

stop_service()
{
    BREAK=1

    [ -s "$PID" ] || return 1

    local pid
    for pid in \
        $(pgrep ${0##*/}) \
        $(pgrep ${SCRIPT##*/}) \
        $(pgrep -f "ipset restore") \
        $(pgrep -f "wget.*ipset-import")
    do
        if [[ $pid -ne $$ ]]; then
            kill -9 $pid >/dev/null 2>&1
        fi
    done

    [ -f "$PID" ] && rm -f "$PID" && log "stopped"
}

trap stop_service INT

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

    import)
        shift
        do_import "$@"
    ;;

    *)
        do_usage
    ;;
esac
