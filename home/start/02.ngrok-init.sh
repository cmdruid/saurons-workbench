#!/usr/bin/env sh
## Ngrok init script.

set -E

###############################################################################
# Main
###############################################################################

if [ -n "$NGROK_ENABLED" ] && [ -n "$NGROK_TOKEN" ]; then

  echo "Initializing Ngrok"

  ngrok config add-authtoken "$NGROK_TOKEN"
  tmux new -d -s ngrok "ngrok http https://127.0.0.1:$SPARK_PORT" && sleep 2
  curl -s localhost:4040/api/tunnels | jq -r .tunnels[0].public_url > "$SPARK_HOST"
fi
