#!/bin/bash
# Run sqlgrey in the foreground under supervisord so a crash actually
# restarts it (previous wrapper masked failures with a sleep loop).
exec /usr/sbin/sqlgrey
