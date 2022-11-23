#!/usr/bin/env bash
## This profile is loaded upon login.
## Feel free to add your own aliases and shortcuts!

## Set default variables.
[ -z "$NETWORK" ] && NETWORK="testnet"

## Run .init on login.
[ -f '/root/home/.init' ] && . /root/home/.init

## Configure lightning-cli shortcut.
alias lcli="lightning-cli --network=$NETWORK"

## Useful for checking open sockets.
alias listen='lsof -i -P -n | grep LISTEN'

## Shortcuts to logfiles.
debug() { 
  tail -f "/root/.lightning/lightningd.log"
}

## Get QR codes for exporting complex strings.
qrcode() {
  [ "$#" -ne 0 ] && input="$1" || input="$(tr -d '\0' < /dev/stdin)"
  echo && qrencode -m 2 -t "UTF8" "$input" && printf "${input}\n\n"
}

spark-qr() {
  SPARKHOST="$(cat $DATA/.sparkhost)"
  APIKEY="$(cat /root/.lightning/spark.keys | kgrep MASTER_KEY)"
  printf "$SPARKHOST?access-key=$APIKEY" | qrcode
}
