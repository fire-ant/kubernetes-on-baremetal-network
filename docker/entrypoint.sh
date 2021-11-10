#!/bin/bash
set -e
set -x

INTFS_SRC=/tmp/intfs/
INTFS_DST=/etc/network/interfaces.d
INTFS_APPLY="ifreload -a -f"

FRR_SRC=/tmp/frr/
FRR_DST=/etc/frr
FRR_APPLY="systemctl restart frr"

SONIC_SRC=/tmp/sonic/
SONIC_DST=/etc/sonic
SONIC_APPLY="sshpass -p 'YourPaSsWoRd' ssh -oStrictHostKeyChecking=no admin@localhost 'sudo config reload -y'"


declare -A mapping=( 
  [$INTFS_SRC]=$INTFS_DST:$INTFS_APPLY 
  [$FRR_SRC]=$FRR_DST:$FRR_APPLY
  [$SONIC_SRC]=$SONIC_DST:$SONIC_APPLY
)

# this is where ifupdown2 stores its lock
mkdir /run/network

sync_dir() {
    # sleep to aggregate events
    sleep 1
    src=$1
    value="${mapping[$1]}"
    dst=$(echo $value | cut -d ':' -f1)
    cmd=$(echo $value | cut -d ':' -f2)

    if [ ! -d "$dst" ]; then
      mkdir -p $dst
    fi

    echo "syncing all files for ${src} to ${dst} and running ${cmd}"
    for file in "$src"*; do
      cp $file $dst/
    done

    eval $cmd || true
    echo "configuration applied"
}

sync_all() {
  if [ -d "$INTFS_SRC" ]; then
    sync_dir $INTFS_SRC
  fi

  if [ -d "$FRR_SRC" ]; then
    sync_dir $FRR_SRC
  fi  

  if [ -d "$SONIC_SRC" ]; then
    sync_dir $SONIC_SRC
  fi  
}

sync_all



WATCH_DIR=""
if [ -d "$INTFS_SRC" ]; then
  WATCH_DIR="$WATCH_DIR $INTFS_SRC"
fi
if [ -d "$FRR_SRC" ]; then
  WATCH_DIR="$WATCH_DIR $FRR_SRC"
fi  
if [ -d "$SONIC_SRC" ]; then
  WATCH_DIR="$WATCH_DIR $SONIC_SRC"
fi  

while true; do
  while name=$(inotifywait -e create,delete,modify,move --format "%w" $WATCH_DIR ); do
    echo "change detected to directory ${name}"
    sync_dir ${name}
  done
done

