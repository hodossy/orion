#!/bin/bash

if [ ! -d "/tmp/orion" ]; then
  git clone https://github.com/hodossy/orion.git /tmp/orion
else
  (cd /tmp/orion && git pull --progress origin)
fi

cd /tmp/origin && ./src/deploy.sh
