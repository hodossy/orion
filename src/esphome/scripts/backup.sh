#!/bin/bash

backup_dir=$1
suffix=$2

if [ -d /homeassistant/esphome ]; then
  tar -czvf $backup_dir/esphome-$2.tar.gz /homeassistant/esphome;
fi

