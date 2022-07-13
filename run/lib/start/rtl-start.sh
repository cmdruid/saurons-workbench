#!/usr/bin/env bash
## Start script for RTL's CL-REST interface.

set -E

###############################################################################
# Environment
###############################################################################

SRC_PATH="$HOME/app/rtl"
LOG_FILE="$LOGPATH/lightning/rtl.log"

###############################################################################
# Methods
###############################################################################

finish() {
  if [ "$?" -ne 0 ]; then templ skip && exit 0; fi
}

###############################################################################
# Script
###############################################################################

trap finish EXIT

DAEMON_PID=`pgrep -f "node rtl.js"`

if [ -z "$DAEMON_PID" ]; then

  echo && printf "Starting RTL server:\n"

  ## Start the RTL server.
  printf "$IND Starting RTL server.\n"
  cd $SRC_PATH && node rtl.js > $LOG_FILE 2>&1 &

  # Wait for lightningd to load, then start other services.
  tail -f $LOG_FILE | while read line; do
    [ -n "$DEVMODE" ] && printf "$IND $line\n"
    echo "$line" | grep "Server is up and running" > /dev/null 2>&1
    if [ $? = 0 ]; then
      [ -n "$(pgrep -f 'node rtl.js')" ] \
        && printf "$IND RTL server is now running!" \
        && templ ok && exit 0 \
        || printf "Failed to start!" && templ skip && exit 0
    fi
  done

else 
  echo && printf "RTL process is running under PID: $(templ hlight $DAEMON_PID)"
  templ ok
fi
