#!/bin/bash
set -e

for dir in /etc/postfix /etc/dovecot /etc/opendkim; do
  find "$dir" -name '*.tmpl' -type f 2>/dev/null | while read -r f; do
    envsubst < "$f" > "${f%.tmpl}"
    rm "$f"
  done
done

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

mkdir -p /var/spool/postfix /var/log /var/run

chown clamav:clamav /data/clamav 2>/dev/null || true
chown vmail:vmail /data/vmail 2>/dev/null || true

newaliases 2>/dev/null || true

exec "$@"
