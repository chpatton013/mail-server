#!/usr/bin/env bash
set -euo pipefail
exec doveadm pw -s SSHA512 "$@"
