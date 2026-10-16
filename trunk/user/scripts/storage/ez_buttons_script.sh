#!/bin/sh

### Custom user script
### Called on WPS or FN button pressed
### $1 - button param

[ -x /opt/bin/on_wps.sh ] && /opt/bin/on_wps.sh $1 &
