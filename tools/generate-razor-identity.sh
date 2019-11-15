#!/usr/bin/env bash
set -euo pipefail

script_dir="$(builtin cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

output_dir="$1"
shift

docker build \
  --rm \
  --tag=generate-razor-identity \
  "$script_dir/generate-razor-identity" >&2
docker run \
  --volume="$output_dir:/var/lib/spamassassin/razor:rw" \
  generate-razor-identity
