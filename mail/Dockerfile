FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    postfix postfix-mysql \
    dovecot-core dovecot-imapd dovecot-pop3d dovecot-mysql dovecot-lmtpd dovecot-sieve \
    sqlgrey \
    amavisd-new \
    clamav-daemon clamav-freshclam \
    opendkim opendkim-tools \
    supervisor gettext-base openssl ca-certificates \
    --no-install-recommends \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Verify critical binaries exist
RUN which amavisd-new 2>/dev/null || echo "WARNING: amavisd-new not found" \
    && which sqlgrey 2>/dev/null || echo "WARNING: sqlgrey not found" \
    && which opendkim 2>/dev/null || echo "WARNING: opendkim not found"

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY safe-run.sh /usr/local/bin/safe-run.sh
RUN chmod +x /usr/local/bin/safe-run.sh

COPY sqlgrey-wrapper.sh /usr/local/bin/sqlgrey-wrapper.sh
RUN chmod +x /usr/local/bin/sqlgrey-wrapper.sh

COPY supervisord.conf /etc/supervisor/supervisord.conf

RUN useradd -r -u 5000 -m -d /data/vmail -s /usr/sbin/nologin vmail \
    && mkdir -p /data/clamav /data/vmail /var/log/clamav /var/run/clamav \
                /etc/opendkim/keys /var/run/opendkim \
    && chown clamav:clamav /data/clamav /var/log/clamav /var/run/clamav \
    && chown vmail:vmail /data/vmail \
    && chown opendkim:opendkim /etc/opendkim /etc/opendkim/keys /var/run/opendkim \
    # Let clamd read amavis spool dirs (avoids "File path check failure" on virus scans)
    && usermod -a -G amavis clamav

EXPOSE 25 143 110 587 993 995

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
