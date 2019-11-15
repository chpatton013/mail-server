#!/usr/bin/env bash
set -euo pipefail

script_dir="$(builtin cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

config_file="$(realpath "$CLAMAV_CONFIG")"
data_dir="$(realpath "$CLAMAV_DATA")"
run_dir="$(realpath "$CLAMAV_RUN")"

docker build \
  --rm \
  --tag=generate-clamav-databases \
  "$script_dir/generate-clamav-databases" >&2
docker run \
  --volume="$config_file:/etc/clamav/freshclam.conf:ro" \
  --volume="$data_dir:/var/lib/clamav:rw" \
  --volume="$run_dir:/run/clamav:rw" \
  generate-clamav-databases
