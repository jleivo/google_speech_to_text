#!/bin/bash
# script to remove flac files that do not belong to a note

MEDIAPATH=/mnt/c/Users/k64128675/Sync/Obsidian/05\ -\ media
CURDIR=$(pwd)

cd "$MEDIAPATH"

TMPFILE=$(mktemp)
trap '{ rm -f -- "$TMPFILE"; }' EXIT

find . -name "*.flac" > $TMPFILE
while read line; do
    echo "Searching for ${line#*/}"
    grep -R --exclude-dir=.obsidian "${line#*/}" ../ || { echo "Not found in any note -> removing"; rm -f "$line"; continue; }
done < $TMPFILE

cd "$CURDIR"