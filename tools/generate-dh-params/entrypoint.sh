#!/usr/bin/env bash
set -euo pipefail
exec openssl dhparam -out /keys/dh.pem 4096 "$@"
