#!/bin/sh
## Startup script for docker container.

set -E

###############################################################################
# Environment
###############################################################################

NAME="cln.main.node"

###############################################################################
# Methods
###############################################################################

build_image() {
  echo "Building $NAME from dockerfile ..."
  docker build --tag $NAME .
}

stop_container() {
  ## Check if previous container exists, and remove it.
  if docker container ls -a | grep $NAME > /dev/null 2>&1; then
    echo "Stopping current container..."
    docker container stop $NAME > /dev/null 2>&1
    docker container rm $NAME > /dev/null 2>&1
  fi
}

###############################################################################
# Script
###############################################################################

## If existing image is not present, build it.
if [ -z "$(docker image ls | grep $NAME)" ] || [ "$1" = "--build" ]; then
  build_image
elif [ "$1" = "--rebuild" ]; then
  docker image rm $NAME > /dev/null 2>&1
  build_image
fi

## Make sure to stop any existing container.
stop_container

## Start docker container.
echo "Starting container for $NAME ... "

docker run -it --rm \
  --name $NAME \
  --hostname $NAME \
  --mount type=volume,source="data.$NAME",target=/data \
  --mount type=bind,source=$(pwd)/run,target=/root/run \
  --mount type=bind,source=$(pwd)/snapshot,target=/snapshot \
  --entrypoint bash \
$NAME:latest