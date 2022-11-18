FROM debian:bullseye-slim

## Define build arguments.
ARG ROOTHOME='/root/home'
ARG NETWORK='testnet'

RUN 

## Install dependencies.
RUN apt-get update && apt-get install -y \
  libevent-dev libsodium-dev python3 python3-pip \
  curl git lsof man neovim netcat procps qrencode tmux
  ## libpq-dev glibc-source

## Install python modules.
RUN pip3 install pyln-client requests

## Copy over runtime.
COPY image /
COPY config /config/
COPY home /root/home/

## Add custom profile to bashrc.
RUN PROFILE="$ROOTHOME/.profile" \
  && printf "\n[ -f $PROFILE ] && . $PROFILE\n\n" >> /root/.bashrc

## Uncomment this if you want to wipe all repository lists.
#RUN rm -rf /var/lib/apt/lists/*

## Setup Environment.
ENV PATH="$ROOTHOME/bin:/root/.local/bin:$PATH"
ENV NETWORK="$NETWORK"

WORKDIR /root/home

ENTRYPOINT [ "entrypoint" ]
