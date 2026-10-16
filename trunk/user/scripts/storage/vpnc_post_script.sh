#!/bin/sh
### Custom user script
### Called after starting Wireguard VPN client
### $1         - action: start/stop/restart/reload/update
### $IF_NAME   - interface name
### $TABLE     - table contains default route to $IF_NAME
### $PREF_WG   - number of rules for $TABLE, marked $FWMARK
###              clears up when stopping/restarting
### $PREF_MAIN - number of rules before the $TABLE, route to main
###              clears up when stopping/restarting

post_start()
{
  return 0
}

post_stop()
{
  return 0
}

post_reload()
{
  # when update ipset, fw
  return 0
}

post_update()
{
  # when update fw
  return 0
}

post_watchdog()
{
  # when watchdog launched
  return 0
}

case "$1" in
  start)
    post_start
  ;;

  stop)
    post_stop
  ;;

  reload)
    post_reload
  ;;

  update)
    post_update
  ;;

  watchdog)
    post_watchdog
  ;;
esac
