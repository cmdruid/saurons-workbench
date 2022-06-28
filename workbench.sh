#!/bin/sh
## Startup script for docker container.

set -E

###############################################################################
# Environment
###############################################################################

DEFAULT_CHAIN="testnet"

DENVPATH=".env"         ## Path to your local .env file.
WORKPATH="$(pwd)"       ## Absolute path to use for this directory.
LINE_OUT="/dev/null"    ## Default output for noisy commands.
HEADMODE="-i"           ## Container connects to terminal by default.
ESC_KEYS="ctrl-z"       ## Escape sequence for detaching from terminals.

DATAPATH="data"         ## Default path for a node's interal storage.

###############################################################################
# Methods
###############################################################################

network_exists() {
  docker network ls | grep $NET_NAME > $LINE_OUT 2>&1
}

image_exists() {
  [ -n "$1" ] && docker image ls | grep $1 > $LINE_OUT 2>&1
}

container_exists() {
  docker container ls -a | grep $SRV_NAME > $LINE_OUT 2>&1
}

volume_exists() {
  docker volume ls | grep $DAT_NAME > $LINE_OUT 2>&1ain
}

get_container_id() {
  [ -z "$1" ] && echo "You provided an empty search tag!" && exit 1
  docker container ls | grep $1 | awk '{ print $1 }' | head -n 2 | tail -n 1
}

create_network() {
  printf "Creating network $NET_NAME ... "
  if [ -n "$VERBOSE" ]; then printf "\n"; fi
  docker network create $NET_NAME > $LINE_OUT 2>&1;
  if ! network_exists; then printf "failed!\n" && exit 1; fi
  printf "done.\n"
}

remove_image() {
  [ -n "$IMG_NAME" ] \
    || ( [ -n "$1" ] && IMG_NAME="$1" ) \
    || IMG_NAME="$DEFAULT_NAME-img"

  printf "Removing existing image ... "

  if [ -n "$VERBOSE" ]; then printf "\n"; fi

  if ! image_exists; then 
    printf "Image '$IMG_NAME' does not exist!" && exit 0
  fi

  docker image rm $IMG_NAME > $LINE_OUT 2>&1

  if image_exists $IMG_NAME; then 
    printf "failed!\n" && exit 1
  fi

  printf "done.\n"
}

build_image() {
  [ -n "$1" ] && IMG_NAME="$1"
  [ -n "$IMG_NAME" ] || IMG_NAME="$DEFAULT_CHAIN-img"
  printf "Building image for $IMG_NAME from dockerfile ... "
  if [ -n "$VERBOSE" ]; then printf "\n"; fi
  DOCKER_BUILDKIT=1 docker build --tag $IMG_NAME . > $LINE_OUT 2>&1
  if ! image_exists $IMG_NAME; then printf "failed!\n" && exit 1; fi
  printf "done.\n"
}

stop_container() {
  if container_exists; then
    printf "Purging existing container ... "
    if [ -n "$VERBOSE" ]; then printf "\n"; fi
    docker container stop $SRV_NAME > $LINE_OUT 2>&1
    docker container rm $SRV_NAME > $LINE_OUT 2>&1
    printf "done.\n"
  fi
}

login_container() {
  cid=`get_container_id $1`
  [ -z "$cid" ] && echo "That node does not exist!" && exit 3
  docker exec -it --detach-keys $ESC_KEYS $cid terminal
}

wipe_data() {
  printf "Purging existing data volume ... "
  if [ -n "$VERBOSE" ]; then printf "\n"; fi
  docker volume rm $DAT_NAME > $LINE_OUT 2>&1
  if volume_exists; then printf "failed!\n" && exit 1; fi
  printf "done.\n"
}

add_mount() {
  ## If mount points are specified, build a mount string.
  if chk_arg $1; then
    src=`printf $1 | awk -F ':' '{ print $1 }'`
    dest=`printf $1 | awk -F ':' '{ print $2 }'`
    if [ -z "$(echo $1 | grep -E '^/')" ]; then prefix="$WORKPATH/"; fi
    MOUNTS="$MOUNTS --mount type=bind,source=$prefix$src,target=$dest"
  fi
}

add_ports() {
  ## If ports are specified, build a port string.
  if chk_arg $1; then for port in `echo $1 | tr ',' ' '`; do
    src=`printf $1 | awk -F ':' '{ print $1 }'`
    dest=`printf $1 | awk -F ':' '{ print $2 }'`
    if [ -z "$dest" ]; then dest="$src"; fi
    PORTS="$PORTS -p $src:$dest"
  done; fi
}

