#!/bin/sh

### Custom user script
### Called after internal VPN client connected/disconnected to remote VPN server
### $1        - action (up/down)
### $IFNAME   - tunnel interface name (e.g. ppp5 or tun0)
### $IPLOCAL  - tunnel local IP address
### $IPREMOTE - tunnel remote IP address
### $DNS1     - peer DNS1
### $DNS2     - peer DNS2

# private LAN subnet behind a remote server (example)
peer_lan="192.168.9.0"
peer_msk="255.255.255.0"

### example: add static route to private LAN subnet behind a remote server

func_ipup()
{
#  route add -net $peer_lan netmask $peer_msk gw $IPREMOTE dev $IFNAME
   return 0
}

func_ipdown()
{
#  route del -net $peer_lan netmask $peer_msk gw $IPREMOTE dev $IFNAME
   return 0
}

logger -t vpnc-script "$IFNAME $1"

case "$1" in
up)
  func_ipup
  ;;
down)
  func_ipdown
  ;;
esac
