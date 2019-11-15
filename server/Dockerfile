FROM archlinux/base as builder--aur-base
RUN pacman --sync --refresh --noconfirm --needed \
      base-devel \
      git \
 && mkdir --parents /opt/aur/ \
 && chown nobody:nobody /opt/aur/

FROM builder--aur-base as builder--spamass-milter
RUN pacman --sync --refresh --noconfirm --needed \
      libmilter \
      postfix \
      spamassassin
ENV PATH="$PATH:/usr/bin/vendor_perl"
USER nobody
RUN git clone \
      https://aur.archlinux.org/spamass-milter.git \
      /opt/aur/spamass-milter/ \
 && cd /opt/aur/spamass-milter/ \
 && makepkg

FROM archlinux/base

ENV PATH="$PATH:/usr/bin/vendor_perl"

RUN pacman --sync --refresh --noconfirm --needed \
      ca-certificates \
      clamav \
      dovecot \
      gcc \
      grep \
      libmilter \
      make \
      opendkim \
      pigeonhole \
      postfix \
      razor \
      spamassassin \
      sudo

RUN mkdir --parents \
      /opt/aur/

COPY --from=builder--spamass-milter \
      /opt/aur/spamass-milter/spamass-milter-0.4.0-1-x86_64.pkg.tar.xz \
      /opt/aur/spamass-milter/spamass-milter-0.4.0.tar.gz \
      /opt/aur/

RUN pacman --upgrade --noconfirm \
      /opt/aur/spamass-milter-0.4.0-1-x86_64.pkg.tar.xz

# Copy all config files to their destination paths.
# Copy all templates to locations where they can be rendered on startup.
COPY files/ /
COPY templates/ /usr/share/mail-server-templates/

