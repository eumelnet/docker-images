#!/bin/bash
set -e

for dir in /etc/postfix /etc/dovecot; do
  find "$dir" -name '*.tmpl' -type f 2>/dev/null | while read -r f; do
    envsubst < "$f" > "${f%.tmpl}"
  done
done

mkdir -p /var/spool/postfix /var/log /var/run

chown clamav:clamav /data/clamav 2>/dev/null || true
chown vmail:vmail /data/vmail 2>/dev/null || true

newaliases 2>/dev/null || true

exec "$@"
