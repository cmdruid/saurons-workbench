FROM debian:bullseye-slim

## Define build arguments.
ARG ROOTHOME='/root/home'
ARG DATAPATH="/root/.lightning"

## Install dependencies.
RUN apt-get update && apt-get install -y \
  libevent-dev libsodium-dev iproute2 python3 python3-pip \
  curl git jq lsof man neovim netcat procps qrencode tmux

## Install python modules.
RUN pip3 install pyln-client requests

## Install Node plus packages.
RUN curl -fsSL https://deb.nodesource.com/setup_19.x | bash - && apt-get install -y nodejs
RUN npm install -g npm yarn clightningjs

## Install ngrok.
RUN curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null 
RUN echo "deb https://ngrok-agent.s3.amazonaws.com bullseye main" | tee /etc/apt/sources.list.d/ngrok.list 
RUN apt update && apt install ngrok

## Uncomment this if you want to install additional packages.
#RUN apt-get install -y <packages>

## Uncomment this if you want to wipe all repository lists.
#RUN rm -rf /var/lib/apt/lists/*

## Copy over runtime.
COPY image /
COPY config /config/
COPY home /root/home/

## Link entrypoint script to bin.
RUN ln -s $ROOTHOME/entrypoint.sh /usr/local/bin/entrypoint

## Add custom profile to bashrc.
RUN PROFILE="$ROOTHOME/.profile" \
  && printf "\n[ -f $PROFILE ] && . $PROFILE\n\n" >> /root/.bashrc

## Setup Environment.
ENV PATH="$ROOTHOME/bin:/root/.local/bin:$PATH"
ENV DATA="$DATAPATH"

WORKDIR /root/home

ENTRYPOINT [ "entrypoint" ]
