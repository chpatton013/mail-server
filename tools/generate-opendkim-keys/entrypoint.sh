#!/usr/bin/env bash
set -euo pipefail
[ -n "$MAIL_DOMAIN" ]
exec opendkim-genkey \
  --bits=2048 \
  --directory=/keys \
  --domain="mail.$MAIL_DOMAIN" \
  --hash-algorithms=sha256 \
  --restrict \
  --selector=mail \
  "$@"
