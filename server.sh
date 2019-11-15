#!/usr/bin/env bash
set -euo pipefail

script_dir="$(builtin cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[ -n "$MAIL_USER" ]
[ -n "$MAIL_DOMAIN" ]
[ -n "$MAIL_SSL_CRT" ]
[ -n "$MAIL_SSL_KEY" ]
[ -n "$MAIL_CONFIG_DIR" ]
[ -n "$MAIL_DATA_DIR" ]
[ -n "$MAIL_RUN_DIR" ]

ssl_crt="$(realpath "$MAIL_SSL_CRT")"
ssl_key="$(realpath "$MAIL_SSL_KEY")"
config_dir="$(realpath "$MAIL_CONFIG_DIR")"
data_dir="$(realpath "$MAIL_DATA_DIR")"
run_dir="$(realpath "$MAIL_RUN_DIR")"

docker_run_args=
if [ -e /dev/log ]; then
  docker_run_args="--volume=$(realpath /dev/log):/dev/log"
fi

docker build --rm --tag=mail-server "$script_dir/server" >/dev/null
docker run \
  $docker_run_args \
  --env=MAIL_USER \
  --env=MAIL_DOMAIN \
  --publish=25:25 \
  --publish=110:110 \
  --publish=143:143 \
  --publish=465:465 \
  --publish=587:587 \
  --publish=993:993 \
  --publish=995:995 \
  --publish=2525:2525 \
  --volume="$ssl_crt:/etc/ssl/private/mail.crt:ro" \
  --volume="$ssl_key:/etc/ssl/private/mail.key:ro" \
  --volume="$config_dir/dovecot/dh.pem:/etc/dovecot/dh.pem:ro" \
  --volume="$config_dir/dovecot/passwd:/etc/dovecot/passwd:ro" \
  --volume="$config_dir/opendkim/mail.private:/etc/opendkim/mail.private:ro" \
  --volume="$config_dir/opendkim/mail.txt:/etc/opendkim/mail.txt:ro" \
  --volume="$data_dir/virtual-mail:/var/mail/virtual:rw" \
  --volume="$data_dir/mail-queues:/var/spool/postfix/_queues:rw" \
  --volume="$data_dir/mail-servers:/var/spool/postfix/_servers:rw" \
  --volume="$data_dir/mail-sockets:/var/spool/postfix/_sockets:rw" \
  --volume="$data_dir/clamav:/var/lib/clamav:rw" \
  --volume="$data_dir/postfix:/var/lib/postfix:rw" \
  --volume="$data_dir/spamassassin:/var/lib/spamassassin:rw" \
  --volume="$run_dir/clamav:/var/spool/postfix/clamav:rw" \
  --volume="$run_dir/dovecot:/var/spool/postfix/dovecot:rw" \
  --volume="$run_dir/opendkim:/var/spool/postfix/opendkim:rw" \
  --volume="$run_dir/postfix:/var/spool/postfix/pid:rw" \
  --volume="$run_dir/spamassassin:/var/spool/postfix/spamassassin:rw" \
  mail-server
