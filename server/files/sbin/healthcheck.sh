#!/usr/bin/env bash
set -euo pipefail

if postfix status; then
  exit 0
else
  exit 1
fi
