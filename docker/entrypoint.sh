#!/bin/bash
set -e
set -x

WATCH_DIR=/tmp/intfs
TARGET_DIR=/etc/network/interfaces.d

# this is where ifupdown2 stores its lock
mkdir /run/network

sync_all() {
    echo 'syncing all files'
    all_files=($WATCH_DIR/*)
    echo "${all_files}" |
    while IFS= read -r file; do
        cp $file $TARGET_DIR/
    done
    ifreload -a -f || true
    echo "configuration applied"
}

sync_all

while fn=$(inotifywait $WATCH_DIR -t 1 --format %f .); do
  echo "change detected to file ${fn}"
  sync_all
done
