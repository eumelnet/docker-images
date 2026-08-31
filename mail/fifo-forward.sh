#!/bin/bash
# Forward a named pipe (FIFO) to stdout.
# Opens the FIFO with O_RDWR so the open() never blocks, even if the writer
# (dovecot/clamd/freshclam) has not started yet. Holding the pipe open also
# guarantees the writer's blocking open() completes and no boot logs are lost.
set -e

exec 3<>"$1"
cat <&3
