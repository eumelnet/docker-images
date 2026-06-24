#!/bin/bash
set -e

for dir in /etc/postfix /etc/dovecot; do
  find "$dir" -name '*.tmpl' -type f 2>/dev/null | while read -r f; do
    envsubst '${MYSQL_HOST}${MYSQL_PORT}${MYSQL_DATABASE}${MYSQL_USER}${MYSQL_PASSWORD}${MYHOSTNAME}${MYDOMAIN}' < "$f" > "${f%.tmpl}"
  done
done

mkdir -p /var/spool/postfix /var/log /var/run /data/clamav /data/vmail

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
