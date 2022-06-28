FROM debian:bullseye-slim

ARG HOMEDIR="/root"
ARG RUNPATH="$HOMEDIR/run"
ARG LIBPATH="$RUNPATH/lib"
ARG BTCPATH="$HOMEDIR/.bitcoin"
ARG CLNPATH="$HOMEDIR/.lightning"

## Install dependencies.
RUN apt-get update && apt-get install -y \
  curl git iproute2 libevent-dev libsodium-dev lsof man netcat \
  openssl procps python3 python3-pip qrencode socat xxd neovim

## Install python modules.
RUN pip3 install pyln-client requests[socks]

## Install Node.
RUN curl -fsSL https://deb.nodesource.com/setup_17.x | bash - && apt-get install -y nodejs

## Install node packages.
RUN npm install -g npm yarn clightningjs

## Copy over binaries.
COPY build/out/* /tmp/bin/

WORKDIR /tmp

## Unpack and/or install binaries.
RUN for file in /tmp/bin/*; do \
  if ! [ -z "$(echo $file | grep .tar.)" ]; then \
    echo "Unpacking $file to /usr ..." \
    && tar --wildcards --strip-components=1 -C /usr -xf $file \
  ; else \
    echo "Moving $file to /usr/local/bin ..." \
    && chmod +x $file && mv $file /usr/local/bin/ \
  ; fi \
; done

## Clean up temporary files.
RUN rm -rf /tmp/* /var/tmp/*

## Uncomment this if you also want to wipe all repository lists.
#RUN rm -rf /var/lib/apt/lists/*

## Install RTL REST API.
RUN PLUGPATH="$CLNPATH/plugins" && mkdir -p $PLUGPATH && cd $PLUGPATH \
  && git clone https://github.com/Ride-The-Lightning/c-lightning-REST.git cl-rest \
  && cd cl-rest && npm install

## Configure user account for Tor.
# RUN addgroup tor \
#   && adduser --system --no-create-home tor \
#   && adduser tor tor \
#   && chown -R tor:tor /var/lib/tor /var/log/tor

## Copy configuration and run environment.
COPY config /
COPY run $RUNPATH/

## Make sure plugins are executable.
RUN chmod +x /root/.lightning/plugins/*

## Create required directories.
RUN mkdir -p /var/log/lightning

## Add bash aliases to .bashrc.
RUN alias_file="~/.bash_aliases" \
  && printf "if [ -e $alias_file ]; then . $alias_file; fi\n\n" >> $HOMEDIR/.bashrc

## Make sure scripts are executable.
RUN for file in `grep -lr '#!/usr/bin/env' $RUNPATH`; do chmod +x $file; done

## Symlink entrypoint and login to PATH.
RUN ln -s $RUNPATH/entrypoint.sh /usr/local/bin/node-start

## Configure run environment.
ENV PATH="$LIBPATH/bin:$HOMEDIR/.local/bin:$PATH"
ENV PYPATH="$LIBPATH/pylib:$PYPATH"
ENV NODE_PATH="$LIBPATH/nodelib:$NODE_PATH"
ENV RUNPATH="$RUNPATH"
ENV LIBPATH="$LIBPATH"
ENV LOGPATH="/var/log"

## Configure core environment.
ARG BTCPATH="$HOMEDIR/.bitcoin"
ENV LNPATH="$HOMEDIR/.lightning"
ENV PLUGPATH="$RUNPATH/plugins/"

WORKDIR $HOMEDIR

ENTRYPOINT [ "node-start" ]
