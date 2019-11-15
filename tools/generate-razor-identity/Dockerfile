FROM archlinux/base

COPY entrypoint.sh /sbin/entrypoint.sh
ENTRYPOINT ["/sbin/entrypoint.sh"]
RUN chmod 700 /sbin/entrypoint.sh \
 && pacman --sync --refresh --noconfirm \
      razor \
 && mkdir --parents \
      /var/lib/spamassassin/razor/
VOLUME /var/lib/spamassassin/razor/
