FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    postfix postfix-mysql \
    dovecot-core dovecot-imapd dovecot-pop3d dovecot-mysql dovecot-lmtpd dovecot-sieve \
    sqlgrey \
    amavisd-new \
    clamav-daemon clamav-freshclam \
    supervisor gettext-base \
    --no-install-recommends \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
RUN dpkg -i http://archive.ubuntu.com/ubuntu/pool/universe/d/dkimproxy/dkimproxy_1.4.1-3_all.deb

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY supervisord.conf /etc/supervisor/supervisord.conf

RUN useradd -r -u 1010 -m -d /data/vmail -s /usr/sbin/nologin vmail \
    && mkdir -p /data/clamav /data/vmail /var/log/clamav /var/run/clamav \
    && chown clamav:clamav /data/clamav /var/log/clamav /var/run/clamav \
    && chown vmail:vmail /data/vmail

EXPOSE 25 143 110 587 993 995

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
