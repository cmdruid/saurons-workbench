#!/usr/bin/env bash
## Start script for lightning daemon.

set -E

###############################################################################
# Environment
###############################################################################

BIN_NAME="lightningd"

DATA_PATH="/data/lightning"
CONF_PATH="$HOME/.lightning"
LOGS_PATH="/var/log/lightning"
CONF_FILE="$CONF_PATH/config"
LOGS_FILE="$LOGS_PATH/lightningd.log"

esplora_net=""

###############################################################################
# Methods
###############################################################################

fprint() {
  col_offset=2
  prefix="$(fgc 215 '|')"
  newline=`printf %s "$1" | cut -f ${col_offset}- -d ' '`
  printf '%s\n' "$IND $newline"
}

###############################################################################
# Script
###############################################################################

templ banner "Lightning Core Configuration"

## Configure devmode.
[ -n "$DEVMODE" ] && LINEOUT='/dev/tty' || LINEOUT='/dev/null'

## Check if binary is installed.
[ -z "$(which $BIN_NAME)" ] && echo "Binary for $BIN_NAME is missing!" && exit 1

## Create any missing paths.
if [ ! -d "$DATA_PATH" ]; then mkdir -p "$DATA_PATH"; fi
if [ ! -d "$LOGS_PATH" ]; then mkdir -p "$LOGS_PATH"; fi

## Check if process is already running.
DAEMON_PID=`lsof -c $BIN_NAME | grep "$(which $BIN_NAME)" | awk '{print $2}'`

if [ -z "$DAEMON_PID" ]; then

  ## Link the network RPC folder for compatibility.
  if [ ! -e "$CONF_PATH/$CHAIN" ]; then
    printf "Adding symlink for $CHAIN network RPC"
    ln -s $DATA_PATH/$CHAIN $CONF_PATH/$CHAIN
    templ ok
  fi

  ## Declare base config string.
  config="--daemon --conf=$CONF_FILE --network=$CHAIN"

  ## If tor is running, add tor configuration.
  if [ -n "$(pgrep tor)" ]; then
    printf "Adding tor proxy settings to lightningd"
    config="$config --proxy=127.0.0.1:9050"
    templ ok
  fi

  ## Configure Sauron if plugin is present.
  if [ -d "$CONF_PATH/plugins/sauron" ]; then
    printf "Adding sauron configuration ..."
    [ "$CHAIN" = "testnet" ] && esplora_net="/testnet"
    config="$config --disable-plugin=bcli"
    config="$config --plugin=$CONF_PATH/plugins/sauron/sauron.py"
    config="$config --sauron-api-endpoint=https://blockstream.info$esplora_net/api/"
    templ ok
  fi

  [ -n "$DEVMODE" ] && ( 
    echo && printf "Config string:"
    for string in $config; do printf "\n$IND $string"; done && templ ok
  )

  ## Start lightning and wait for it to load.
  echo && printf "Starting lightning daemon" && templ prog
  lightningd $config > $LINEOUT 2>&1; tail -f $LOGS_FILE | while read line; do
    [ -n "$DEVMODE" ] && fprint "$line"
    echo "$line" | grep "Server started with public key" > /dev/null 2>&1
    if [ $? = 0 ]; then
      printf "$IND Lightning daemon running on $CHAIN network!"
      templ ok && exit 0
    fi
  done

else 
  printf "Lightning daemon is running under PID: $(templ hlight $DAEMON_PID)" && templ ok
fi
