#!/bin/bash

xml=$(curl -s https://cdn.fwupd.org/downloads/firmware.xml.gz | gzip -d)

OUT="$PWD/data"
mkdir -p "$OUT"

for url in $(echo "$xml" | grep location | sed -r "s| *<location>(.+)</location>|\1|g"); do
  f=$(basename "$url")
  F="$OUT/$f"
  if [ ! -e "$F" ]; then
    wget "$url" -O "$F"
  fi
done

echo -n "$xml" | gzip > "$OUT/firmware.xml.gz"