cleanup() {
  ## Exit codes are complicated.
  status="$?"
  [ -n "$HEADLESS" ] || [ "$status" -eq 10 ] && exit
  ( [ $status -eq 11 ] || [ $status -eq 1 ] ) && echo "You are now logged out. Node running in the background." && exit
  stop_container && echo "Exiting workbench with status: $status" && exit
}

###############################################################################
# Main
###############################################################################

main() {
  [ -n "$VERBOSE" ] && echo \
  "Configuration string: $HEADMODE $RUN_FLAGS $MOUNTS $PORTS $ENV_STR $ARGS_STR $PASSTHRU\n"

  ## Start container script.
  docker run -t \
    --name $SRV_NAME \
    --hostname $SRV_NAME \
    --network $NET_NAME \
    --mount type=volume,source=$DAT_NAME,target=/$DATAPATH \
    -e DATAPATH="/$DATAPATH" -e ESC_KEYS="$ESC_KEYS" -e CHAIN="$CHAIN" \
  $HEADMODE $RUN_FLAGS $MOUNTS $PORTS $ENV_STR $ARGS_STR $PASSTHRU $IMG_NAME:latest
}

###############################################################################
# Script
###############################################################################

set -E && trap cleanup EXIT

## Parse arguments.
for arg in "$@"; do
  case $arg in
    build)             build_image $2;                   exit 10;;
    rebuild)           remove_image $2; build_image $2;  exit 10;;
    login)             login_container $2;               exit 11;;
    start)             TAG=$2                            shift 2;;
    -b|--build)        BUILD=1;                          shift  ;;
    -r|--rebuild)      REBUILD=1;                        shift  ;;
    -v|--verbose)      VERBOSE=1; LINE_OUT="/dev/tty";   shift  ;;
    -w|--wipe)         WIPE=1;                           shift  ;;
    -d|--devmode)      DEVMODE=1;                        shift  ;;
    -v|--verbose)      VERBOSE=1; LINE_OUT="/dev/tty";   shift  ;;
    -T|--passthru)     PASSTHRU=$2;                      shift 2;;                      
    -n|--chain)        CHAIN=$2;                         shift 2;;
    -i|--image)        IMG_NAME=$2;                      shift 2;;
    -M|--mount)        add_mount $2;                     shift 2;;
    -P|--ports)        add_ports $2;                     shift 2;;
    --no-kill)         NOKILL=1;                         shift  ;;
  esac
done

## If no name argument provied, display help and exit.
[ -z "$TAG" ] && usage && exit

## Set default variables and flags.
[ -z "$CHAIN" ]    && CHAIN="$DEFAULT_CHAIN"
[ -z "$IMG_NAME" ] && IMG_NAME="$CHAIN-img"

## Define naming scheme.
NET_NAME="$CHAIN-network"
SRV_NAME="$TAG.$CHAIN.node"
DAT_NAME="$TAG.$CHAIN.data"

## If there's an existing container, remove it.
if container_exists && [ -n "$NOKILL" ]; then
  echo "Container already running for $SRV_NAME, aborting!" && exit 0
else stop_container; fi

## If rebuild is declared, remove existing image.
if image_exists $IMG_NAME && [ -n "$REBUILD" ]; then remove_image; fi

## If no existing image is present, build it.
if ! image_exists $IMG_NAME || [ -n "$BUILD" ]; then build_image; fi

## If no existing network exists, create it.
if ! network_exists; then create_network; fi

## Purge data volume if flagged for removal.
[ -n "$WIPE" ] && volume_exists && wipe_data

## Set flags and run mode of container.
if [ -n "$DEVMODE" ] && [ -z "$HEADLESS" ]; then
  DEV_MOUNT="type=bind,source=$WORKPATH/run,target=/root/run"
  RUN_MODE="development"
  RUN_FLAGS="--rm --entrypoint bash --mount $DEV_MOUNT -e DEVMODE=1"
else
  RUN_MODE="safe"
  RUN_FLAGS="--init --detach --restart on-failure:2"
fi

## Call main container script based on run mode.
echo "Starting container for $SRV_NAME in $RUN_MODE mode ..."
if [ -n "$HEADLESS" ]; then
  main & exit 11
elif [ -n "$DEVMODE" ]; then
  echo "Enter the command 'node-start' to begin the node startup script:" && main
else
  cid=`main` && docker attach --detach-keys $ESC_KEYS $cid && exit 11
fi
