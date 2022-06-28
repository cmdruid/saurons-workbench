#!/usr/bin/env bash
## Startup script for init.

set -E

###############################################################################
# Environment
###############################################################################

###############################################################################
# Script
###############################################################################

templ banner "Init Configuration"

## If tor enabled, call tor startup script.
if [ -n "$TOR_NODE" ]; then sh -c $LIBPATH/start/onion-start.sh; fi
