#!/bin/bash
set -e

for dir in /etc/postfix /etc/dovecot /etc/opendkim; do
  find "$dir" -name '*.tmpl' -type f 2>/dev/null | while read -r f; do
    envsubst '${MYSQL_HOST}${MYSQL_PORT}${MYSQL_DATABASE}${MYSQL_USER}${MYSQL_PASSWORD}${MYHOSTNAME}${MYDOMAIN}' < "$f" > "${f%.tmpl}"
  done
done

mkdir -p /var/spool/postfix /var/log /var/run /data/clamav /data/vmail /data/sqlgrey /var/log/clamav

# sqlgrey stores its SQLite greylist DB on the persistent volume.
chown sqlgrey:sqlgrey /data/sqlgrey 2>/dev/null || true

# Create named pipes (FIFOs) for services that only log to files.
# A supervised `cat` process reads each FIFO and writes to stdout,
# so the logs appear in `kubectl logs` and are scraped by Promtail.
for fifo in /var/log/dovecot /var/log/dovecot-info \
            /var/log/clamav/clamd /var/log/clamav/freshclam; do
  rm -f "$fifo"
  mkfifo "$fifo"
done
chown vmail:vmail /var/log/dovecot /var/log/dovecot-info
chown clamav:clamav /var/log/clamav/clamd /var/log/clamav/freshclam
# Generate DKIM KeyTable + SigningTable for multiple domains.
# DKIM_DOMAINS is a space-separated list of domains that share the same key/selector.
if [ -n "${DKIM_DOMAINS:-}" ] && [ -f /etc/opendkim/keys-src/tembo.private ]; then
  mkdir -p /etc/opendkim/keys /var/run/opendkim
  cp /etc/opendkim/keys-src/tembo.private /etc/opendkim/keys/tembo.private
  chown opendkim:opendkim /etc/opendkim/keys/tembo.private /var/run/opendkim
  chmod 600 /etc/opendkim/keys/tembo.private

  > /var/run/opendkim/KeyTable
  > /var/run/opendkim/SigningTable
  for domain in $DKIM_DOMAINS; do
    echo "tembo._domainkey.$domain $domain:tembo:/etc/opendkim/keys/tembo.private" \
      >> /var/run/opendkim/KeyTable
    echo "*@$domain tembo._domainkey.$domain" \
      >> /var/run/opendkim/SigningTable
  done
fi

chown clamav:clamav /data/clamav 2>/dev/null || true
chown vmail:vmail /data/vmail 2>/dev/null || true

mkdir -p /etc/ssl/mail 2>/dev/null || true
if [ ! -f /etc/ssl/mail/tls.crt ]; then
  openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout /etc/ssl/mail/tls.key \
    -out /etc/ssl/mail/tls.crt \
    -subj "/CN=${MYHOSTNAME:-mail.local}" 2>/dev/null || true
fi

echo "${MYDOMAIN:-example.com}" > /etc/mailname 2>/dev/null || true
newaliases 2>/dev/null || true
postfix -c /etc/postfix check 2>/dev/null || true

# Update SpamAssassin rules (best-effort: amavis runs SA in-process, picks up
# rules from /var/lib/spamassassin on restart). Fails silently offline.
if [ -x /usr/bin/sa-update ]; then
  sa-update --nogpg >/dev/null 2>&1 || true
fi

# Stage the DKIM private key with correct ownership/permissions for opendkim.
# The key is mounted read-only as a Secret at /etc/opendkim/keys-src/mail.private
# (mode 0400, owned by root - opendkim cannot read it directly).
if [ -f /etc/opendkim/keys-src/mail.private ]; then
  mkdir -p /etc/opendkim/keys /var/run/opendkim
  cp /etc/opendkim/keys-src/mail.private /etc/opendkim/keys/mail.private
  chown opendkim:opendkim /etc/opendkim/keys/mail.private /var/run/opendkim
  chmod 600 /etc/opendkim/keys/mail.private
fi

exec "$@"
