#!/usr/bin/env bash
set -euo pipefail

script_dir="$(builtin cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

output_dir="$1"

docker build --rm --tag=generate-opendkim-keys "$script_dir/generate-opendkim-keys" >&2
docker run --env=MAIL_DOMAIN --volume="$output_dir:/keys:rw" generate-opendkim-keys
