FROM archlinux/base

COPY entrypoint.sh /sbin/entrypoint.sh
ENTRYPOINT ["/sbin/entrypoint.sh"]
RUN chmod 700 /sbin/entrypoint.sh \
 && pacman --sync --refresh --noconfirm \
      dovecot \
 && touch \
      /etc/dovecot/dovecot.conf
