#!/usr/bin/env bash
## Start script for RTL's CL-REST interface.

set -E

###############################################################################
# Environment
###############################################################################

SRC_PATH="$HOME/app/cl-rest"
CERT_PATH="$DATAPATH/certs"
CERT_LINK="$SRC_PATH/certs"
LOG_FILE="$LOGPATH/lightning/cl-rest.log"
CONF_FILE="$SRC_PATH/cl-rest-config.json"

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

DAEMON_PID=`pgrep -f "node cl-rest.js"`

if [ -z "$DAEMON_PID" ]; then

  echo && printf "Starting CL-REST server:\n"

  ## Create log directory if it does not exist.
  
  
  ## Create certificate directory if does not exist.
  if [ ! -d "$CERT_PATH" ]; then 
    printf "$IND Adding data directory for rest certificates.\n"
    mkdir -p $CERT_PATH
  fi

  ## Symlink the certificates for the REST API to persistent storage.
  if [ ! -e "$CERT_LINK" ]; then
    printf "$IND Adding symlink for access macaroon.\n"
    ln -s $CERT_PATH $CERT_LINK
  fi

  ## Set the chain path in the config.
  sed -i "s/%CHAIN%/$CHAIN/g" $CONF_FILE

  ## Start the CL-REST server.
  printf "$IND Starting CL-REST server.\n"
  cd $SRC_PATH && node cl-rest.js > $LOG_FILE 2>&1 &

  # Wait for lightningd to load, then start other services.
  tail -f $LOG_FILE | while read line; do
    [ -n "$DEVMODE" ] && printf "$IND $line\n"
    echo "$line" | grep "cl-rest api server is ready" > /dev/null 2>&1
    if [ $? = 0 ]; then
      [ -n "$(pgrep -f 'node cl-rest.js')" ] \
        && ( printf "$IND CL-REST server is now running!" && templ ok ) \
        || ( printf "Failed to start!" && templ skip )
      exit
    fi
  done

else 
  echo && printf "CL-REST process is running under PID: $(templ hlight $DAEMON_PID)"
  templ ok
fi
