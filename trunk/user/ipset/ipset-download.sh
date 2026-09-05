#!/bin/sh

log()
{
    [ -n "$*" ] || return
    echo "$@" >&2
    logger -t "ipset" "$@"
}

error()
{
    log "error: $@"
    exit 1
}

angry_wget() {
    local r=1

    while [ $r -lt 11 ]; do
        wget -T10 --no-check-certificate "$1" -O "$2" && return 0 || sleep $r
        r=$((r + 1))
    done

    return 1
}

download() {
    local tmp_file=/tmp/ipset-import.txt
    local name="$1"
    local url="$2"

    [ -n "$name" ] || error "specify ipset name"
    [ -n "$url" ] || error "specify URL"

    if angry_wget "$url" $tmp_file; then
        log "successfully downloaded $url"
        ipset-import.sh "$name" $tmp_file
    else
        log "error downloading $url"
    fi

    rm -f $tmp_file
}

case "$1" in
    "")
        echo "Usage: $0 <ipset_name> <url_list_ipv4_cidr>"
        exit 1
    ;;

    *)
        download "$1" "$2"
    ;;
esac
