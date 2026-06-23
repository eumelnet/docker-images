#!/bin/bash
/usr/sbin/sqlgrey "$@" &
PID=$!
trap "kill $PID" SIGTERM SIGINT
while kill -0 $PID 2>/dev/null; do
  sleep 2
done
