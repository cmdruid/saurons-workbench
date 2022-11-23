#!/usr/bin/env sh
## Entrypoint Script

set -E

###############################################################################
# Environment
###############################################################################

CMD="lightningd"
CONF="/config/lightningd.conf"

export PARAM_FILE="$DATA/.params"
export SPARK_HOST="$DATA/.sparkhost"
export CLND_LOGS="$DATA/lightningd.log"

[ -z "$NETWORK" ]    && export NETWORK="testnet"
[ -z "$SPARK_PORT" ] && export SPARK_PORT="9737"

###############################################################################
# Methods
###############################################################################

init() {
  ## Execute startup scripts.
  for script in `find /root/home/start -name *.*.sh | sort`; do
    $script; state="$?"
    [ $state -ne 0 ] && exit $state
  done
}

###############################################################################
# Main
###############################################################################

## Ensure all files are executable.
for FILE in $PWD/bin/*   ; do chmod a+x $FILE; done
for FILE in $PWD/start/* ; do chmod a+x $FILE; done

## Check if binary exists.
[ -z "$(which $CMD)" ] && (echo "$CMD file is missing!" && exit 1)

## Make sure log and param files is empty.
printf "" > $CLND_LOGS
printf "" > $PARAM_FILE

## Run init scripts.
init

## If hostname is not set, use container address as default.
[ ! -f "$SPARK_HOST" ] && printf "https://$(hostname -I):$SPARK_PORT" > "$SPARK_HOST"

## Construct final params string.
PARAMS="--conf=$CONF --network=$NETWORK $(cat $PARAM_FILE) $@"

## Print our params string.
echo "Executing $CMD with params:"
for line in $PARAMS; do echo $line; done && echo

## Start lightningd.
$CMD $PARAMS
