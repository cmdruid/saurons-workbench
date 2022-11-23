#!/usr/bin/env sh
## Sparko init script.

set -E

###############################################################################
# Methods
###############################################################################

get_keystring() {
  KEYS_FILE="$DATA/spark.keys"
  for key in "$(cat $KEYS_FILE)"; do
    val="$(printf "$key" | awk -F '=' '{ print $2 }')"
    keystr="${keystr}${val}"
  done
  printf %s "$keystr" | tr '\n' '\;'
}

get_logstring() {
  LOGIN_FILE="$DATA/spark.login"
  SPARK_USER=`cat $LOGIN_FILE | kgrep USERNAME`
  SPARK_PASS=`cat $LOGIN_FILE | kgrep PASSWORD`
  printf %s "$SPARK_USER:$SPARK_PASS"
}

###############################################################################
# Main
###############################################################################

PARAMS="$(cat $PARAM_FILE)"

echo "Initializing Spark Plugin"

## Check if tls credentials exists.
CERTPATH="$DATA/$NETWORK/certs"
if [ ! -f "$CERTPATH/cert.pem" ]; then
  echo "Generating new set of tls certs ..." 
  mkdir -p "$CERTPATH" && gencerts "$CERTPATH"
fi

## Check if sparko credentials exist.
if [ ! -f "$DATA/spark.keys" ] || [ ! -f "$DATA/spark.login" ]; then
 echo "Generating new set of spark keys ..." && genkeys
fi

## If tor is not enabled, update params to use TLS.
[ -z "$TOR_ENABLED" ] && PARAMS="$PARAMS --sparko-tls-path=certs"

## Add sparko credentials to params string.
PARAMS="$PARAMS --sparko-port=$SPARK_PORT --sparko-login=$(get_logstring) --sparko-keys=$(get_keystring)"

## Save updated params to file.
printf "$PARAMS" > "$PARAM_FILE"