RUN echo "Add postfix user to socket groups" >&2 \
 && usermod --append --groups clamav,dovecot,opendkim,spamd postfix \
 && echo "Add sa-milt user to socket groups" >&2 \
 && usermod --append --groups spamd sa-milt \
 && echo "Create the mailman user to manage dovecot's virtual email users" >&2 \
 && groupadd --gid 5000 mailman \
 && useradd \
      --uid 5000 \
      --gid mailman \
      --no-create-home \
      --home-dir /var/mail/mailman \
      --shell /usr/bin/nologin \
      --comment 'User to manage virtual mail accounts' \
      mailman \
 && mkdir --parents \
      /var/mail/mailman \
      /var/mail/mailman/sieve-after \
      /var/mail/mailman/sieve-before \
 && sievec /var/mail/mailman/sieve-before/filter.sieve \
 && chown --recursive mailman:mailman /var/mail/mailman \
 && echo "Create mount points with appropriate mode, owner, and group" >&2 \
 && umask 0077 \
 && echo "  Config files" >&2 \
 && touch \
      /etc/ssl/private/mail.crt \
      /etc/ssl/private/mail.key \
      /etc/dovecot/dh.pem \
      /etc/dovecot/passwd \
      /etc/opendkim/mail.private \
      /etc/opendkim/mail.txt \
 && chown root:root \
      /etc/ssl/private/mail.crt \
      /etc/ssl/private/mail.key \
 && chown dovecot:root \
      /etc/dovecot/dh.pem \
      /etc/dovecot/passwd \
 && chown opendkim:root \
      /etc/opendkim/mail.private \
      /etc/opendkim/mail.txt \
 && echo "  Mail directories" >&2 \
 && mkdir --parents \
      /var/mail/virtual/ \
      /var/spool/postfix/_queues/ \
      /var/spool/postfix/_servers/ \
      /var/spool/postfix/_sockets/ \
 && chown mailman:mailman \
      /var/mail/virtual/ \
 && chown postfix:postfix \
      /var/spool/postfix/_queues/ \
      /var/spool/postfix/_servers/ \
      /var/spool/postfix/_sockets/ \
 && echo "  Data directories" >&2 \
 && mkdir --parents \
      /var/lib/clamav/ \
      /var/lib/postfix/ \
      /var/lib/spamassassin/ \
 && chown clamav:clamav /var/lib/clamav/ \
 && chown postfix:postfix /var/lib/postfix/ \
 && chown spamd:spamd /var/lib/spamassassin/ \
 && echo "  Run directories" >&2 \
 && mkdir --parents \
      /var/spool/postfix/clamav/ \
      /var/spool/postfix/dovecot/ \
      /var/spool/postfix/opendkim/ \
      /var/spool/postfix/pid/ \
      /var/spool/postfix/spamassassin/ \
 && chmod 0775 \
      /var/spool/postfix/clamav/ \
      /var/spool/postfix/dovecot/ \
      /var/spool/postfix/opendkim/ \
      /var/spool/postfix/pid/ \
      /var/spool/postfix/spamassassin/ \
 && chown postfix:clamav /var/spool/postfix/clamav/ \
 && chown postfix:dovecot /var/spool/postfix/dovecot/ \
 && chown postfix:opendkim /var/spool/postfix/opendkim/ \
 && chown postfix:postfix /var/spool/postfix/pid/ \
 && chown postfix:spamd /var/spool/postfix/spamassassin/ \
 && echo "Create symbolic links to mounted directories" >&2 \
 && echo "  Mail queue directories" >&2 \
 && rmdir \
      /var/spool/postfix/active/ \
      /var/spool/postfix/corrupt/ \
      /var/spool/postfix/deferred/ \
      /var/spool/postfix/hold/ \
      /var/spool/postfix/incoming/ \
      /var/spool/postfix/maildrop/ \
 && ln --symbolic --force \
      /var/spool/postfix/_queues/active/ \
      /var/spool/postfix/_queues/corrupt/ \
      /var/spool/postfix/_queues/deferred/ \
      /var/spool/postfix/_queues/hold/ \
      /var/spool/postfix/_queues/incoming/ \
      /var/spool/postfix/_queues/maildrop/ \
      /var/spool/postfix/ \
 && chown --no-dereference postfix:postfix \
      /var/spool/postfix/active \
      /var/spool/postfix/corrupt \
      /var/spool/postfix/deferred \
      /var/spool/postfix/hold \
      /var/spool/postfix/incoming \
 && chown --no-dereference postfix:postdrop \
      /var/spool/postfix/maildrop \
 && echo "  Mail server directories" >&2 \
 && rmdir \
      /var/spool/postfix/bounce/ \
      /var/spool/postfix/defer/ \
      /var/spool/postfix/flush/ \
      /var/spool/postfix/saved/ \
      /var/spool/postfix/trace/ \
 && ln --symbolic --force \
      /var/spool/postfix/_servers/bounce/ \
      /var/spool/postfix/_servers/defer/ \
      /var/spool/postfix/_servers/flush/ \
      /var/spool/postfix/_servers/saved/ \
      /var/spool/postfix/_servers/trace/ \
      /var/spool/postfix/ \
 && chown --no-dereference postfix:postfix \
      /var/spool/postfix/bounce \
      /var/spool/postfix/defer \
      /var/spool/postfix/flush \
      /var/spool/postfix/saved \
      /var/spool/postfix/trace \
 && echo "  Mail socket directories" >&2 \
 && rmdir \
      /var/spool/postfix/private/ \
      /var/spool/postfix/public/ \
 && ln --symbolic --force \
      /var/spool/postfix/_sockets/private/ \
      /var/spool/postfix/_sockets/public/ \
      /var/spool/postfix/ \
 && chown --no-dereference postfix:postfix \
      /var/spool/postfix/private \
 && chown --no-dereference postfix:postdrop \
      /var/spool/postfix/public \
 && echo "Make command scripts executable" >&2 \
 && chmod 0700 \
      /sbin/healthcheck.sh \
      /sbin/startup.sh

# Expose ports needed to provide email services:
#    25: SMTP official
#  2525: SMTP unofficial
#   465: SMTPS unofficial
#   587: SMTPS official
#   143: IMAP
#   993: IMAPS
#   110: POP3
#   995: POP3S
EXPOSE 25 110 143 465 587 993 995 2525

VOLUME \
      /var/lib/clamav/ \
      /var/lib/postfix/ \
      /var/lib/spamassassin/ \
      /var/mail/virtual/ \
      /var/spool/postfix/_queues/ \
      /var/spool/postfix/_servers/ \
      /var/spool/postfix/_sockets/ \
      /var/spool/postfix/clamav/ \
      /var/spool/postfix/dovecot/ \
      /var/spool/postfix/opendkim/ \
      /var/spool/postfix/spamassassin/

CMD ["/sbin/startup.sh"]
HEALTHCHECK --start-period=600s CMD /sbin/healthcheck.sh
