## This file can be used to customize your environment.
## Feel free to add your own aliases and shortcuts!

## Run .init on login.
[ -f '/root/home/.init' ] && . /root/home/.init

## Configure bitcoin-cli.
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

sparkoconnect() {
  [ -z "$SPARK_HOST" ] && SPARK_HOST=127.0.0.1
  [ -z "$SPARK_PORT" ] && SPARK_PORT=443
  APIKEY="$(cat /root/.lightning/sparko.keys | kgrep MASTER_KEY)"
  printf "http://$SPARK_HOST:$SPARK_PORT?access-key=$APIKEY" | qrcode
}
