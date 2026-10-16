#!/bin/sh

### Custom user script
### Called after remote peer connected/disconnected to internal VPN server
### $1 - peer action (up/down)
### $2 - peer interface name (e.g. ppp10)
### $3 - peer local IP address
### $4 - peer remote IP address
### $5 - peer name

peer_if="$2"
peer_ip="$4"
peer_name="$5"

### example: add static route to private LAN subnet behind a remote peer

func_ipup()
{
#  if [ "$peer_name" == "dmitry" ] ; then
#    route add -net 192.168.5.0 netmask 255.255.255.0 dev $peer_if
#  elif [ "$peer_name" == "victoria" ] ; then
#    route add -net 192.168.8.0 netmask 255.255.255.0 dev $peer_if
#  fi
   return 0
}

func_ipdown()
{
#  if [ "$peer_name" == "dmitry" ] ; then
#    route del -net 192.168.5.0 netmask 255.255.255.0 dev $peer_if
#  elif [ "$peer_name" == "victoria" ] ; then
#    route del -net 192.168.8.0 netmask 255.255.255.0 dev $peer_if
#  fi
   return 0
}

case "$1" in
up)
  func_ipup
  ;;
down)
  func_ipdown
  ;;
esac
