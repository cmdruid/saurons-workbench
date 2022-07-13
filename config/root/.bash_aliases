# bash_aliases
## This file is loaded upon login to your node terminal, 
## and can be used to customize your environment. Feel free to 
## modify this file, like adding your own aliases and shortcuts!

## Short-hand for bitcoin / lightning CLI.
alias lcli="lightning-cli --network=$CHAIN"

## Useful for checking open sockets.
alias opensockets='lsof -nP -iTCP -sTCP:LISTEN'
alias listsockets='ss -tunlp'

## Shortcuts to logfiles.
alias ldlog='tail -f /var/log/lightning/lightningd.log'
alias torlog='tail -f /var/log/tor/notice.log'

## QR Code shortcut.
alias qrcode='qrencode -m 2 -t "ANSIUTF8"'

## Get QR codes for onion strings.
alias qrclnonion='cat /data/tor/services/cln/hostname | qrencode -m 2 -t "ANSIUTF8"'

## Get QR code for lightning funding address.
qrclnfunds='cat /data/lightning/fund.address | qrencode -m 2 -t "ANSIUTF8"'

## Generates a sparko QR code for connecting to zeus via Tor.
## Must have tor enabled so that a hostname is generated!
alias qrsparko='\
  HOST="$(cat /data/tor/services/cln/hostname)" \
  && CRED="$(cat /data/lightning/sparko.keys | kgrep MASTER_KEY)" \
  && printf "http://$HOST:9737?access-key=$CRED" | qrencode -m 2 -t "ANSIUTF8"'