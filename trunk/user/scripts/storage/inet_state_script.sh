#!/bin/sh

### Custom user script
### Called on Internet status changed
### $1 - Internet status (0/1)
### $2 - elapsed time (s) from previous state

logger -t "di" "Internet state: $1, elapsed time: $2s."
