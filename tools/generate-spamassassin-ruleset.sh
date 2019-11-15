#!/usr/bin/env bash
set -euo pipefail

script_dir="$(builtin cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

data_dir="$(realpath "$SPAM_DATA")"
run_dir="$(realpath "$SPAM_RUN")"

docker build \
  --rm \
  --tag=generate-spamassassin-ruleset \
  "$script_dir/generate-spamassassin-ruleset" >&2
docker run \
  --volume="$data_dir:/var/lib/spamassassin:rw" \
  --volume="$run_dir:/run/spamd:rw" \
  generate-spamassassin-ruleset
