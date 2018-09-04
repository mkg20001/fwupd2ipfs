#!/bin/bash

set -e

# Config

OUT="$PWD/data"
GATEWAY="https://ipfs.io/ipfs"

# Code

xml=$(curl -s https://cdn.fwupd.org/downloads/firmware.xml.gz | gzip -d) # get and ungz latest metadata

mkdir -p "$OUT"

all=$(echo "$xml" | grep location | wc -l)
cur=0

echo "$xml" | grep location | sed -r "s| *<location>(.+)</location>|\1|g" | \
while read url; do # iterate over locations
  ((cur=cur+1))
  echo "Processing $url ($cur/$all) ..."
  f=$(basename "$url") # get just the filename: "HASH-sth.cab"
  F="$OUT/$f" # output location
  if [ ! -e "$F.ipfs" ]; then # if not added to ipfs,
    ex=0
    wget "$url" -O "$F" || ex=$? # download firmware
    if [ $ex -eq 8 ]; then
      echo "Download failed, retaining URL as $url"
      continue
    fi
    ipfs add -wQ "$F" > "$F.ipfs" # create hash for file wrapped with directory. wrapped so real filename can be used in url
  fi
  hash=$(cat "$F.ipfs") # load hash
  if [ -z "$hash" ]; then
    echo "Hash missing for $f"
    exit 2
  fi
  newURL=$(echo "$GATEWAY/$hash/$f") # generate new url
  xml=${xml/"$url"/"$newURL"} # replace url in xml
done

echo -n "$xml" | gzip > "$OUT/firmware.xml.gz"
