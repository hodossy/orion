#!/bin/bash

target_folder=/homeassistant/esphome

echo "|-------------------------------------|"
echo "|-------------- ESPHOME --------------|"
echo "|-------------------------------------|"
echo ""

# make sure globstar is on for ** to work
shopt -s globstar

echo "Updated definition files:"
for f in **/*.yaml; do
  if [ -f "$f" ] && cmp $f $target_folder/$f >& /dev/null; then
    # empty command
    :
  else
    echo "$f"
    mkdir -p $(dirname $target_folder/$f)
    cp $f $target_folder/$f
  fi
done

# TODO: identify which devices need to update and run esphome cli to update
