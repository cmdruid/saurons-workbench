#!/usr/bin/env bash
## Start script for lightning daemon.

set -E

###############################################################################
# Environment
###############################################################################

BIN_NAME="lightningd"

DATA_PATH="$DATAPATH/lightning"
CONF_PATH="$LNPATH"
LOGS_PATH="$LOGPATH/lightning"

CONF_FILE="$CONF_PATH/config"
LOGS_FILE="$LOGS_PATH/lightningd.log"
KEYS_FILE="$DATA_PATH/sparko.keys"
CRED_FILE="$DATA_PATH/sparko.login"
FUND_FILE="$DATA_PATH/fund.address"

esplora_net=""

###############################################################################
# Methods
###############################################################################

gen_keystr() {
  [ -n "$1" ] && (
    for key in `cat $1`; do
      val=`printf "$key" | awk -F '=' '{ print $2 }'`
      keystr="$keystr$val;"
    done
    printf %s "--sparko-keys=$keystr"
  )
}

gen_logstr() {
  [ -n "$1" ] && (
    SPARK_USER=`cat $1 | kgrep USERNAME`
    SPARK_PASS=`cat $1 | kgrep PASSWORD`
    printf %s "--sparko-login=$SPARK_USER:$SPARK_PASS"
  )
}

fprint() {
  col_offset=2
  prefix="$(fgc 215 '|')"
  newline=`printf %s "$1" | cut -f ${col_offset}- -d ' '`
  printf '%s\n' "$IND $newline"
}

lcli() {
  [ -n "$1" ] && lightning-cli --network=$CHAIN $@
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
    printf "Adding sauron configuration"
    [ "$CHAIN" = "testnet" ] && esplora_net="/testnet"
    config="$config --disable-plugin=bcli"
    config="$config --plugin=$CONF_PATH/plugins/sauron/sauron.py"
    config="$config --sauron-api-endpoint=https://blockstream.info$esplora_net/api/"
    templ ok
  fi

  ## Configure sparko keys.
  echo && printf "Adding sparko key configuration to lightningd:"
  if ! ( [ -e "$KEYS_FILE" ] && [ -e "$CRED_FILE" ] ); then
    printf "\n$IND Generating keys for sparko plugin"
    $LIBPATH/start/sparko-genkeys.sh
  fi
  config="$config $(gen_keystr $KEYS_FILE) $(gen_logstr $CRED_FILE)"
  templ ok

  [ -n "$DEVMODE" ] && ( 
    echo && printf "Config string:"
    for string in $config; do printf "\n$IND $string"; done && templ ok
  )

  ## Start lightning and wait for it to load.
  echo && printf "Starting lightning daemon" && templ prog
  lightningd $config > $LINEOUT 2>&1
  [ ! -e $LOGS_FILE ] && printf "lightningd failed to start!" && exit 1
  tail -f $LOGS_FILE | while read line; do
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

## Start CL-REST server.
$LIBPATH/start/cl-rest-start.sh

## Start RTL server.
$LIBPATH/start/rtl-start.sh

###############################################################################
# Payment Configuration
###############################################################################

## Generate a funding address.
if [ ! -e "$FUND_FILE" ] || [ -z "$(cat $FUND_FILE)" ]; then
  printf "Generating new payment address for lightning"
  lcli newaddr | jgrep bech32 > $FUND_FILE
  templ ok
fi

###############################################################################
# Plugins
###############################################################################

## Enable plugins
if [ -d "$PLUGPATH" ]; then
  plugins=`find $PLUGPATH -maxdepth 1 -type d`
  if [ -n "$plugins" ]; then
    echo && printf "Plugins:\n"
    for plugin in $plugins; do
      name=$(basename $plugin)
      if case $name in .*) ;; *) false;; esac; then continue; fi
      plugin_name=`find $plugin -maxdepth 1 -name $name.*`
      if [ -e "$plugin_name" ]; then
        printf "$IND Enabling $name plugin"
        chmod +x $plugin_name
        lcli plugin start $plugin_name > /dev/null 2>&1
        templ ok
      fi
    done
  fi
fi
