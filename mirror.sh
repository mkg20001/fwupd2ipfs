#!/bin/bash

set -e

# Config

OUT="$PWD/data"
GATEWAY="https://ipfs.io/ipfs"

# Code

xml=$(curl -s https://cdn.fwupd.org/downloads/firmware.xml.gz | gzip -d) # get and ungz latest metadata

mkdir -p "$OUT"

echo "$xml" | grep location | sed -r "s| *<location>(.+)</location>|\1|g" | \
while read url; do # iterate over locations
  f=$(basename "$url") # get just the filename: "HASH-sth.cab"
  F="$OUT/$f" # output location
  if [ ! -e "$F.ipfs" ]; then # if not added to ipfs,
    wget "$url" -O "$F" # download firmware
    ipfs add -wQ "$F" > "$F.ipfs" # create hash for file wrapped with directory. wrapped so real filename can be used in url
  fi
  hash=$(cat "$F.ipfs") # load hash
  if [ -z "$hash" ]; then
    echo "Hash missing for $f"
    exit 2
  fi
  newURL=$(echo "$GATEWAY/$hash/$f") # generate new url
  xml=$(echo -n "$xml" | sed "s|$url|$newURL|g") # replace url in xml
done

echo -n "$xml" | gzip > "$OUT/firmware.xml.gz"
