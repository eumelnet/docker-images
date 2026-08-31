#!/bin/bash
BIN="$1"
shift
ARGS="$@"

if command -v "$BIN" 2>/dev/null; then
  exec "$BIN" $ARGS
else
  echo "WARNING: $BIN not found, sleeping..."
  while true; do sleep 3600; done
fi
