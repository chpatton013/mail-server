#!/usr/bin/env bash
set -euo pipefail

script_dir="$(builtin cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

docker build --rm --tag=generate-dovecot-passwd "$script_dir/generate-dovecot-passwd" >&2
docker run --interactive --tty generate-dovecot-passwd "$@"
