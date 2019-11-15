#!/usr/bin/env bash
set -euo pipefail
trap 'kill $(jobs -p)' EXIT

[ -n "$MAIL_USER" ]
[ -n "$MAIL_DOMAIN" ]

user="$MAIL_USER"
domain="$MAIL_DOMAIN"
templates=/usr/share/mail-server-templates

function render_template() {
  local source_file output_file
  source_file="$1"
  output_file="$2"
  readonly source_file output_file

  sed \
    --expression="s#{{user}}#$user#g" \
    --expression="s#{{domain}}#$domain#g" \
    "$source_file" >"$output_file"
}

echo [$(date)] Rendering config templates
render_template "$templates/postfix/main.cf" /etc/postfix/main.cf
render_template "$templates/postfix/aliases" /etc/postfix/aliases
render_template "$templates/postfix/virtual" /etc/postfix/virtual
render_template \
  "$templates/postfix/virtual_mailbox_domains" \
  /etc/postfix/virtual_mailbox_domains
render_template \
  "$templates/postfix/virtual_mailbox_maps" \
  /etc/postfix/virtual_mailbox_maps
render_template "$templates/opendkim/KeyTable" /etc/opendkim/KeyTable
render_template "$templates/opendkim/SigningTable" /etc/opendkim/SigningTable
render_template "$templates/opendkim/opendkim.conf" /etc/opendkim/opendkim.conf

echo [$(date)] Fixing volume permissions
chown --recursive mailman:mailman \
  /var/mail/virtual
chown --recursive postfix:postfix \
  /var/lib/postfix/ \
  /var/spool/postfix/_queues/ \
  /var/spool/postfix/_servers/ \
  /var/spool/postfix/_sockets/
chown --recursive postfix:postdrop \
  /var/spool/postfix/_queues/maildrop/ \
  /var/spool/postfix/_sockets/public/
chown --recursive postfix:clamav /var/spool/postfix/clamav/
chown --recursive postfix:dovecot /var/spool/postfix/dovecot/
chown --recursive postfix:opendkim /var/spool/postfix/opendkim/
chown --recursive postfix:spamd /var/spool/postfix/spamassassin/
chown --recursive clamav:clamav /var/lib/clamav/
chown --recursive spamd:spamd /var/lib/spamassassin/
chmod 0775 \
  /var/spool/postfix/clamav/ \
  /var/spool/postfix/dovecot/ \
  /var/spool/postfix/opendkim/ \
  /var/spool/postfix/spamassassin/

echo [$(date)] Generating runtime data files
postalias /etc/postfix/aliases
postmap /etc/postfix/virtual
postmap /etc/postfix/virtual_mailbox_domains
postmap /etc/postfix/virtual_mailbox_maps
ln --symbolic --force \
  /etc/dovecot/dovecot.conf \
  /var/spool/postfix/dovecot/dovecot.conf

echo [$(date)] Validating configuration
postfix check
doveconf >/dev/null
spamassassin --lint

echo [$(date)] Starting OpenDKIM
# Add `-f` for foreground
opendkim -x /etc/opendkim/opendkim.conf

echo [$(date)] Starting SpamAssassin
# Remove `--daemonize` for foreground
spamd \
  --daemonize \
  --username=spamd \
  --groupname=spamd \
  --nouser-config \
  --pidfile=/var/spool/postfix/spamassassin/spamd.pid \
  --syslog=mail \
  --socketpath=/var/spool/postfix/spamassassin/spamd.sock \
  --socketowner=postfix \
  --socketgroup=spamd \
  --socketmode=660

echo [$(date)] Starting SpamAssassin Milter
# Remove `-f` for foreground
spamass-milter \
  -f \
  -m \
  -u sa-milt \
  -g sa-milt \
  -p /var/spool/postfix/spamassassin/sa-milt.sock \
  -P /var/spool/postfix/spamassassin/sa-milt.pid \
  -- --socket=/var/spool/postfix/spamassassin/spamd.sock
chown postfix:sa-milt \
  /var/spool/postfix/spamassassin/sa-milt.sock

echo [$(date)] Starting ClamAV
# Add `--foreground=true` for foreground
clamd --config-file=/etc/clamav/clamd.conf

echo [$(date)] Starting ClamAV Milter
# Set `Foreground yes` in config file for foreground
clamav-milter --config-file=/etc/clamav/clamav-milter.conf
chown postfix:clamav \
  /var/spool/postfix/clamav/clamav-milter.sock

echo [$(date)] Starting Dovecot
# Add `-F` for foreground
dovecot

echo [$(date)] Starting Postfix
postfix start-fg
